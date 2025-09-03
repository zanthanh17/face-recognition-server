# 🍓 Raspberry Pi Deployment Guide

## ✅ Đã hoàn thành!

Ứng dụng Face Recognition đã được build và deploy thành công trên Raspberry Pi 3B+ với:
- **Qt6.4.2** - Framework hiện đại
- **OpenCV 4.5.1** - Computer Vision
- **GStreamer** - Multimedia support
- **Auto-start** với systemd service

## 📋 Thông tin hệ thống

- **OS**: Raspberry Pi OS 32-bit (Bookworm)
- **Qt Version**: 6.4.2
- **OpenCV Version**: 4.5.1
- **Memory Usage**: ~120MB
- **Display**: 800x480 (4.3 inch)

## 🚀 Cách chạy ứng dụng

### Chạy thủ công:
```bash
cd /home/pi/app/Qt/build-rpi
QT_QPA_PLATFORM=eglfs ./pbl5_facelogin
```

### Chạy với script:
```bash
cd /home/pi/app/Qt/build-rpi
./run_facelogin.sh
```

### Auto-start (đã cấu hình):
```bash
# Kiểm tra service status
sudo systemctl status facelogin.service

# Restart service
sudo systemctl restart facelogin.service

# Stop service
sudo systemctl stop facelogin.service
```

## 🔧 Troubleshooting

### Nếu ứng dụng không chạy:
1. Kiểm tra dependencies: `ldd pbl5_facelogin`
2. Kiểm tra camera: `v4l2-ctl --list-devices`
3. Kiểm tra logs: `sudo journalctl -u facelogin.service -f`

### Nếu có lỗi display:
```bash
export QT_QPA_PLATFORM=eglfs
export QT_QPA_EGLFS_PHYSICAL_WIDTH=800
export QT_QPA_EGLFS_PHYSICAL_HEIGHT=480
./pbl5_facelogin
```

## 📁 Cấu trúc thư mục

```
/home/pi/app/Qt/
├── build-rpi/
│   ├── pbl5_facelogin          # Executable
│   └── run_facelogin.sh        # Run script
├── src/                        # Source code
├── ui/                         # QML files
└── assets/                     # Resources
```

## 🎯 Tính năng chính

- ✅ Face Recognition với camera
- ✅ User Management
- ✅ Attendance History
- ✅ System Monitoring
- ✅ Network Management
- ✅ Auto-start on boot
- ✅ Optimized for RPi 3B+

## 🔄 Cập nhật ứng dụng

1. Copy source code mới
2. Build lại: `cd build-rpi && make -j$(nproc)`
3. Restart service: `sudo systemctl restart facelogin.service`

## 📊 Performance

- **Startup Time**: ~5-10 seconds
- **Memory Usage**: ~120MB
- **CPU Usage**: Low (optimized)
- **Camera**: USB camera supported

## 🎉 Kết luận

Ứng dụng đã sẵn sàng sử dụng trên Raspberry Pi 3B+ với đầy đủ tính năng!

