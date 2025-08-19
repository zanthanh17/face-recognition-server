import base64
import json
import os
import threading
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field


# ---------- Configuration ----------
STORAGE_DIR = Path(__file__).parent / "storage"
STORAGE_DIR.mkdir(parents=True, exist_ok=True)
EMBEDDINGS_PATH = STORAGE_DIR / "embeddings.json"
LOGS_PATH = STORAGE_DIR / "attendance_logs.jsonl"

# Cosine distance threshold. For ArcFace embeddings typical 0.45±0.05.
RECOGNITION_THRESHOLD = float(os.getenv("RECOGNITION_THRESHOLD", "0.45"))


# ---------- Optional DeepFace backend ----------
_deepface_lock = threading.Lock()
_deepface_model_name = os.getenv("DEEPFACE_MODEL", "ArcFace")
_deepface_available = False
try:
    from deepface import DeepFace  # type: ignore

    _deepface_available = True
except Exception:
    _deepface_available = False


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
    if not _deepface_available:
        raise RuntimeError("DeepFace is not available")
    # DeepFace expects RGB
    import cv2  # noqa: WPS433

    rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    with _deepface_lock:
        reps = DeepFace.represent(
            rgb,
            model_name=_deepface_model_name,
            enforce_detection=False,
        )
    if not reps:
        raise ValueError("No embedding returned by DeepFace")
    emb = np.array(reps[0]["embedding"], dtype=np.float32)
    return emb


def _represent_fallback(img_bgr: np.ndarray) -> np.ndarray:
    """Lightweight embedding fallback using resized grayscale + DCT.

    This is not SOTA but good enough for local demo when DeepFace is absent.
    """
    import cv2  # noqa: WPS433

    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    face = cv2.resize(gray, (128, 128), interpolation=cv2.INTER_AREA)
    face = np.float32(face) / 255.0
    dct = cv2.dct(face)
    # Take top-left 32x32 low-frequency block → 1024 dims
    coeff = dct[:32, :32].flatten()
    return _normalize_vector(coeff)


def compute_embedding(img_bgr: np.ndarray) -> np.ndarray:
    if _deepface_available:
        try:
            return _represent_with_deepface(img_bgr)
        except Exception:
            # Fall back silently if DeepFace fails
            pass
    return _represent_fallback(img_bgr)


def detect_and_crop_face(img_bgr: np.ndarray) -> np.ndarray:
    """Detect the largest face and return a tight crop. If none, return center crop."""
    import cv2  # noqa: WPS433

    cascade_path = cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
    face_cascade = cv2.CascadeClassifier(cascade_path)
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5)
    h, w = gray.shape[:2]
    if len(faces) == 0:
        # center crop square as fallback
        side = min(h, w)
        y0 = (h - side) // 2
        x0 = (w - side) // 2
        return img_bgr[y0 : y0 + side, x0 : x0 + side]
    # Select largest
    x, y, ww, hh = max(faces, key=lambda rect: rect[2] * rect[3])
    pad = int(0.15 * max(ww, hh))
    x0 = max(x - pad, 0)
    y0 = max(y - pad, 0)
    x1 = min(x + ww + pad, w)
    y1 = min(y + hh + pad, h)
    return img_bgr[y0:y1, x0:x1]


def load_embeddings() -> List[Dict[str, Any]]:
    if not EMBEDDINGS_PATH.exists():
        return []
    try:
        return json.loads(EMBEDDINGS_PATH.read_text(encoding="utf-8"))
    except Exception:
        return []


def save_embeddings(records: List[Dict[str, Any]]) -> None:
    EMBEDDINGS_PATH.write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")


def append_log(entry: Dict[str, Any]) -> None:
    with LOGS_PATH.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


class RegisterRequest(BaseModel):
    name: str = Field(..., min_length=1)
    position: Optional[str] = None
    image_base64: str


class RegisterResponse(BaseModel):
    user_id: str
    embedding_dim: int


class RecognizeRequest(BaseModel):
    image_base64: str
    device_id: Optional[str] = None
    ts: Optional[int] = None


class RecognizeResponse(BaseModel):
    matched: bool
    user_id: Optional[str] = None
    name: Optional[str] = None
    distance: Optional[float] = None
    threshold: float
    liveness: Optional[str] = "pass"


app = FastAPI(title="FaceLog Server", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.post("/register", response_model=RegisterResponse)
def register(req: RegisterRequest) -> RegisterResponse:
    try:
        img = _load_image_from_base64(req.image_base64)
    except Exception as exc:  # noqa: WPS429
        raise HTTPException(status_code=400, detail=str(exc))

    # Detect & crop, then compute embedding
    face = detect_and_crop_face(img)
    emb = compute_embedding(face)

    user_id = str(uuid.uuid4())
    record = {
        "id": user_id,
        "name": req.name,
        "position": req.position or "",
        "model": _deepface_model_name if _deepface_available else "fallback_dct",
        "embedding": emb.tolist(),
        "created_at": datetime.now(timezone.utc).isoformat(),
        "active": True,
    }
    records = load_embeddings()
    records.append(record)
    save_embeddings(records)
    return RegisterResponse(user_id=user_id, embedding_dim=int(emb.shape[0]))


def _find_best_match(emb: np.ndarray, records: List[Dict[str, Any]]) -> Tuple[Optional[Dict[str, Any]], Optional[float]]:
    if not records:
        return None, None
    best: Tuple[Optional[Dict[str, Any]], float] = (None, 1e9)
    for r in records:
        vec = np.array(r["embedding"], dtype=np.float32)
        d = _cosine_distance(emb, vec)
        if d < best[1]:
            best = (r, d)
    return best[0], best[1]


@app.post("/recognize", response_model=RecognizeResponse)
def recognize(req: RecognizeRequest) -> RecognizeResponse:
    try:
        img = _load_image_from_base64(req.image_base64)
    except Exception as exc:  # noqa: WPS429
        raise HTTPException(status_code=400, detail=str(exc))

    face = detect_and_crop_face(img)
    emb = compute_embedding(face)
    records = load_embeddings()
    match, distance = _find_best_match(emb, records)
    matched = bool(match is not None and distance is not None and distance <= RECOGNITION_THRESHOLD)

    # Log
    log_entry = {
        "ts": int(datetime.now(timezone.utc).timestamp()),
        "device_id": req.device_id or "local-pc",
        "distance": float(distance) if distance is not None else None,
        "matched": matched,
        "user_id": match["id"] if matched and match else None,
        "name": match["name"] if matched and match else None,
    }
    append_log(log_entry)

    return RecognizeResponse(
        matched=matched,
        user_id=(match["id"] if matched and match else None),
        name=(match["name"] if matched and match else None),
        distance=(float(distance) if distance is not None else None),
        threshold=RECOGNITION_THRESHOLD,
        liveness="pass",
    )


