# Render Deployment Guide

## Tổng quan
Hướng dẫn deploy Face Recognition Server lên Render.com

## Files đã tạo/sửa đổi

### 1. `render.yaml`
- Cấu hình service cho Render
- Web service cho API
- PostgreSQL service cho database

### 2. `server/requirements-render.txt`
- Requirements tối ưu cho Render
- Sử dụng `opencv-python-headless` thay vì `opencv-python`
- Thêm `gunicorn` cho production

### 3. `scripts/start_server.py`
- Sửa để tương thích với Render
- Host mặc định: `0.0.0.0`
- Port từ environment variable

## Các bước deploy

### Bước 1: Chuẩn bị repository
```bash
# Commit các thay đổi
git add .
git commit -m "Add Render deployment configuration"
git push origin main
```

### Bước 2: Tạo Render account
1. Truy cập [render.com](https://render.com)
2. Đăng ký/đăng nhập
3. Connect GitHub account

### Bước 3: Deploy từ GitHub
1. **New + Web Service**
2. **Connect GitHub repository**
3. **Chọn repository:** face-recognition-server
4. **Cấu hình:**
   - **Name:** face-recognition-api
   - **Environment:** Python 3
   - **Region:** Singapore (gần Việt Nam)
   - **Branch:** main
   - **Root Directory:** (để trống)
   - **Build Command:** `pip install --upgrade pip && pip install -r server/requirements-render.txt`
   - **Start Command:** `python scripts/start_server.py`

### Bước 4: Environment Variables
```
HOST=0.0.0.0
PORT=8000
RECOGNITION_THRESHOLD=0.45
DEEPFACE_MODEL=ArcFace
CORS_ALLOWED_ORIGINS=*
PYTHON_VERSION=3.12.0
```

### Bước 5: Tạo PostgreSQL Database
1. **New + PostgreSQL**
2. **Name:** face-recognition-db
3. **Region:** Singapore
4. **Plan:** Starter ($7/tháng)
5. **Database:** face
6. **User:** postgres

### Bước 6: Kết nối Database
1. Copy **External Database URL** từ PostgreSQL service
2. Thêm vào Web Service environment variables:
```
DATABASE_URL=postgresql://user:password@host:port/database
```

## Ước tính chi phí

### Web Service
- **Starter:** $7/tháng (512MB RAM) - Có thể không đủ
- **Standard:** $25/tháng (1GB RAM) - **Khuyến nghị**
- **Pro:** $85/tháng (2GB RAM) - Nếu cần performance cao

### PostgreSQL
- **Starter:** $7/tháng (1GB storage)
- **Standard:** $20/tháng (10GB storage)

**Tổng chi phí khuyến nghị:** $32/tháng (Standard Web + Starter DB)

## Lưu ý quan trọng

### 1. Build Time
- DeepFace dependencies nặng
- Build time: 5-10 phút
- Có thể timeout nếu plan quá nhỏ

### 2. Memory Usage
- DeepFace cần ít nhất 1GB RAM
- Khuyến nghị dùng Standard plan ($25/tháng)

### 3. Storage
- Render có ephemeral filesystem
- Data sẽ mất khi restart
- Cần migrate sang PostgreSQL

### 4. CORS
- Đã cấu hình `CORS_ALLOWED_ORIGINS=*`
- Có thể restrict sau khi deploy

## Test sau khi deploy

### 1. Health Check
```bash
curl https://your-app.onrender.com/health
```

### 2. API Test
```bash
curl -X POST https://your-app.onrender.com/recognize \
  -H "Content-Type: application/json" \
  -d '{"image_base64": "base64_encoded_image"}'
```

### 3. Web Interface
Truy cập: `https://your-app.onrender.com/web/`

## Troubleshooting

### Build Failed
- Kiểm tra requirements-render.txt
- Tăng plan lên Standard
- Kiểm tra logs trong Render dashboard

### Out of Memory
- Upgrade lên plan cao hơn
- Optimize DeepFace model loading

### Database Connection
- Kiểm tra DATABASE_URL
- Đảm bảo PostgreSQL service đang chạy

## Next Steps

1. **Deploy lên Render**
2. **Test API endpoints**
3. **Update Qt app** để sử dụng Render URL
4. **Monitor performance**
5. **Scale nếu cần**

## Support

Nếu gặp vấn đề:
1. Kiểm tra Render logs
2. Test local với `render.yaml`
3. Liên hệ support Render
