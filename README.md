# Face Recognition Server

A Flask-based face recognition API server using DeepFace for face detection and recognition.

## Features

- **User Registration**: Register users with face images
- **Face Recognition**: Recognize faces from uploaded images
- **Login History**: Track all login attempts with confidence scores
- **RESTful API**: Easy integration with any client application
- **SQLite Database**: Lightweight database for user data
- **CORS Support**: Cross-origin requests enabled

## API Endpoints

### Health Check
```
GET /
```
Returns server health status.

### User Registration
```
POST /api/users/register
Content-Type: application/json

{
  "name": "Nguyễn Văn An",
  "department": "IT Department",
  "email": "an@company.com",
  "face_image": "base64_encoded_image"
}
```

### Face Recognition
```
POST /api/auth/recognize
Content-Type: application/json

{
  "face_image": "base64_encoded_image"
}
```

### Get All Users
```
GET /api/users
```

### Get Login History
```
GET /api/history?limit=50
```

## Installation

### Local Development

1. Clone this repository
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Run the server:
   ```bash
   python app.py
   ```

### Deploy to Railway

1. Create a new project on [Railway](https://railway.app)
2. Connect your GitHub repository
3. Railway will automatically detect the Python app and deploy it
4. The server will be available at your Railway-provided URL

## Environment Variables

- `PORT`: Port number (default: 5000, Railway sets this automatically)

## Database Schema

### Users Table
- `id`: Primary key
- `name`: User full name
- `department`: User department
- `email`: User email (unique)
- `face_image_path`: Path to stored face image
- `created_at`: Registration timestamp

### Face Encodings Table
- `id`: Primary key
- `user_id`: Foreign key to users table
- `encoding_hash`: MD5 hash of face encoding
- `model_name`: AI model used (VGG-Face)
- `created_at`: Creation timestamp

### Login History Table
- `id`: Primary key
- `user_id`: Foreign key to users table (null for failed attempts)
- `action_type`: Type of action (login)
- `status`: success/failed
- `confidence`: Recognition confidence percentage
- `ip_address`: Client IP address
- `created_at`: Attempt timestamp

## Usage with Qt Application

### Converting Image to Base64 (Qt/C++)
```cpp
// Convert QByteArray to base64 string
QString imageBase64 = imageData.toBase64();
```

### Example API Call (Qt/C++)
```cpp
// Register user
QJsonObject registerData;
registerData["name"] = "Nguyễn Văn An";
registerData["department"] = "IT Department";
registerData["email"] = "an@company.com";
registerData["face_image"] = imageBase64;

// Recognize face
QJsonObject recognizeData;
recognizeData["face_image"] = imageBase64;
```

## Face Recognition Models

The server uses **VGG-Face** model from DeepFace library:
- **Accuracy**: High accuracy for face recognition
- **Speed**: Optimized for cloud deployment
- **Threshold**: 60% confidence minimum for positive recognition

## Security Features

- Input validation for all endpoints
- Image format validation
- SQL injection protection
- Error handling and logging
- CORS configuration for cross-origin requests

## Performance

- **Recognition Time**: ~2-5 seconds per face
- **Concurrent Users**: Supports multiple simultaneous requests
- **Storage**: Images stored locally, database in SQLite
- **Memory Usage**: ~500MB RAM usage

## Troubleshooting

### Common Issues

1. **DeepFace Installation**: May require additional system dependencies
2. **Memory Usage**: Large images may cause memory issues
3. **Model Download**: First run downloads AI models (~100MB)

### Logs

Check server logs for detailed error information:
```bash
tail -f server.log
```

## License

MIT License - See LICENSE file for details 