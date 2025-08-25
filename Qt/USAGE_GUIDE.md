# Hướng dẫn sử dụng hệ thống Face Recognition

## 🎯 **Mục đích của hệ thống**

Hệ thống này được thiết kế để:
- **Server**: Quản lý và đăng ký users thông qua web admin interface
- **Qt App**: Chỉ thực hiện face recognition để tracking attendance

## 📋 **Quy trình sử dụng**

### **1. Đăng ký Users trên Server**

#### **Cách 1: Web Admin Interface**
1. Mở trình duyệt và truy cập: `http://localhost:8088/admin`
2. Đăng ký users mới với thông tin:
   - Tên
   - Vị trí/Department
   - Ảnh khuôn mặt
3. Users sẽ được lưu vào database với face embeddings

#### **Cách 2: API trực tiếp**
```bash
# Test với real image
cd Qt
python3 test_with_real_image.py
```

### **2. Sử dụng Qt App cho Face Recognition**

#### **Khởi động ứng dụng**
```bash
cd Qt/build
./pbl5_facelogin
```

#### **Cấu hình Server**
1. Mở ứng dụng Qt
2. Vào **Settings** → **Network Settings**
3. Nhập **Server URL**: `http://127.0.0.1:8001`
4. Test connection và Save

#### **Face Recognition**
1. **Login Screen**: 
   - Camera tự động bật
   - Auto-recognition mỗi 3 giây
   - Hoặc nhấn phím **'R'** để recognition ngay
   
2. **Kết quả Recognition**:
   - ✅ **Success**: Hiển thị tên user và chào mừng
   - ❌ **Failed**: Hiển thị "Unknown" và yêu cầu thử lại

## 🔧 **Cấu hình hệ thống**

### **Server Configuration**
```bash
# Khởi động server
cd ..
docker compose up -d

# Kiểm tra status
docker compose ps

# Xem logs
docker compose logs api
```

### **Database**
- **PostgreSQL** với extension `pgvector`
- Lưu trữ user info và face embeddings
- Attendance logs với timestamp

### **API Endpoints**
- `GET /health` - Kiểm tra server status
- `POST /recognize` - Face recognition
- `POST /register` - User registration
- `GET /users` - Danh sách users
- `GET /attendance` - Lịch sử attendance

## 🧪 **Testing**

### **Test Server Integration**
```bash
cd Qt
python3 test_integration.py
python3 test_with_real_image.py
```

### **Test Qt App**
1. **Auto Recognition**: Đợi 3 giây để test
2. **Manual Recognition**: Nhấn phím 'R'
3. **Test Dialogs**: Nhấn 'S' (Success) hoặc 'F' (Failed)

## 📊 **Monitoring**

### **Grafana Dashboard**
- Truy cập: `http://localhost:3000`
- Username: `admin`
- Password: `admin`
- Xem metrics và performance

### **Prometheus**
- Truy cập: `http://localhost:9090`
- Xem raw metrics

## 🚨 **Troubleshooting**

### **Server không khởi động**
```bash
# Kiểm tra logs
docker compose logs api

# Restart services
docker compose restart
```

### **Qt App không kết nối server**
1. Kiểm tra server URL trong Network Settings
2. Test connection
3. Kiểm tra firewall/network

### **Camera không hoạt động**
1. Kiểm tra camera permissions
2. Restart ứng dụng
3. Kiểm tra camera device

## 📝 **Lưu ý quan trọng**

1. **User Registration**: Chỉ thực hiện trên server, không phải Qt app
2. **Face Recognition**: Chỉ thực hiện trên Qt app
3. **Database**: Tự động backup hàng ngày
4. **Security**: JWT authentication đã được disable cho đơn giản

## 🎉 **Kết quả mong đợi**

- ✅ Server chạy ổn định với web admin
- ✅ Qt app nhận diện khuôn mặt real-time
- ✅ Attendance được log tự động
- ✅ Performance monitoring hoạt động
- ✅ Database backup tự động

---

**Hệ thống đã sẵn sàng sử dụng!** 🚀


