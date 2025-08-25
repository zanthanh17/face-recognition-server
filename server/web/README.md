# FaceLog Web Interface

Giao diện web chuyên nghiệp cho hệ thống FaceLog, cung cấp các tính năng quản lý user, theo dõi attendance và chấm công.

## 🚀 Tính năng chính

### 1. Dashboard (Trang chủ)
- **Thống kê tổng quan**: Số lượng users, logs, giờ làm việc
- **Biểu đồ hoạt động**: Chart hiển thị hoạt động theo thời gian
- **Danh sách hoạt động gần đây**: Các sự kiện quét khuôn mặt mới nhất

### 2. Quản lý Users
- **Danh sách users**: Hiển thị tất cả users đã đăng ký
- **Thêm user mới**: Upload ảnh và thông tin user
- **Chỉnh sửa user**: Cập nhật thông tin và ảnh
- **Xóa user**: Xóa user khỏi hệ thống với tùy chọn backup
- **Tìm kiếm và lọc**: Tìm kiếm user theo tên hoặc ID

### 3. History In/Out
- **Lịch sử quét khuôn mặt**: Tất cả các lần quét khuôn mặt
- **Bộ lọc nâng cao**: 
  - Theo ngày (từ ngày - đến ngày)
  - Theo trạng thái (thành công/thất bại)
  - Theo user
- **Thống kê trực quan**:
  - Tổng số logs
  - Số lần thành công/thất bại
  - Số users tham gia
- **Biểu đồ phân tích**:
  - Pie chart: Tỷ lệ thành công/thất bại
  - Bar chart: Hoạt động theo giờ
- **Export dữ liệu**: Xuất ra file CSV

### 4. Chấm công
- **Tính giờ làm việc**: Tự động tính giờ làm dựa trên check-in đầu và check-out cuối
- **Hai chế độ xem**:
  - **Xem theo ngày**: Chi tiết giờ làm của từng user trong một ngày
  - **Xem tổng hợp**: Tổng hợp giờ làm trong khoảng thời gian
- **Thống kê**:
  - Tổng số workers
  - Tổng giờ làm việc
  - Workers hoạt động hôm nay
  - Trung bình giờ làm/người
- **Biểu đồ phân tích**:
  - Bar chart: Giờ làm theo user
  - Line chart: Xu hướng giờ làm theo thời gian
- **Export báo cáo**: Xuất dữ liệu ra CSV

### 5. Quản lý Backups 🆕
- **Backup tự động**: Tự động tạo backup khi xóa user
- **Khôi phục user**: Khôi phục user và attendance logs từ backup
- **Quản lý backup files**: Xem danh sách và chi tiết các backup
- **Thống kê backup**: Số lượng backups, users đã xóa, logs được backup
- **An toàn dữ liệu**: Đảm bảo không mất dữ liệu khi xóa user

## 🛠️ Công nghệ sử dụng

- **Frontend**: HTML5, CSS3, JavaScript (ES6+)
- **UI Framework**: Bootstrap 5
- **Icons**: Font Awesome 6
- **Charts**: Chart.js
- **Backend API**: FastAPI (Python)

## 📁 Cấu trúc thư mục

```
server/web/
├── index.html          # Dashboard chính
├── users.html          # Quản lý users
├── attendance.html     # History In/Out
├── workhours.html      # Chấm công
├── backups.html        # Quản lý backups 🆕
├── css/
│   └── style.css       # Custom styles
├── js/
│   ├── app.js          # Main app logic
│   ├── users.js        # User management
│   ├── attendance.js   # Attendance tracking
│   ├── workhours.js    # Work hours calculation
│   └── backups.js      # Backup management 🆕
└── README.md           # Documentation này
```

## 🔌 API Endpoints

### Users Management
- `GET /api/users` - Lấy danh sách users
- `POST /register` - Đăng ký user mới
- `PATCH /users/{user_id}` - Cập nhật thông tin user
- `DELETE /users/{user_id}` - Xóa user (với tùy chọn backup)
- `GET /users/{user_id}/image` - Lấy ảnh user

### Attendance Tracking
- `GET /attendance/get` - Lấy lịch sử attendance
- `GET /attendance/work-hours` - Tính giờ làm theo ngày
- `GET /attendance/work-hours/summary` - Tổng hợp giờ làm

### Backup Management 🆕
- `GET /backups` - Lấy danh sách backups
- `POST /backups/{filename}/restore` - Khôi phục user từ backup
- `GET /backups/{filename}/details` - Xem chi tiết backup

### Statistics
- `GET /api/stats` - Thống kê tổng quan
- `GET /api/logs` - Logs gần đây

## 🎨 Giao diện

### Responsive Design
- Tương thích với desktop, tablet và mobile
- Navigation menu có thể thu gọn trên mobile
- Tables có scroll horizontal trên màn hình nhỏ

### Color Scheme
- **Primary**: Blue (#0d6efd) - Navigation, buttons
- **Success**: Green (#198754) - Success states
- **Warning**: Yellow (#ffc107) - Warning states  
- **Danger**: Red (#dc3545) - Error states
- **Info**: Cyan (#0dcaf0) - Information

### Components
- **Cards**: Hiển thị thống kê và thông tin
- **Tables**: Danh sách dữ liệu với pagination
- **Charts**: Biểu đồ trực quan
- **Forms**: Input fields với validation
- **Modals**: Popup dialogs
- **Notifications**: Toast messages

## 📊 Tính năng nâng cao

### Real-time Updates
- Auto-refresh data mỗi 30 giây
- Loading indicators
- Error handling với retry

### Data Export
- Export CSV cho attendance logs
- Export CSV cho work hours reports
- Tự động đặt tên file theo ngày

### Search & Filter
- Tìm kiếm theo tên user
- Lọc theo ngày
- Lọc theo trạng thái
- Lọc theo user

### Charts & Analytics
- **Pie Chart**: Phân bố trạng thái
- **Bar Chart**: Hoạt động theo giờ/user
- **Line Chart**: Xu hướng theo thời gian
- **Responsive charts**: Tự động điều chỉnh kích thước

### Backup & Recovery 🆕
- **Automatic Backup**: Tự động tạo backup khi xóa user
- **Complete Restoration**: Khôi phục user và tất cả attendance logs
- **Backup Management**: Quản lý và xem chi tiết các backup files
- **Data Safety**: Đảm bảo không mất dữ liệu quan trọng

## 🚀 Cách sử dụng

### Truy cập
1. Mở trình duyệt web
2. Truy cập: `http://localhost:8001/web/`
3. Sử dụng navigation menu để chuyển đổi giữa các trang

### Quản lý Users
1. Vào trang "Quản lý Users"
2. Xem danh sách users hiện tại
3. Thêm user mới bằng nút "Thêm User"
4. Chỉnh sửa thông tin user bằng nút "Sửa"
5. Xóa user bằng nút "Xóa" (có tùy chọn backup)

### Xem History In/Out
1. Vào trang "History In/Out"
2. Sử dụng bộ lọc để tìm kiếm
3. Xem thống kê và biểu đồ
4. Export dữ liệu nếu cần

### Xem Chấm công
1. Vào trang "Chấm công"
2. Chọn chế độ xem (theo ngày/tổng hợp)
3. Chọn ngày hoặc khoảng thời gian
4. Xem báo cáo giờ làm việc
5. Export báo cáo nếu cần

### Quản lý Backups 🆕
1. Vào trang "Backups"
2. Xem danh sách các backup đã tạo
3. Khôi phục user bằng nút "Khôi phục"
4. Xem chi tiết backup bằng nút "Chi tiết"
5. Theo dõi thống kê backup

## 🔧 Cấu hình

### Environment Variables
- `PORT`: Port của server (mặc định: 8001)
- `HOST`: Host của server (mặc định: 0.0.0.0)

### Docker
```bash
# Build và chạy
docker-compose up --build

# Chỉ chạy
docker-compose up

# Dừng
docker-compose down
```

## 🐛 Troubleshooting

### Lỗi thường gặp

1. **Không kết nối được server**
   - Kiểm tra Docker container có đang chạy không
   - Kiểm tra port 8001 có bị block không

2. **Không load được dữ liệu**
   - Kiểm tra API endpoints có hoạt động không
   - Kiểm tra console browser có lỗi JavaScript không

3. **Charts không hiển thị**
   - Kiểm tra Chart.js có load thành công không
   - Kiểm tra dữ liệu có đúng format không

4. **Backup không tạo được** 🆕
   - Kiểm tra quyền ghi vào thư mục storage
   - Kiểm tra dung lượng ổ đĩa
   - Kiểm tra logs server

### Debug
- Mở Developer Tools (F12)
- Xem tab Console để kiểm tra lỗi JavaScript
- Xem tab Network để kiểm tra API calls

## 📝 Changelog

### Version 1.1.0 🆕
- ✅ Tính năng backup và khôi phục user
- ✅ Trang quản lý backups
- ✅ Tự động backup khi xóa user
- ✅ Khôi phục user và attendance logs
- ✅ Thống kê backup

### Version 1.0.0
- ✅ Dashboard với thống kê tổng quan
- ✅ Quản lý users (CRUD)
- ✅ History In/Out với filters và charts
- ✅ Chấm công với tính giờ tự động
- ✅ Export dữ liệu CSV
- ✅ Responsive design
- ✅ Real-time updates

## 🤝 Đóng góp

Để đóng góp vào dự án:
1. Fork repository
2. Tạo feature branch
3. Commit changes
4. Push to branch
5. Tạo Pull Request

## 📄 License

MIT License - xem file LICENSE để biết thêm chi tiết.

