# Face Recognition Server

A FastAPI-based face recognition server with web interface for attendance tracking.

## 📁 Project Structure

```
server/
├── main.py                    # Main FastAPI application
├── requirements.txt           # Dependencies
├── requirements-render.txt    # Render deployment dependencies
├── Dockerfile                # Docker configuration
├── __init__.py               # Python package marker
│
├── api/                      # API-related files
│   ├── __init__.py
│   ├── routes/               # API route modules
│   │   └── __init__.py
│   ├── models/               # Pydantic models
│   │   └── __init__.py
│   └── services/             # Business logic
│       └── __init__.py
│
├── web/                      # Web interface
│   ├── static/               # Static assets
│   │   ├── css/              # Stylesheets
│   │   │   ├── main.css      # Main styles
│   │   │   ├── components.css # Component styles
│   │   │   └── pages.css     # Page-specific styles
│   │   ├── js/               # JavaScript files
│   │   │   ├── components/   # Reusable components
│   │   │   ├── pages/        # Page-specific logic
│   │   │   └── utils/        # Utility functions
│   │   └── images/           # Images and icons
│   │
│   └── templates/            # HTML templates
│       ├── components/       # Reusable HTML components
│       │   └── sidebar.html
│       └── pages/            # Page templates
│           ├── dashboard.html
│           ├── login.html
│           ├── users.html
│           ├── attendance.html
│           └── workhours.html
│
├── storage/                  # Data storage
│   ├── data/                 # Application data
│   │   ├── embeddings.json   # Face embeddings
│   │   └── attendance_logs.jsonl # Attendance logs
│   ├── backups/              # Backup files
│   ├── uploads/              # User uploads
│   └── temp/                 # Temporary files
│
├── config/                   # Configuration files
│   └── __init__.py
│
├── utils/                    # Utility modules
│   └── __init__.py
│
└── tests/                    # Test files
    ├── test_api/
    ├── test_services/
    └── test_utils/
```

## 🚀 Features

- **Face Recognition**: DeepFace-based face recognition
- **User Management**: CRUD operations for users
- **Attendance Tracking**: Real-time attendance logging
- **Work Hours Calculation**: Automatic work hours calculation
- **Web Interface**: Modern responsive web UI
- **Backup System**: Automatic backup and restore functionality

## 🛠️ Technology Stack

- **Backend**: FastAPI (Python)
- **Frontend**: HTML5, CSS3, JavaScript (ES6+)
- **UI Framework**: Bootstrap 5
- **Icons**: Font Awesome 6
- **Charts**: Chart.js
- **Face Recognition**: DeepFace (ArcFace model)

## 📦 Installation

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Run the server:
```bash
python main.py
```

3. Access the web interface:
```
http://localhost:8001
```

## 🐳 Docker

```bash
# Build and run
docker build -t face-recognition-server .
docker run -p 8001:8001 face-recognition-server
```

## 🔧 Configuration

Environment variables:
- `SECRET_KEY`: JWT secret key
- `ADMIN_USERNAME`: Admin username (default: admin)
- `ADMIN_PASSWORD`: Admin password (default: admin123)
- `RECOGNITION_THRESHOLD`: Face recognition threshold (default: 0.45)
- `DEEPFACE_MODEL`: DeepFace model (default: ArcFace)

## 📊 API Endpoints

### Authentication
- `POST /login` - User login
- `POST /recognize` - Face recognition

### User Management
- `GET /users` - Get all users
- `POST /register` - Register new user
- `PATCH /users/{user_id}` - Update user
- `DELETE /users/{user_id}` - Delete user

### Attendance
- `GET /attendance/get` - Get attendance logs
- `GET /attendance/work-hours` - Get work hours
- `GET /attendance/work-hours/summary` - Get work hours summary

### Admin
- `POST /admin/cleanup-orphaned-data` - Cleanup orphaned data
- `POST /admin/reset-all-data` - Reset all data

## 🧪 Testing

```bash
# Run tests
python -m pytest tests/
```

## 📝 Development

1. **Adding new API routes**: Add to `api/routes/`
2. **Adding new pages**: Add to `web/templates/pages/`
3. **Adding new components**: Add to `web/templates/components/`
4. **Adding new styles**: Add to `web/static/css/`
5. **Adding new JavaScript**: Add to `web/static/js/`

## 🔒 Security

- JWT-based authentication
- CORS enabled for web interface
- Input validation with Pydantic
- Secure file handling

## 📄 License

MIT License

