# FaceLog - Hệ thống Face Recognition & Quản lý Attendance

Hệ thống nhận diện khuôn mặt và quản lý chấm công hoàn chỉnh với giao diện web chuyên nghiệp và ứng dụng Qt.

## 🚀 Tổng quan

FaceLog là một hệ thống hoàn chỉnh bao gồm:
- **Server**: FastAPI backend với face recognition
- **Web Interface**: Giao diện quản trị chuyên nghiệp
- **Qt App**: Ứng dụng desktop cho face recognition
- **Database**: PostgreSQL với vector embeddings
hơw to detect recognation from client to server???
opencv + deepface -> client - server -> postresql database 

## 📋 Tính năng chính

### 🔐 Face Recognition
- Nhận diện khuôn mặt real-time
- Đăng ký user với ảnh khuôn mặt
- Lưu trữ embeddings trong database
- So sánh độ chính xác cao

### 👥 User Management
- Đăng ký user mới
- Chỉnh sửa thông tin user
- Upload và quản lý ảnh khuôn mặt
- Xóa user khỏi hệ thống

### 📊 Attendance Tracking
- Ghi lại mọi lần quét khuôn mặt
- Phân biệt check-in/check-out
- Tính toán giờ làm việc tự động
- Lịch sử chi tiết theo thời gian

### 📈 Analytics & Reports
- Dashboard với thống kê tổng quan
- Biểu đồ hoạt động theo thời gian
- Báo cáo giờ làm việc
- Export dữ liệu CSV

## 🏗️ Kiến trúc hệ thống

```
FaceLog System
├── Server (FastAPI)
│   ├── Face Recognition Engine
│   ├── Database Management
│   ├── REST API Endpoints
│   └── Web Interface
├── Qt Application
│   ├── Camera Interface
│   ├── Face Detection
│   └── Server Communication
└── Database (PostgreSQL)
    ├── User Profiles
    ├── Face Embeddings
    └── Attendance Logs
```

## 🛠️ Công nghệ sử dụng

### Backend
- **Python 3.9+**
- **FastAPI** - Web framework
- **PostgreSQL** - Database
- **pgvector** - Vector similarity search
- **OpenCV** - Image processing
- **InsightFace** - Face recognition
- **Docker** - Containerization

### Frontend
- **HTML5/CSS3/JavaScript**
- **Bootstrap 5** - UI framework
- **Chart.js** - Data visualization
- **Font Awesome** - Icons

### Desktop App
- **Qt 6** - Cross-platform framework
- **QML** - UI markup language
- **C++** - Backend logic

## 📁 Cấu trúc dự án

```
face-recognition-server/
├── server/                 # Backend server
│   ├── main.py            # FastAPI application
│   ├── web/               # Web interface
│   │   ├── index.html     # Dashboard
│   │   ├── users.html     # User management
│   │   ├── attendance.html # History In/Out
│   │   ├── workhours.html # Work hours
│   │   ├── css/           # Styles
│   │   ├── js/            # JavaScript
│   │   └── README.md      # Web docs
│   ├── admin/             # Legacy admin interface
│   └── storage/           # Data storage
├── Qt/                    # Desktop application
│   ├── src/               # C++ source code
│   ├── ui/                # QML UI files
│   └── scripts/           # Python scripts
├── docker-compose.yml     # Docker configuration
└── README.md              # This file
```

## 🚀 Cài đặt và chạy

### Yêu cầu hệ thống
- Docker & Docker Compose
- Python 3.9+
- Qt 6 (cho desktop app)

### Quick Start

1. **Clone repository**
```bash
git clone <repository-url>
cd face-recognition-server
```

2. **Chạy với Docker**
```bash
docker-compose up --build
```

3. **Truy cập web interface**
```
http://localhost:8001/web/
```

4. **Chạy Qt app**
```bash
cd Qt
python scripts/system_monitor.py
```

## 📖 Hướng dẫn sử dụng

### Web Interface

#### Dashboard
- Xem thống kê tổng quan
- Biểu đồ hoạt động
- Danh sách hoạt động gần đây

#### Quản lý Users
- Thêm/sửa/xóa users
- Upload ảnh khuôn mặt
- Tìm kiếm và lọc users

#### History In/Out
- Xem lịch sử quét khuôn mặt
- Bộ lọc theo ngày, trạng thái, user
- Export dữ liệu CSV

#### Chấm công
- Tính giờ làm việc tự động
- Xem theo ngày hoặc tổng hợp
- Báo cáo chi tiết

### Qt Application

#### Đăng ký User
1. Chụp ảnh khuôn mặt
2. Nhập thông tin user
3. Gửi lên server

#### Nhận diện
1. Chụp ảnh real-time
2. So sánh với database
3. Hiển thị kết quả

## 🔌 API Endpoints

### Authentication
- `POST /register` - Đăng ký user
- `POST /recognize` - Nhận diện khuôn mặt

### User Management
- `GET /api/users` - Lấy danh sách users
- `PATCH /users/{user_id}` - Cập nhật user
- `DELETE /users/{user_id}` - Xóa user
- `GET /users/{user_id}/image` - Lấy ảnh user

### Attendance
- `GET /attendance/get` - Lấy lịch sử
- `GET /attendance/work-hours` - Tính giờ làm
- `GET /attendance/work-hours/summary` - Tổng hợp

### Statistics
- `GET /api/stats` - Thống kê tổng quan
- `GET /api/logs` - Logs gần đây

## 📊 Database Schema

### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    position VARCHAR(255),
    image_base64 TEXT,
    embedding VECTOR(512)
);
```

### Attendance Logs Table
```sql
CREATE TABLE attendance_logs (
    id SERIAL PRIMARY KEY,
    user_id UUID,
    ts BIGINT,
    matched BOOLEAN,
    distance FLOAT,
    timestamp TIMESTAMP
);
```

## 🔧 Cấu hình

### Environment Variables
```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost/face_log

# Server
HOST=0.0.0.0
PORT=8001

# Face Recognition
FACE_RECOGNITION_THRESHOLD=0.6
```

### Docker Configuration
```yaml
services:
  facelog-api:
    build: .
    ports:
      - "8001:8001"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db/face_log
    depends_on:
      - db
  
  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=face_log
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
```

## 🐛 Troubleshooting

### Lỗi thường gặp

1. **Face recognition không hoạt động**
   - Kiểm tra camera permissions
   - Kiểm tra model files có đầy đủ không

2. **Database connection error**
   - Kiểm tra PostgreSQL service
   - Kiểm tra connection string

3. **Web interface không load**
   - Kiểm tra Docker container
   - Kiểm tra port 8001

### Debug Commands
```bash
# Check container status
docker ps

# View logs
docker logs facelog-api

# Access container
docker exec -it facelog-api bash

# Test API
curl http://localhost:8001/api/stats
```

## 📈 Performance

### Benchmarks
- **Face Recognition**: ~200ms per image
- **Database Query**: ~50ms average
- **Web Interface**: <2s load time
- **Concurrent Users**: 10+ simultaneous

### Optimization Tips
- Use SSD storage for database
- Enable database indexing
- Optimize image sizes
- Use connection pooling

## 🔒 Security

### Authentication
- API key authentication
- Rate limiting
- Input validation
- SQL injection prevention

### Data Protection
- Encrypted database connections
- Secure file uploads
- Privacy-compliant data handling

## 📝 Changelog

### Version 1.0.0 (Current)
- ✅ Face recognition engine
- ✅ Web interface với 4 trang chính
- ✅ Qt desktop application
- ✅ PostgreSQL database
- ✅ Docker deployment
- ✅ API documentation
- ✅ Export functionality

### Planned Features
- 🔄 Real-time notifications
- 🔄 Mobile app
- 🔄 Advanced analytics
- 🔄 Multi-language support

## 🤝 Đóng góp

1. Fork repository
2. Tạo feature branch
3. Commit changes
4. Push to branch
5. Tạo Pull Request

## 📄 License

MIT License - xem file LICENSE để biết thêm chi tiết.

## 📞 Support

- **Email**: support@facelog.com
- **Documentation**: `/server/web/README.md`
- **Issues**: GitHub Issues

---

**FaceLog** - Hệ thống Face Recognition & Quản lý Attendance chuyên nghiệp

