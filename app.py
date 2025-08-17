import os
import sys
import sqlite3
import base64
import io
import uuid
import logging
from datetime import datetime
import hashlib

from flask import Flask, request, jsonify
from flask_cors import CORS
from PIL import Image

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
        'service': 'Face Recognition Server (Simplified)',
        'version': '1.0.0',
        'message': 'Server is running without DeepFace (for testing)',
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
        
        conn.commit()
        conn.close()
        
        logger.info(f"User registered successfully: {name} (ID: {user_id})")
        
        return jsonify({
            'success': True,
            'user_id': user_id,
            'name': name,
            'department': department,
            'message': 'User registered successfully (image saved, face recognition disabled)'
        }), 201
        
    except Exception as e:
        logger.error(f"Error in register_user: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@app.route('/api/auth/recognize', methods=['POST'])
def recognize_face():
    """Simulate face recognition for testing"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        face_image_base64 = data.get('face_image')
        
        if not face_image_base64:
            return jsonify({'error': 'face_image is required'}), 400
        
        # Get all registered users for simulation
        conn = sqlite3.connect(DATABASE)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT id, name, department FROM users LIMIT 1
        ''')
        
        user = cursor.fetchone()
        
        if not user:
            conn.close()
            return jsonify({
                'success': False,
                'error': 'No registered users found'
            }), 404
        
        # Simulate successful recognition for testing
        user_id, name, department = user
        confidence = 85.5  # Simulated confidence
        
        # Record login attempt
        client_ip = request.remote_addr
        cursor.execute('''
            INSERT INTO login_history (user_id, action_type, status, confidence, ip_address)
            VALUES (?, ?, ?, ?, ?)
        ''', (user_id, 'login', 'success', confidence, client_ip))
        
        conn.commit()
        conn.close()
        
        logger.info(f"Face recognized (simulated): {name} ({confidence}%)")
        
        return jsonify({
            'success': True,
            'user_id': user_id,
            'user_name': name,
            'department': department,
            'confidence': confidence,
            'message': 'Simulated recognition (DeepFace disabled for testing)'
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
    
    logger.info(f"Starting Simplified Face Recognition Server on port {port}")
    logger.info("Note: This version runs without DeepFace for testing purposes")
    
    app.run(host='0.0.0.0', port=port, debug=False) 