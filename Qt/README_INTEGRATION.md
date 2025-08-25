# Qt Face Recognition App Integration

## 🎯 Overview

This Qt application integrates with the face recognition server to provide:
- **Real-time face recognition** in the login screen
- **User registration** with face capture
- **Server configuration** and connection testing
- **Attendance history** synchronization
- **Offline fallback** when server is unavailable

## 🏗️ Architecture

```
Qt App (Client)                    Server API
┌─────────────────┐              ┌─────────────────┐
│ Camera Capture  │              │ FastAPI Server  │
│ Face Detection  │              │ InsightFace     │
│ Image Encoding  │ ──HTTP──→    │ PostgreSQL      │
│ Result Display  │ ←──JSON───   │ pgvector        │
└─────────────────┘              └─────────────────┘
```

## 🚀 Quick Start

### 1. Prerequisites

- **Qt 6.x** installed on your system
- **CMake 3.16+** for building
- **Server running** at `http://127.0.0.1:8001`
- **Camera access** for face capture

### 2. Build the Application

```bash
# Navigate to Qt directory
cd Qt

# Create build directory
mkdir build && cd build

# Configure with CMake
cmake ..

# Build the application
make -j4

# Run the application
./pbl5_facelogin
```

### 3. Configure Server Connection

1. **Open the app** and go to Settings
2. **Navigate to Network Settings**
3. **Configure Server URL**: `http://127.0.0.1:8001`
4. **Test Connection** to verify server is reachable
5. **Save** the configuration

## 📱 Features

### 🔐 Login Screen (Real-time Recognition)

- **Auto-recognition**: Captures and recognizes faces every 3 seconds
- **Manual trigger**: Press 'R' key for immediate recognition
- **Success dialog**: Shows user name and welcome message
- **Failure handling**: Shows retry message for unrecognized faces

### 👤 User Registration

- **Face capture**: High-quality image capture with preview
- **Server registration**: Sends face data to server for processing
- **User management**: Edit user details and manage registrations

### ⚙️ Server Configuration

- **URL configuration**: Set server address and port
- **Connection testing**: Verify server connectivity
- **Status monitoring**: Real-time connection status

### 📊 Attendance History

- **Server sync**: Download attendance logs from server
- **Local storage**: Cache data for offline access
- **Real-time updates**: Sync when connection is restored

## 🔧 Configuration

### Server Settings

The app stores server configuration in local settings:

```cpp
// Default server URL
QString serverUrl = "http://127.0.0.1:8001";

// Device ID (auto-generated from hostname)
QString deviceId = QSysInfo::machineHostName();
```

### Network Settings

- **WiFi configuration**: Connect to local network
- **Server URL**: Configure face recognition server
- **Connection testing**: Verify server accessibility

## 🧪 Testing

### 1. Server Integration Test

Run the integration test script:

```bash
cd Qt
python3 test_integration.py
```

This will test:
- ✅ Server health check
- ✅ User registration
- ✅ Face recognition
- ✅ Attendance history
- ✅ Users list

### 2. Manual Testing

1. **Start the server**:
   ```bash
   docker compose up -d
   ```

2. **Build and run Qt app**:
   ```bash
   cd Qt/build
   cmake .. && make && ./pbl5_facelogin
   ```

3. **Test face recognition**:
   - Go to Login screen
   - Position face in the frame
   - Wait for auto-recognition or press 'R'

4. **Test user registration**:
   - Go to Settings → Admin → Edit User
   - Select a user and capture face
   - Verify registration in server

## 🔍 Debugging

### Enable Debug Logs

The app provides detailed logging for troubleshooting:

```cpp
// Enable debug output
qDebug() << "Server URL:" << m_serverUrl;
qDebug() << "Network status:" << isNetworkAvailable();
qDebug() << "Recognition result:" << result;
```

### Common Issues

1. **Server Connection Failed**
   - Check server is running: `docker compose ps`
   - Verify URL: `http://127.0.0.1:8001`
   - Test with: `curl http://127.0.0.1:8001/health`

2. **Camera Not Working**
   - Check camera permissions
   - Verify camera device is available
   - Test with: `v4l2-ctl --list-devices`

3. **Face Recognition Fails**
   - Check server logs: `docker compose logs api`
   - Verify InsightFace is loaded
   - Test with real face images

## 📁 File Structure

```
Qt/
├── main.cpp                 # Application entry point
├── main.qml                 # Root QML with navigation
├── CMakeLists.txt           # Build configuration
├── src/
│   ├── bridge/
│   │   ├── qmlbridge.h      # QML-C++ bridge interface
│   │   └── qmlbridge.cpp    # Bridge implementation
│   └── services/
│       └── facerecognitionservice.cpp  # Server integration
├── ui/
│   ├── pages/
│   │   ├── Login.qml        # Real-time recognition
│   │   └── NetworkSettings.qml  # Server config
│   └── pages_component/
│       └── CaptureFace.qml  # Face registration
└── test_integration.py      # Integration tests
```

## 🔄 API Integration

### Face Recognition

```cpp
// Send image to server for recognition
QVariantMap result = recognizeFaceWithServer(imageData);

// Handle response
if (result["matched"].toBool()) {
    QString userName = result["name"].toString();
    emit faceRecognized(userId, userName);
} else {
    emit faceRecognitionFailed();
}
```

### User Registration

```cpp
// Register new user with face
bool success = registerFaceWithServer(imageData, name, position);

if (success) {
    emit faceRegistrationSuccess(userId);
} else {
    emit faceRegistrationFailed(error);
}
```

### Server Configuration

```cpp
// Set server URL
setServerUrl("http://192.168.1.100:8001");

// Test connection
bool connected = testServerConnection(url);

// Handle result
emit serverConnectionTested(connected, message);
```

## 🚀 Deployment

### Raspberry Pi Deployment

1. **Cross-compile for Pi**:
   ```bash
   # Set up cross-compilation environment
   export QT_DIR=/path/to/qt/pi
   cmake -DCMAKE_TOOLCHAIN_FILE=pi-toolchain.cmake ..
   ```

2. **Package for deployment**:
   ```bash
   # Create deployment package
   make package
   ```

3. **Install on Pi**:
   ```bash
   # Copy to Pi
   scp pbl5_facelogin.tar.gz pi@raspberrypi.local:~/
   
   # Install on Pi
   ssh pi@raspberrypi.local
   tar -xzf pbl5_facelogin.tar.gz
   cd pbl5_facelogin
   ./pbl5_facelogin
   ```

## 📈 Performance

### Optimization Tips

1. **Image Compression**: Images are compressed to JPEG 80% quality
2. **Async Operations**: All server calls are asynchronous
3. **Caching**: User data is cached locally
4. **Connection Pooling**: HTTP connections are reused

### Expected Performance

- **Recognition latency**: 2-5 seconds
- **Registration time**: 3-8 seconds
- **Image capture**: < 1 second
- **UI responsiveness**: < 100ms

## 🔒 Security

### Data Protection

- **No local storage** of face images
- **Base64 encoding** for transmission
- **HTTPS support** for secure communication
- **Device ID tracking** for audit logs

### Privacy Compliance

- **GDPR compliant** data handling
- **User consent** for face registration
- **Data retention** policies
- **Audit logging** for compliance

## 🆘 Support

### Troubleshooting

1. **Check server status**: `docker compose ps`
2. **View server logs**: `docker compose logs api`
3. **Test API endpoints**: Use `test_integration.py`
4. **Check network**: Verify WiFi connection

### Getting Help

- **Server issues**: Check Docker logs
- **Qt app issues**: Check console output
- **Integration issues**: Run test script
- **Performance issues**: Monitor system resources

## 🎉 Success!

Once everything is working:

1. ✅ **Server is running** and accessible
2. ✅ **Qt app builds** and runs successfully
3. ✅ **Face recognition** works in real-time
4. ✅ **User registration** captures and stores faces
5. ✅ **Attendance tracking** logs recognition events

Your face recognition system is now fully integrated! 🚀


