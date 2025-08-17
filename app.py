import os
import sys

# Add system path for proper imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from flask import Flask, request, jsonify
from flask_cors import CORS
import sqlite3
import base64
import io
import numpy as np
from PIL import Image
import uuid
import logging
from datetime import datetime
import hashlib

# Import deepface with better error handling
try:
    from deepface import DeepFace
    DEEPFACE_AVAILABLE = True
    print("✅ DeepFace imported successfully")
except ImportError as e:
    print(f"⚠️ DeepFace not available: {e}")
    print("🔄 Installing DeepFace...")
    try:
        import subprocess
        subprocess.check_call([sys.executable, "-m", "pip", "install", "deepface"])
        from deepface import DeepFace
        DEEPFACE_AVAILABLE = True
        print("✅ DeepFace installed and imported successfully")
    except Exception as install_error:
        print(f"❌ Failed to install DeepFace: {install_error}")
        DEEPFACE_AVAILABLE = False

app = Flask(__name__)
CORS(app)  # Enable CORS for cross-origin requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Database configuration
DATABASE = 'face_recognition.db'
UPLOAD_FOLDER = 'uploaded_faces'

if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

def init_database():
    """Initialize SQLite database with required tables"""
    try:
        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()
        
        # Users table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                department TEXT,
                email TEXT UNIQUE,
                face_image_path TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Face encodings table (for backup/comparison)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS face_encodings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER,
                encoding_hash TEXT,
                model_name TEXT DEFAULT 'VGG-Face',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        ''')
        
        # Login history
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS login_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER,
                action_type TEXT DEFAULT 'login',
                status TEXT,
                confidence REAL,
                ip_address TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        ''')
        
        conn.commit()
        conn.close()
        logger.info("Database initialized successfully")
        return True
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        return False

def base64_to_image(base64_string):
    """Convert base64 string to PIL Image"""
    try:
        # Remove data URL prefix if present
        if ',' in base64_string:
            base64_string = base64_string.split(',')[1]
        
        image_data = base64.b64decode(base64_string)
        image = Image.open(io.BytesIO(image_data))
        return image
    except Exception as e:
        logger.error(f"Error converting base64 to image: {str(e)}")
        return None

def save_image(image, user_id):
    """Save image to disk and return file path"""
    try:
        filename = f"user_{user_id}_{uuid.uuid4().hex[:8]}.jpg"
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        
        # Convert to RGB if necessary
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        image.save(filepath, 'JPEG', quality=95)
        return filepath
    except Exception as e:
        logger.error(f"Error saving image: {str(e)}")
        return None

@app.route('/', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'Face Recognition Server',
        'version': '1.0.0',
        'deepface_available': DEEPFACE_AVAILABLE,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/users/register', methods=['POST'])
def register_user():
    """Register a new user with face image"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        name = data.get('name')
        department = data.get('department', 'Unknown')
        email = data.get('email')
        face_image_base64 = data.get('face_image')
        
        if not name or not face_image_base64:
            return jsonify({'error': 'Name and face_image are required'}), 400
        
        # Convert base64 to image
        image = base64_to_image(face_image_base64)
        if image is None:
            return jsonify({'error': 'Invalid image format'}), 400
        
        # Insert user into database
        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO users (name, department, email)
            VALUES (?, ?, ?)
        ''', (name, department, email))
        
        user_id = cursor.lastrowid
        
        # Save face image
        image_path = save_image(image, user_id)
        if image_path is None:
            conn.rollback()
            conn.close()
            return jsonify({'error': 'Failed to save image'}), 500
        
        # Update user with image path
        cursor.execute('''
            UPDATE users SET face_image_path = ? WHERE id = ?
        ''', (image_path, user_id))
        
        # Generate face encoding hash if DeepFace is available
        if DEEPFACE_AVAILABLE:
            try:
                # Use DeepFace to analyze the face
                analysis = DeepFace.represent(img_path=image_path, model_name='VGG-Face')
                encoding_hash = hashlib.md5(str(analysis[0]['embedding']).encode()).hexdigest()
                
                cursor.execute('''
                    INSERT INTO face_encodings (user_id, encoding_hash, model_name)
                    VALUES (?, ?, ?)
                ''', (user_id, encoding_hash, 'VGG-Face'))
            except Exception as e:
                logger.warning(f"Could not generate face encoding: {str(e)}")
        
        conn.commit()
        conn.close()
        
        logger.info(f"User registered successfully: {name} (ID: {user_id})")
        
        return jsonify({
            'success': True,
            'user_id': user_id,
            'name': name,
            'department': department,
            'message': 'User registered successfully'
        }), 201
        
    except Exception as e:
        logger.error(f"Error in register_user: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@app.route('/api/auth/recognize', methods=['POST'])
def recognize_face():
    """Recognize face from uploaded image"""
    try:
        if not DEEPFACE_AVAILABLE:
            return jsonify({
                'error': 'Face recognition not available - DeepFace not installed'
            }), 503
            
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        face_image_base64 = data.get('face_image')
        
        if not face_image_base64:
            return jsonify({'error': 'face_image is required'}), 400
        
        # Convert base64 to image
        image = base64_to_image(face_image_base64)
        if image is None:
            return jsonify({'error': 'Invalid image format'}), 400
        
        # Save temporary image for recognition
        temp_filename = f"temp_{uuid.uuid4().hex[:8]}.jpg"
        temp_filepath = os.path.join(UPLOAD_FOLDER, temp_filename)
        
        # Convert to RGB if necessary
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        image.save(temp_filepath, 'JPEG', quality=95)
        
        # Get all registered users
        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT id, name, department, face_image_path 
            FROM users 
            WHERE face_image_path IS NOT NULL
        ''')
        
        users = cursor.fetchall()
        
        if not users:
            os.remove(temp_filepath)
            conn.close()
            return jsonify({
                'success': False,
                'error': 'No registered users found'
            }), 404
        
        best_match = None
        highest_confidence = 0.0
        
        # Compare with each registered user
        for user in users:
            user_id, name, department, face_image_path = user
            
            if not os.path.exists(face_image_path):
                logger.warning(f"Face image not found for user {name}: {face_image_path}")
                continue
            
            try:
                # Use DeepFace to verify faces
                result = DeepFace.verify(
                    img1_path=temp_filepath,
                    img2_path=face_image_path,
                    model_name='VGG-Face',
                    distance_metric='cosine'
                )
                
                # Convert distance to confidence score
                distance = result['distance']
                confidence = max(0, (1 - distance) * 100)  # Convert to percentage
                
                logger.info(f"Comparison with {name}: confidence={confidence:.2f}%")
                
                if result['verified'] and confidence > highest_confidence:
                    highest_confidence = confidence
                    best_match = {
                        'user_id': user_id,
                        'name': name,
                        'department': department,
                        'confidence': confidence
                    }
                    
            except Exception as e:
                logger.error(f"Error comparing with user {name}: {str(e)}")
                continue
        
        # Clean up temporary file
        try:
            os.remove(temp_filepath)
        except:
            pass
        
        # Record login attempt
        client_ip = request.remote_addr
        
        if best_match and highest_confidence >= 60:  # 60% threshold
            # Successful recognition
            cursor.execute('''
                INSERT INTO login_history (user_id, action_type, status, confidence, ip_address)
                VALUES (?, ?, ?, ?, ?)
            ''', (best_match['user_id'], 'login', 'success', highest_confidence, client_ip))
            
            conn.commit()
            conn.close()
            
            logger.info(f"Face recognized: {best_match['name']} ({highest_confidence:.2f}%)")
            
            return jsonify({
                'success': True,
                'user_id': best_match['user_id'],
                'user_name': best_match['name'],
                'department': best_match['department'],
                'confidence': round(highest_confidence, 2)
            })
        else:
            # Failed recognition
            cursor.execute('''
                INSERT INTO login_history (user_id, action_type, status, confidence, ip_address)
                VALUES (?, ?, ?, ?, ?)
            ''', (None, 'login', 'failed', highest_confidence, client_ip))
            
            conn.commit()
            conn.close()
            
            logger.info(f"Face not recognized. Best match: {highest_confidence:.2f}%")
            
            return jsonify({
                'success': False,
                'error': 'Face not recognized',
                'best_match_confidence': round(highest_confidence, 2) if highest_confidence > 0 else 0
            })
        
    except Exception as e:
        logger.error(f"Error in recognize_face: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@app.route('/api/users', methods=['GET'])
def get_users():
    """Get all registered users"""
    try:
        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT id, name, department, email, created_at
            FROM users
            ORDER BY created_at DESC
        ''')
        
        users = []
        for row in cursor.fetchall():
            users.append({
                'id': row[0],
                'name': row[1],
                'department': row[2],
                'email': row[3],
                'created_at': row[4]
            })
        
        conn.close()
        
        return jsonify({
            'success': True,
            'users': users,
            'count': len(users)
        })
        
    except Exception as e:
        logger.error(f"Error in get_users: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/history', methods=['GET'])
def get_login_history():
    """Get login history"""
    try:
        limit = request.args.get('limit', 50, type=int)
        
        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT h.id, h.user_id, u.name, h.action_type, h.status, 
                   h.confidence, h.ip_address, h.created_at
            FROM login_history h
            LEFT JOIN users u ON h.user_id = u.id
            ORDER BY h.created_at DESC
            LIMIT ?
        ''', (limit,))
        
        history = []
        for row in cursor.fetchall():
            history.append({
                'id': row[0],
                'user_id': row[1],
                'user_name': row[2] or 'Unknown',
                'action_type': row[3],
                'status': row[4],
                'confidence': row[5],
                'ip_address': row[6],
                'created_at': row[7]
            })
        
        conn.close()
        
        return jsonify({
            'success': True,
            'history': history,
            'count': len(history)
        })
        
    except Exception as e:
        logger.error(f"Error in get_login_history: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    # Initialize database
    if not init_database():
        logger.error("Failed to initialize database. Exiting...")
        sys.exit(1)
    
    # Get port from environment variable (Railway uses this)
    port = int(os.environ.get('PORT', 5000))
    
    logger.info(f"Starting Face Recognition Server on port {port}")
    logger.info(f"DeepFace available: {DEEPFACE_AVAILABLE}")
    
    app.run(host='0.0.0.0', port=port, debug=False) 