import base64
import json
import os
import threading
import uuid
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field


# ---------- Configuration ----------
STORAGE_DIR = Path(__file__).parent / "storage"
STORAGE_DIR.mkdir(parents=True, exist_ok=True)
EMBEDDINGS_PATH = STORAGE_DIR / "embeddings.json"
LOGS_PATH = STORAGE_DIR / "attendance_logs.jsonl"

# Adaptive threshold for DeepFace ArcFace model
# Optimized for Raspberry Pi Camera v2 with poor lighting conditions
RECOGNITION_THRESHOLD = float(os.getenv("RECOGNITION_THRESHOLD", "0.45"))


# ---------- DeepFace backend (Required) ----------
_deepface_lock = threading.Lock()
_deepface_model_name = os.getenv("DEEPFACE_MODEL", "ArcFace")

# DeepFace is required for this server
try:
    from deepface import DeepFace  # type: ignore
    _deepface_available = True
    print(f"✅ DeepFace loaded successfully with model: {_deepface_model_name}")
except Exception as e:
    print(f"❌ ERROR: DeepFace is required but not available: {e}")
    print("Please install DeepFace: pip install deepface")
    raise RuntimeError("DeepFace is required for face recognition")


def _load_image_from_base64(image_base64: str) -> np.ndarray:
    data = base64.b64decode(image_base64)
    arr = np.frombuffer(data, dtype=np.uint8)
    # Lazy import to avoid forcing cv2 at module import if server is inspected
    import cv2  # noqa: WPS433

    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("Invalid image data")
    return img


def _normalize_vector(vec: np.ndarray) -> np.ndarray:
    norm = np.linalg.norm(vec) + 1e-12
    return vec / norm


def _cosine_distance(a: np.ndarray, b: np.ndarray) -> float:
    a_n = _normalize_vector(a)
    b_n = _normalize_vector(b)
    return float(1.0 - np.dot(a_n, b_n))


def _represent_with_deepface(img_bgr: np.ndarray) -> np.ndarray:
    """Compute face embedding using DeepFace ArcFace model optimized for RPi Camera v2."""
    # DeepFace expects RGB
    import cv2  # noqa: WPS433

    rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    
    # Image preprocessing for better performance in poor lighting
    # Apply slight brightness and contrast adjustment
    lab = cv2.cvtColor(rgb, cv2.COLOR_RGB2LAB)
    l, a, b = cv2.split(lab)
    
    # Enhance brightness slightly
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    l = clahe.apply(l)
    
    # Merge channels back
    lab = cv2.merge([l, a, b])
    rgb_enhanced = cv2.cvtColor(lab, cv2.COLOR_LAB2RGB)
    
    with _deepface_lock:
        reps = DeepFace.represent(
            rgb_enhanced,
            model_name=_deepface_model_name,
            enforce_detection=False,  # More lenient for poor lighting
            detector_backend="opencv",  # Use OpenCV for face detection
            align=True,  # Align faces for better accuracy
        )
    
    if not reps:
        raise ValueError("No face detected in image")
    
    emb = np.array(reps[0]["embedding"], dtype=np.float32)
    return emb


# Fallback function removed - DeepFace is now required


def compute_embedding(img_bgr: np.ndarray) -> np.ndarray:
    """Compute face embedding using DeepFace ArcFace model for high accuracy."""
    return _represent_with_deepface(img_bgr)


def load_embeddings() -> List[Dict[str, Any]]:
    """Load stored embeddings from JSON file."""
    if not EMBEDDINGS_PATH.exists():
        return []
    try:
        with EMBEDDINGS_PATH.open("r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return []


def save_embeddings(embeddings: List[Dict[str, Any]]) -> None:
    """Save embeddings to JSON file."""
    with EMBEDDINGS_PATH.open("w", encoding="utf-8") as f:
        json.dump(embeddings, f, indent=2, ensure_ascii=False)


def log_attendance(user_id: str, name: str, matched: bool, distance: Optional[float] = None, captured_image: Optional[str] = None) -> None:
    """Log attendance event to JSONL file."""
    log_entry = {
        "ts": int(datetime.now(timezone.utc).timestamp()),
        "user_id": user_id,
        "name": name,
        "matched": matched,
        "distance": distance,
        "timestamp": datetime.now(timezone(timedelta(hours=7))).isoformat()
    }
    
    # Add captured image if provided
    if captured_image:
        log_entry["captured_image"] = captured_image
    
    with LOGS_PATH.open("a", encoding="utf-8") as f:
        f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")


# ---------- FastAPI app ----------
app = FastAPI(title="FaceLog API", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------- Pydantic models ----------
class RecognitionRequest(BaseModel):
    image_base64: str = Field(..., description="Base64 encoded image")
    captured_image: Optional[str] = Field(None, description="Base64 encoded captured image for history")


class RecognitionResponse(BaseModel):
    matched: bool
    user_id: Optional[str] = None
    name: Optional[str] = None
    distance: Optional[float] = None
    threshold: float
    liveness: str = "pass"


class RegistrationRequest(BaseModel):
    name: str = Field(..., description="User's full name")
    position: Optional[str] = Field(None, description="User's position")
    image_base64: str = Field(..., description="Base64 encoded face image")


class RegistrationResponse(BaseModel):
    user_id: str
    name: str
    position: Optional[str] = None
    model: str
    embedding_length: int


# ---------- API endpoints ----------
@app.get("/health")
def health_check() -> Dict[str, str]:
    """Health check endpoint."""
    return {"status": "ok"}


@app.post("/recognize", response_model=RecognitionResponse)
def recognize_face(request: RecognitionRequest) -> RecognitionResponse:
    """Recognize a face from the provided image."""
    try:
        # Load and process image
        img = _load_image_from_base64(request.image_base64)
        
        # Compute embedding
        query_embedding = compute_embedding(img)
        
        # Load stored embeddings
        stored_embeddings = load_embeddings()
        
        if not stored_embeddings:
            # Log failed recognition attempt
            log_attendance("unknown", "Unknown", False, captured_image=request.captured_image)
            return RecognitionResponse(
                matched=False,
                threshold=RECOGNITION_THRESHOLD,
                liveness="pass"
            )
        
        # Find best match
        best_match = None
        best_distance = float("inf")
        
        print(f"=== Face Recognition Debug ===")
        print(f"Threshold: {RECOGNITION_THRESHOLD}")
        print(f"Total users in database: {len(stored_embeddings)}")
        
        for stored in stored_embeddings:
            if not stored.get("active", True):
                continue
                
            stored_embedding = np.array(stored["embedding"], dtype=np.float32)
            distance = _cosine_distance(query_embedding, stored_embedding)
            
            print(f"User: {stored['name']}, Distance: {distance:.4f}, Model: {stored.get('model', 'unknown')}")
            
            if distance < best_distance:
                best_distance = distance
                best_match = stored
        
        print(f"Best match: {best_match['name'] if best_match else 'None'}, Distance: {best_distance:.4f}")
        print(f"===============================")
        
        # Adaptive recognition logic optimized for RPi Camera v2
        if best_match and best_distance <= RECOGNITION_THRESHOLD:
            # Quality checks adapted for poor lighting conditions
            is_acceptable_match = True
            quality_reason = ""
            
            # More lenient distance check for RPi Camera v2
            if best_distance > 0.40:
                is_acceptable_match = False
                quality_reason = f"Distance too high: {best_distance:.4f} > 0.40"
            
            # Check if we have multiple users and this is the clear winner
            if len(stored_embeddings) > 1:
                # Find second best match
                second_best_distance = float("inf")
                for stored in stored_embeddings:
                    if stored["id"] != best_match["id"] and stored.get("active", True):
                        stored_embedding = np.array(stored["embedding"], dtype=np.float32)
                        distance = _cosine_distance(query_embedding, stored_embedding)
                        if distance < second_best_distance:
                            second_best_distance = distance
                
                # More lenient separation check for poor lighting
                if second_best_distance - best_distance < 0.05:
                    is_acceptable_match = False
                    quality_reason = f"Unclear winner: best={best_distance:.4f}, second={second_best_distance:.4f}"
            
            if is_acceptable_match:
                print(f"✅ RPI CAMERA MATCH: User {best_match['name']}, Distance {best_distance:.4f} <= {RECOGNITION_THRESHOLD}")
                
                # Log successful recognition
                log_attendance(best_match["id"], best_match["name"], True, best_distance, request.captured_image)
                
                return RecognitionResponse(
                    matched=True,
                    user_id=best_match["id"],
                    name=best_match["name"],
                    distance=best_distance,
                    threshold=RECOGNITION_THRESHOLD,
                    liveness="pass"
                )
            else:
                print(f"⚠️ LOW QUALITY RPI MATCH: User {best_match['name']}, Distance {best_distance:.4f}, Reason: {quality_reason}")
                
                # Log failed recognition due to low quality
                log_attendance("unknown", "Unknown", False, best_distance, request.captured_image)
                
                return RecognitionResponse(
                    matched=False,
                    distance=best_distance,
                    threshold=RECOGNITION_THRESHOLD,
                    liveness="pass"
                )
        else:
            print(f"❌ NO MATCH: Best distance {best_distance:.4f} > {RECOGNITION_THRESHOLD}")
            
            # Log failed recognition
            log_attendance("unknown", "Unknown", False, best_distance if best_match else None, request.captured_image)
            
            return RecognitionResponse(
                matched=False,
                distance=best_distance if best_match else None,
                threshold=RECOGNITION_THRESHOLD,
                liveness="pass"
            )
            
    except Exception as e:
        # Log error
        log_attendance("error", "Error", False)
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/register", response_model=RegistrationResponse)
def register_user(request: RegistrationRequest) -> RegistrationResponse:
    """Register a new user with their face image."""
    try:
        # Load and process image
        img = _load_image_from_base64(request.image_base64)
        
        # Compute embedding
        embedding = compute_embedding(img)
        
        # Generate user ID
        user_id = str(uuid.uuid4())
        
        # Use DeepFace ArcFace model for high accuracy
        model_name = _deepface_model_name
        
        # Create user record
        user_record = {
            "id": user_id,
            "name": request.name,
            "position": request.position,
            "embedding": embedding.tolist(),
            "model": model_name,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "active": True,
            "image_base64": request.image_base64  # Store original image
        }
        
        # Load existing embeddings and add new user
        embeddings = load_embeddings()
        embeddings.append(user_record)
        save_embeddings(embeddings)
        
        return RegistrationResponse(
            user_id=user_id,
            name=request.name,
            position=request.position,
            model=model_name,
            embedding_length=len(embedding)
        )
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/users")
def get_users() -> Dict[str, Any]:
    """Get all registered users."""
    embeddings = load_embeddings()
    return {
        "total_users": len(embeddings),
        "active_users": len([e for e in embeddings if e.get("active", True)]),
        "users": embeddings
    }


@app.get("/users/{user_id}/image")
def get_user_image(user_id: str):
    """Get user's registered image."""
    embeddings = load_embeddings()
    user = next((u for u in embeddings if u["id"] == user_id), None)
    
    if not user or "image_base64" not in user:
        raise HTTPException(status_code=404, detail="User or image not found")
    
    return {"image_base64": user["image_base64"]}


@app.delete("/users/{user_id}")
def delete_user(user_id: str, backup: bool = True):
    """Delete a user by ID with optional backup."""
    embeddings = load_embeddings()
    user = next((u for u in embeddings if u["id"] == user_id), None)
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Create backup if requested
    if backup:
        backup_data = {
            "user": user,
            "deleted_at": datetime.now().isoformat(),
            "attendance_logs": []
        }
        
        # Backup attendance logs for this user
        if LOGS_PATH.exists():
            try:
                with LOGS_PATH.open("r", encoding="utf-8") as f:
                    lines = f.readlines()
                    for line in lines:
                        try:
                            log = json.loads(line.strip())
                            if log.get("user_id") == user_id:
                                backup_data["attendance_logs"].append(log)
                        except:
                            continue
            except Exception as e:
                print(f"Error reading logs for backup: {e}")
        
        # Save backup to file
        backup_dir = STORAGE_DIR / "backups"
        backup_dir.mkdir(exist_ok=True)
        backup_file = backup_dir / f"user_{user_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        try:
            with backup_file.open("w", encoding="utf-8") as f:
                json.dump(backup_data, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"Error saving backup: {e}")
    
    # Remove user from embeddings
    embeddings = [u for u in embeddings if u["id"] != user_id]
    save_embeddings(embeddings)
    
    # Remove attendance logs for this user
    if LOGS_PATH.exists():
        try:
            with LOGS_PATH.open("r", encoding="utf-8") as f:
                lines = f.readlines()
            
            # Filter out logs for this user
            remaining_logs = []
            for line in lines:
                try:
                    log = json.loads(line.strip())
                    if log.get("user_id") != user_id:
                        remaining_logs.append(line)
                except:
                    remaining_logs.append(line)  # Keep malformed lines
            
            # Write back filtered logs
            with LOGS_PATH.open("w", encoding="utf-8") as f:
                f.writelines(remaining_logs)
        except Exception as e:
            print(f"Error cleaning attendance logs: {e}")
    
    return {
        "message": f"User {user['name']} deleted successfully",
        "backup_created": backup,
        "attendance_logs_removed": len(backup_data.get("attendance_logs", [])) if backup else 0
    }


@app.post("/admin/cleanup-orphaned-data")
def cleanup_orphaned_data():
    """Clean up attendance logs that don't have corresponding users."""
    embeddings = load_embeddings()
    valid_user_ids = {user["id"] for user in embeddings}
    
    if not LOGS_PATH.exists():
        return {"message": "No attendance logs to clean", "removed_logs": 0}
    
    try:
        with LOGS_PATH.open("r", encoding="utf-8") as f:
            lines = f.readlines()
        
        # Filter out logs for users that don't exist
        remaining_logs = []
        removed_count = 0
        
        for line in lines:
            try:
                log = json.loads(line.strip())
                user_id = log.get("user_id")
                if user_id in valid_user_ids:
                    remaining_logs.append(line)
                else:
                    removed_count += 1
            except:
                # Keep malformed lines
                remaining_logs.append(line)
        
        # Write back filtered logs
        with LOGS_PATH.open("w", encoding="utf-8") as f:
            f.writelines(remaining_logs)
        
        return {
            "message": f"Cleaned up orphaned data successfully",
            "removed_logs": removed_count,
            "remaining_logs": len(remaining_logs)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error cleaning up data: {e}")


@app.post("/admin/reset-all-data")
def reset_all_data():
    """Reset all data - remove all users and attendance logs."""
    try:
        # Clear embeddings
        save_embeddings([])
        
        # Clear attendance logs
        if LOGS_PATH.exists():
            LOGS_PATH.unlink()
        
        # Clear backups
        backup_dir = STORAGE_DIR / "backups"
        if backup_dir.exists():
            import shutil
            shutil.rmtree(backup_dir)
            backup_dir.mkdir(exist_ok=True)
        
        return {
            "message": "All data has been reset successfully",
            "users_removed": "all",
            "attendance_logs_removed": "all",
            "backups_removed": "all"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error resetting data: {e}")


@app.get("/backups")
def list_backups():
    """List all user backups."""
    backup_dir = STORAGE_DIR / "backups"
    if not backup_dir.exists():
        return {"backups": []}
    
    backups = []
    for backup_file in backup_dir.glob("user_*.json"):
        try:
            with backup_file.open("r", encoding="utf-8") as f:
                backup_data = json.load(f)
                backups.append({
                    "filename": backup_file.name,
                    "user_name": backup_data.get("user", {}).get("name", "Unknown"),
                    "user_id": backup_data.get("user", {}).get("id", "Unknown"),
                    "deleted_at": backup_data.get("deleted_at", "Unknown"),
                    "attendance_logs_count": len(backup_data.get("attendance_logs", []))
                })
        except Exception as e:
            print(f"Error reading backup {backup_file}: {e}")
    
    # Sort by deleted_at (newest first)
    backups.sort(key=lambda x: x["deleted_at"], reverse=True)
    return {"backups": backups}


@app.post("/backups/{filename}/restore")
def restore_user_backup(filename: str):
    """Restore a user from backup."""
    backup_dir = STORAGE_DIR / "backups"
    backup_file = backup_dir / filename
    
    if not backup_file.exists():
        raise HTTPException(status_code=404, detail="Backup file not found")
    
    try:
        with backup_file.open("r", encoding="utf-8") as f:
            backup_data = json.load(f)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid backup file: {e}")
    
    user = backup_data.get("user")
    if not user:
        raise HTTPException(status_code=400, detail="No user data in backup")
    
    # Check if user already exists
    embeddings = load_embeddings()
    existing_user = next((u for u in embeddings if u["id"] == user["id"]), None)
    if existing_user:
        raise HTTPException(status_code=409, detail="User already exists")
    
    # Restore user to embeddings
    embeddings.append(user)
    save_embeddings(embeddings)
    
    # Restore attendance logs
    attendance_logs = backup_data.get("attendance_logs", [])
    if attendance_logs and LOGS_PATH.exists():
        try:
            with LOGS_PATH.open("a", encoding="utf-8") as f:
                for log in attendance_logs:
                    f.write(json.dumps(log, ensure_ascii=False) + "\n")
        except Exception as e:
            print(f"Error restoring attendance logs: {e}")
    
    return {
        "message": f"User {user['name']} restored successfully",
        "attendance_logs_restored": len(attendance_logs)
    }


@app.get("/backups/{filename}/details")
def get_backup_details(filename: str):
    """Get detailed information about a backup."""
    backup_dir = STORAGE_DIR / "backups"
    backup_file = backup_dir / filename
    
    if not backup_file.exists():
        raise HTTPException(status_code=404, detail="Backup file not found")
    
    try:
        with backup_file.open("r", encoding="utf-8") as f:
            backup_data = json.load(f)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid backup file: {e}")
    
    return backup_data


# Attendance and work hours endpoints
@app.get("/attendance/get")
def get_attendance_logs(limit: int = 50):
    """Get attendance logs"""
    if not LOGS_PATH.exists():
        return {"items": [], "count": 0}
    
    try:
        with LOGS_PATH.open("r", encoding="utf-8") as f:
            lines = f.readlines()
            items = []
            for line in lines[-limit:]:  # Get last N lines
                try:
                    item = json.loads(line.strip())
                    items.append(item)
                except:
                    continue
            return {"items": items, "count": len(items)}
    except Exception:
        return {"items": [], "count": 0}


@app.get("/attendance/work-hours")
def get_work_hours(date: Optional[str] = None):
    """Calculate work hours for users on a specific date"""
    if not LOGS_PATH.exists():
        return {"users": []}
    
    try:
        # Parse date or use today
        if date:
            target_date = datetime.strptime(date, "%Y-%m-%d").date()
        else:
            target_date = datetime.now().date()
        
        # Load attendance logs
        with LOGS_PATH.open("r", encoding="utf-8") as f:
            lines = f.readlines()
        
        # Filter logs for target date (using UTC+7 timezone)
        daily_logs = []
        vietnam_tz = timezone(timedelta(hours=7))
        for line in lines:
            try:
                log = json.loads(line.strip())
                # Convert UTC timestamp to Vietnam timezone
                log_date = datetime.fromtimestamp(log["ts"], tz=vietnam_tz).date()
                if log_date == target_date and log["matched"]:
                    daily_logs.append(log)
            except:
                continue
        
        # Group by user
        user_logs = {}
        for log in daily_logs:
            user_id = log["user_id"]
            if user_id not in user_logs:
                user_logs[user_id] = []
            user_logs[user_id].append(log)
        
        # Calculate work hours for each user
        users_work_hours = []
        for user_id, logs in user_logs.items():
            if len(logs) < 2:
                continue
                
            # Sort by timestamp
            logs.sort(key=lambda x: x["ts"])
            
            # Get first and last check-in (quét thành công đầu tiên và cuối cùng)
            first_check_in = logs[0]["ts"]
            last_check_out = logs[-1]["ts"]
            
            # Convert to datetime for easier handling (using UTC+7 timezone)
            vietnam_tz = timezone(timedelta(hours=7))
            first_check_in_dt = datetime.fromtimestamp(first_check_in, tz=vietnam_tz)
            last_check_out_dt = datetime.fromtimestamp(last_check_out, tz=vietnam_tz)
            
            # Calculate work hours based on first and last successful scan
            # Simple calculation: last scan - first scan
            work_hours = (last_check_out - first_check_in) / 3600
            
            # Determine if it's cross-day work (after midnight)
            cross_day = False
            if first_check_in_dt.date() != last_check_out_dt.date():
                cross_day = True
            elif last_check_out_dt.hour < 6 and first_check_in_dt.hour >= 22:
                # Same day but late night work (22:00-06:00)
                cross_day = True
            
            users_work_hours.append({
                "user_id": user_id,
                "name": logs[0]["name"],
                "first_check_in": first_check_in,
                "last_check_out": last_check_out,
                "work_hours": round(work_hours, 2),
                "check_ins": len(logs),
                "cross_day": cross_day
            })
        
        return {"users": users_work_hours}
        
    except Exception as e:
        return {"users": [], "error": str(e)}


@app.get("/attendance/work-hours/summary")
def get_work_hours_summary(start_date: Optional[str] = None, end_date: Optional[str] = None):
    """Get work hours summary for a date range"""
    if not LOGS_PATH.exists():
        return {"summary": []}
    
    try:
        # Parse date range or use last 7 days
        if start_date and end_date:
            start = datetime.strptime(start_date, "%Y-%m-%d").date()
            end = datetime.strptime(end_date, "%Y-%m-%d").date()
        else:
            end = datetime.now().date()
            start = end - timedelta(days=7)
        
        # Load attendance logs
        with LOGS_PATH.open("r", encoding="utf-8") as f:
            lines = f.readlines()
        
        # Filter logs for date range (using UTC+7 timezone)
        range_logs = []
        vietnam_tz = timezone(timedelta(hours=7))
        for line in lines:
            try:
                log = json.loads(line.strip())
                # Convert UTC timestamp to Vietnam timezone
                log_date = datetime.fromtimestamp(log["ts"], tz=vietnam_tz).date()
                if start <= log_date <= end and log["matched"]:
                    range_logs.append(log)
            except:
                continue
        
        # Group by user and date
        user_date_logs = {}
        for log in range_logs:
            user_id = log["user_id"]
            log_date = datetime.fromtimestamp(log["ts"]).date()
            key = (user_id, log_date)
            
            if key not in user_date_logs:
                user_date_logs[key] = []
            user_date_logs[key].append(log)
        
        # Calculate summary
        summary = []
        for (user_id, date), logs in user_date_logs.items():
            if len(logs) < 2:
                continue
                
            logs.sort(key=lambda x: x["ts"])
            first_check_in = logs[0]["ts"]
            last_check_out = logs[-1]["ts"]
            
            # Convert to datetime for easier handling (using UTC+7 timezone)
            vietnam_tz = timezone(timedelta(hours=7))
            first_check_in_dt = datetime.fromtimestamp(first_check_in, tz=vietnam_tz)
            last_check_out_dt = datetime.fromtimestamp(last_check_out, tz=vietnam_tz)
            
            # Calculate work hours based on first and last successful scan
            work_hours = (last_check_out - first_check_in) / 3600
            
            # Determine if it's cross-day work (after midnight)
            cross_day = False
            if first_check_in_dt.date() != last_check_out_dt.date():
                cross_day = True
            elif last_check_out_dt.hour < 6 and first_check_in_dt.hour >= 22:
                # Same day but late night work (22:00-06:00)
                cross_day = True
            
            summary.append({
                "user_id": user_id,
                "name": logs[0]["name"],
                "date": date.isoformat(),
                "first_check_in": first_check_in,
                "last_check_out": last_check_out,
                "work_hours": round(work_hours, 2),
                "check_ins": len(logs),
                "cross_day": cross_day
            })
        
        return {"summary": summary}
        
    except Exception as e:
        return {"summary": [], "error": str(e)}


# Demo endpoint
@app.get("/demo")
def get_demo_page():
    """Simple demo page"""
    from fastapi.responses import HTMLResponse
    return HTMLResponse(content="""
    <!DOCTYPE html>
    <html>
    <head>
        <title>API Demo - User Friendly</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
        <style>
            body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
            .card { background: rgba(255,255,255,0.95); border-radius: 15px; margin-bottom: 20px; }
            .time-badge { background: #48bb78; color: white; padding: 5px 10px; border-radius: 15px; font-size: 0.8rem; }
            .status-success { background: #48bb78; color: white; padding: 5px 10px; border-radius: 15px; }
            .status-danger { background: #f56565; color: white; padding: 5px 10px; border-radius: 15px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="text-center text-white mb-4">
                <h1>API Demo - Hiển thị dữ liệu thân thiện</h1>
                <p>Chuyển đổi JSON thành giao diện dễ đọc với timestamp được quy đổi</p>
            </div>
            
            <div class="row">
                <div class="col-md-6">
                    <div class="card p-3">
                        <h4>Work Hours API</h4>
                        <button class="btn btn-primary" onclick="loadWorkHours()">Tải dữ liệu chấm công</button>
                        <div id="work-hours-result" class="mt-3"></div>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="card p-3">
                        <h4>History API</h4>
                        <button class="btn btn-success" onclick="loadHistory()">Tải dữ liệu lịch sử</button>
                        <div id="history-result" class="mt-3"></div>
                    </div>
                </div>
            </div>
        </div>
        
        <script>
        function formatTime(timestamp) {
            if (!timestamp) return '-';
            const date = new Date(timestamp * 1000);
            return date.toLocaleString('vi-VN');
        }
        
        async function loadWorkHours() {
            const result = document.getElementById('work-hours-result');
            result.innerHTML = '<div class="spinner-border"></div>';
            try {
                const response = await fetch('/attendance/work-hours');
                const data = await response.json();
                
                if (data.users && data.users.length > 0) {
                    result.innerHTML = data.users.map(user => `
                        <div class="border rounded p-3 mb-2">
                            <h5>${user.name}</h5>
                            <p><strong>Check In đầu:</strong> <span class="time-badge">${formatTime(user.first_check_in)}</span></p>
                            <p><strong>Check Out cuối:</strong> <span class="time-badge">${formatTime(user.last_check_out)}</span></p>
                            <p><strong>Tổng giờ:</strong> <span class="text-success">${user.work_hours}h</span></p>
                            <p><strong>Số lần quét:</strong> ${user.check_ins.length}</p>
                        </div>
                    `).join('');
                } else {
                    result.innerHTML = '<p class="text-muted">Không có dữ liệu</p>';
                }
            } catch(e) {
                result.innerHTML = '<div class="alert alert-danger">Lỗi: ' + e.message + '</div>';
            }
        }
        
        async function loadHistory() {
            const result = document.getElementById('history-result');
            result.innerHTML = '<div class="spinner-border"></div>';
            try {
                const response = await fetch('/attendance/get?limit=5');
                const data = await response.json();
                
                if (data.items && data.items.length > 0) {
                    result.innerHTML = data.items.map(item => `
                        <div class="border rounded p-3 mb-2">
                            <p><strong>Thời gian:</strong> <span class="time-badge">${formatTime(item.ts)}</span></p>
                            <p><strong>User:</strong> ${item.name || 'Unknown'}</p>
                            <p><strong>Trạng thái:</strong> 
                                <span class="status-${item.matched ? 'success' : 'danger'}">
                                    ${item.matched ? 'Thành công' : 'Thất bại'}
                                </span>
                            </p>
                            <p><strong>Distance:</strong> ${item.distance ? item.distance.toFixed(3) : '-'}</p>
                        </div>
                    `).join('');
                } else {
                    result.innerHTML = '<p class="text-muted">Không có dữ liệu</p>';
                }
            } catch(e) {
                result.innerHTML = '<div class="alert alert-danger">Lỗi: ' + e.message + '</div>';
            }
        }
        </script>
    </body>
    </html>
    """)


# Admin endpoint
@app.get("/admin/")
def get_admin_page():
    """Admin dashboard page"""
    from fastapi.responses import HTMLResponse
    return HTMLResponse(content="""
    <!DOCTYPE html>
    <html lang="vi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>FaceLog Admin Dashboard</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
        <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
        <style>
            body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
            .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
            .card { background: rgba(255,255,255,0.95); border-radius: 15px; margin-bottom: 20px; box-shadow: 0 10px 30px rgba(0,0,0,0.1); }
            .stat-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 15px; text-align: center; }
            .btn-primary { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border: none; }
            .btn-primary:hover { background: linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%); }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="text-center text-white mb-4">
                <h1><i class="fas fa-chart-line me-3"></i>FaceLog Admin Dashboard</h1>
                <p class="lead">Manage users and monitor face recognition system</p>
                <button class="btn btn-primary btn-lg" onclick="testRecognition()">
                    <i class="fas fa-camera me-2"></i>TEST FACE RECOGNITION
                </button>
            </div>
            
            <div class="row mb-4">
                <div class="col-md-4">
                    <div class="stat-card">
                        <h3 id="total-users">0</h3>
                        <p>TOTAL USERS</p>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="stat-card">
                        <h3 id="active-users">0</h3>
                        <p>ACTIVE USERS</p>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="stat-card">
                        <h3 id="attendance-logs">0</h3>
                        <p>ATTENDANCE LOGS</p>
                    </div>
                </div>
            </div>
            
            <div class="row">
                <div class="col-md-6">
                    <div class="card p-4">
                        <h4><i class="fas fa-user-plus me-2"></i>Register New User</h4>
                        <form id="registerForm">
                            <div class="mb-3">
                                <label class="form-label">Full Name *</label>
                                <input type="text" class="form-control" id="userName" value="Thanh" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label">Position</label>
                                <input type="text" class="form-control" id="userPosition" value="IT">
                            </div>
                            <div class="mb-3">
                                <label class="form-label">Face Image *</label>
                                <input type="file" class="form-control" id="userImage" accept="image/*" required>
                            </div>
                            <button type="submit" class="btn btn-primary">REGISTER USER</button>
                        </form>
                        <div id="registerResult" class="mt-3"></div>
                    </div>
                </div>
                
                <div class="col-md-6">
                    <div class="card p-4">
                        <h4><i class="fas fa-cog me-2"></i>System Status</h4>
                        <div class="mb-3">
                            <label class="form-label">Recognition Threshold</label>
                            <input type="range" class="form-range" id="threshold" min="0.1" max="1.0" step="0.05" value="0.45">
                            <span id="thresholdValue">0.45</span>
                        </div>
                        <button class="btn btn-primary" onclick="updateThreshold()">UPDATE THRESHOLD</button>
                    </div>
                </div>
            </div>
            
            <div class="card p-4">
                <h4><i class="fas fa-users me-2"></i>Registered Users</h4>
                <div class="table-responsive">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>User ID</th>
                                <th>Name</th>
                                <th>Position</th>
                                <th>Model</th>
                                <th>Created</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody id="usersTable">
                            <tr><td colspan="7" class="text-center">Loading...</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        
        <script>
        // Load stats on page load
        document.addEventListener('DOMContentLoaded', function() {
            loadStats();
            loadUsers();
        });
        
        // Update threshold display
        document.getElementById('threshold').addEventListener('input', function() {
            document.getElementById('thresholdValue').textContent = this.value;
        });
        
        async function loadStats() {
            try {
                const response = await fetch('/api/stats');
                const data = await response.json();
                document.getElementById('total-users').textContent = data.total_users;
                document.getElementById('active-users').textContent = data.active_users;
                document.getElementById('attendance-logs').textContent = data.attendance_logs;
            } catch(e) {
                console.error('Error loading stats:', e);
            }
        }
        
        async function loadUsers() {
            try {
                const response = await fetch('/api/users');
                const data = await response.json();
                const tbody = document.getElementById('usersTable');
                
                if (data.users && data.users.length > 0) {
                    tbody.innerHTML = data.users.map(user => `
                        <tr>
                            <td><code>${user.id.substring(0, 8)}...</code></td>
                            <td>${user.name}</td>
                            <td>${user.position || '-'}</td>
                            <td>${user.model}</td>
                            <td>${new Date(user.created_at).toLocaleDateString()}</td>
                            <td><span class="badge bg-success">Active</span></td>
                            <td>
                                <button class="btn btn-sm btn-outline-danger" onclick="deleteUser('${user.id}')">
                                    <i class="fas fa-trash"></i>
                                </button>
                            </td>
                        </tr>
                    `).join('');
                } else {
                    tbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted">No users found</td></tr>';
                }
            } catch(e) {
                console.error('Error loading users:', e);
                document.getElementById('usersTable').innerHTML = '<tr><td colspan="7" class="text-center text-danger">Error loading users</td></tr>';
            }
        }
        
        document.getElementById('registerForm').addEventListener('submit', async function(e) {
            e.preventDefault();
            const result = document.getElementById('registerResult');
            result.innerHTML = '<div class="spinner-border"></div>';
            
            try {
                const file = document.getElementById('userImage').files[0];
                if (!file) {
                    result.innerHTML = '<div class="alert alert-danger">Please select an image</div>';
                    return;
                }
                
                const base64 = await fileToBase64(file);
                const response = await fetch('/register', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({
                        name: document.getElementById('userName').value,
                        position: document.getElementById('userPosition').value,
                        image_base64: base64
                    })
                });
                
                const data = await response.json();
                if (response.ok) {
                    result.innerHTML = '<div class="alert alert-success">User registered successfully!</div>';
                    loadStats();
                    loadUsers();
                } else {
                    result.innerHTML = '<div class="alert alert-danger">Error: ' + (data.detail || 'Unknown error') + '</div>';
                }
            } catch(e) {
                result.innerHTML = '<div class="alert alert-danger">Error: ' + e.message + '</div>';
            }
        });
        
        function fileToBase64(file) {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.readAsDataURL(file);
                reader.onload = () => {
                    const base64 = reader.result.split(',')[1];
                    resolve(base64);
                };
                reader.onerror = error => reject(error);
            });
        }
        
        function updateThreshold() {
            const threshold = document.getElementById('threshold').value;
            alert('Threshold updated to: ' + threshold);
        }
        
        function testRecognition() {
            alert('Face recognition test feature coming soon!');
        }
        
        function deleteUser(userId) {
            if (confirm('Are you sure you want to delete this user?')) {
                alert('Delete user: ' + userId);
            }
        }
        </script>
    </body>
    </html>
    """)


# Admin API endpoints
@app.get("/api/users")
def get_users_api():
    """Get all registered users"""
    records = load_embeddings()
    return {
        "total_users": len(records),
        "active_users": len([r for r in records if r.get("active", True)]),
        "users": records
    }


class UserUpdateRequest(BaseModel):
    name: str
    position: str = ""
    image_base64: str = ""

@app.put("/users/{user_id}")
def update_user(user_id: str, user_data: UserUpdateRequest):
    """Update user information"""
    records = load_embeddings()
    
    # Find user
    user_index = None
    for i, record in enumerate(records):
        if record["id"] == user_id:
            user_index = i
            break
    
    if user_index is None:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Update user data
    records[user_index]["name"] = user_data.name
    records[user_index]["position"] = user_data.position
    
    # Update image if provided
    if user_data.image_base64:
        try:
            # Validate and process new image
            img = _load_image_from_base64(user_data.image_base64)
            new_embedding = _represent_with_deepface(img)
            records[user_index]["embedding"] = new_embedding.tolist()
            records[user_index]["image_base64"] = user_data.image_base64
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Invalid image: {str(e)}")
    
    # Save updated records
    save_embeddings(records)
    
    return {"message": "User updated successfully", "user_id": user_id}


@app.get("/api/logs")
def get_logs_api(limit: int = 50):
    """Get attendance logs"""
    if not LOGS_PATH.exists():
        return {"items": [], "count": 0}
    
    try:
        with LOGS_PATH.open("r", encoding="utf-8") as f:
            lines = f.readlines()
            items = []
            for line in lines[-limit:]:  # Get last N lines
                try:
                    item = json.loads(line.strip())
                    items.append(item)
                except:
                    continue
            return {"items": items, "count": len(items)}
    except Exception:
        return {"items": [], "count": 0}


@app.get("/api/stats")
def get_stats_api():
    """Get system statistics"""
    records = load_embeddings()
    total_users = len(records)
    active_users = len([r for r in records if r.get("active", True)])
    
    # Count logs
    log_count = 0
    if LOGS_PATH.exists():
        try:
            with LOGS_PATH.open("r", encoding="utf-8") as f:
                log_count = sum(1 for _ in f)
        except:
            pass
    
    return {
        "total_users": total_users,
        "active_users": active_users,
        "attendance_logs": log_count,
        "recognition_threshold": RECOGNITION_THRESHOLD
    }


# Dashboard endpoint
@app.get("/dashboard")
def get_dashboard():
    """Beautiful admin dashboard"""
    from fastapi.responses import HTMLResponse
    return HTMLResponse(content="""
    <!DOCTYPE html>
    <html lang="vi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>FaceLog Admin Dashboard</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
        <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
        <style>
            body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
            .dashboard-container { max-width: 1400px; margin: 0 auto; padding: 20px; }
            .header { background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); border-radius: 20px; padding: 30px; margin-bottom: 30px; text-align: center; color: white; }
            .feature-card { background: rgba(255,255,255,0.95); border-radius: 20px; padding: 30px; margin-bottom: 30px; box-shadow: 0 15px 35px rgba(0,0,0,0.1); }
            .stat-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 25px; border-radius: 15px; text-align: center; }
            .stat-number { font-size: 2.5rem; font-weight: bold; margin-bottom: 8px; }
            .time-badge { background: linear-gradient(45deg, #48bb78, #38a169); color: white; padding: 5px 12px; border-radius: 20px; font-size: 0.8rem; }
        </style>
    </head>
    <body>
        <div class="dashboard-container">
            <div class="header">
                <h1><i class="fas fa-chart-line me-3"></i>FaceLog Admin Dashboard</h1>
                <p class="lead mb-0">Hệ thống quản lý chấm công với Face Recognition</p>
            </div>
            
            <div class="feature-card">
                <h3><i class="fas fa-user-clock me-2"></i>Dữ liệu Chấm Công</h3>
                <button class="btn btn-primary" onclick="loadData()">Tải dữ liệu</button>
                <div id="data-content" class="mt-3"></div>
            </div>
        </div>
        
        <script>
        function formatTime(timestamp) {
            if (!timestamp) return '-';
            const date = new Date(timestamp * 1000);
            return date.toLocaleString('vi-VN');
        }
        
        async function loadData() {
            const content = document.getElementById('data-content');
            content.innerHTML = '<div class="spinner-border"></div>';
            
            try {
                const response = await fetch('/attendance/get?limit=10');
                const data = await response.json();
                
                if (data.items && data.items.length > 0) {
                    content.innerHTML = data.items.map(item => `
                        <div class="border rounded p-3 mb-2">
                            <p><strong>Thời gian:</strong> <span class="time-badge">${formatTime(item.ts)}</span></p>
                            <p><strong>User:</strong> ${item.name || 'Unknown'}</p>
                            <p><strong>Trạng thái:</strong> 
                                <span class="badge ${item.matched ? 'bg-success' : 'bg-danger'}">
                                    ${item.matched ? 'Thành công' : 'Thất bại'}
                                </span>
                            </p>
                        </div>
                    `).join('');
                } else {
                    content.innerHTML = '<p class="text-muted">Không có dữ liệu</p>';
                }
            } catch(e) {
                content.innerHTML = '<div class="alert alert-danger">Lỗi: ' + e.message + '</div>';
            }
        }
        </script>
    </body>
    </html>
    """)


# Web interface endpoints
@app.get("/web/")
def get_web_home():
    """Web interface home page"""
    from fastapi.responses import FileResponse
    return FileResponse("/app/server/web/index.html")

@app.get("/web/{path:path}")
def get_web_file(path: str):
    """Serve web interface files"""
    from fastapi.responses import FileResponse
    file_path = f"/app/server/web/{path}"
    if os.path.exists(file_path):
        return FileResponse(file_path)
    else:
        raise HTTPException(status_code=404, detail="File not found")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)


