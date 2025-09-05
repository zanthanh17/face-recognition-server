# Camera Setup for Qt Face Recognition App on Raspberry Pi OS

## Overview
This guide explains how to set up and use the camera integration in the Qt face recognition application on Raspberry Pi OS.

## Prerequisites
- Raspberry Pi OS (Bullseye or newer)
- Raspberry Pi Camera Module (connected and enabled)
- Display connected (not running headless)
- Qt 6 development environment

## Installation

### 1. Install Dependencies
Run the installation script to install all required packages:

```bash
cd Qt
chmod +x install_dependencies.sh
./install_dependencies.sh
```

This script will install:
- `rpicam-apps` - New camera stack for Raspberry Pi
- `raspistill` - Legacy camera tool (fallback)
- Qt 6 development packages
- OpenCV for face recognition
- Build tools

### 2. Verify Camera Installation
Check if camera tools are available:

```bash
# Check rpicam-hello
which rpicam-hello

# Check rpicam-still
which rpicam-still

# Check raspistill
which raspistill

# List available cameras
rpicam-hello --list-cameras
```

### 3. Test Camera Manually
Test the camera with the same command used in the app:

```bash
# Test camera preview (will show camera feed)
DISPLAY=:0 rpicam-hello -t 0

# Test still capture
rpicam-still -o test.jpg -t 1000

# Test legacy camera
raspistill -o test2.jpg -t 1000
```

## Building the Application

### 1. Create Build Directory
```bash
cd Qt
mkdir build
cd build
```

### 2. Configure with CMake
```bash
cmake ..
```

### 3. Build the Application
```bash
make -j4
```

## Usage

### 1. Running the Application
```bash
# From build directory
./pbl5_facelogin

# Or with specific display
DISPLAY=:0 ./pbl5_facelogin
```

### 2. Camera Controls in the App
The application provides several camera control buttons:

- **Start Preview**: Starts camera preview using `rpicam-hello`
- **Stop Preview**: Stops camera preview
- **Set Display :0**: Sets the display to `:0` (main display)
- **Capture & Recognize**: Captures an image and attempts face recognition

### 3. Automatic Camera Initialization
The app automatically:
- Sets display to `:0` on startup
- Starts camera service
- Attempts to start camera preview after 1 second

## Camera Integration Details

### Architecture
The camera integration uses a layered approach:

1. **QmlBridge**: Exposes camera functions to QML
2. **CameraManager**: Manages camera operations and processes
3. **rpicam-hello**: Provides live camera preview (when Qt Process module available)
4. **rpicam-still**: Handles still image capture
5. **Fallback Support**: Uses alternative methods when Qt Process module unavailable

### Process Management
- Camera preview runs as a separate `rpicam-hello` process (when available)
- Process environment includes `DISPLAY=:0`
- Automatic cleanup when preview is stopped
- Error handling for process failures
- Fallback to still capture only when process support unavailable

### Fallback Support
If `rpicam-hello` is not available, the app falls back to:
1. `rpicam-still` for image capture
2. `raspistill` as final fallback

If Qt Process module is not available:
1. Camera preview shows "not available" message
2. Still image capture works normally
3. Face recognition functionality unaffected

## Troubleshooting

### Common Issues

#### 1. Camera Not Available
```bash
# Check if camera is enabled
sudo raspi-config

# Check camera module connection
vcgencmd get_camera

# Check device permissions
ls -la /dev/video*
```

#### 2. Display Issues
```bash
# Check display
echo $DISPLAY

# Set display manually
export DISPLAY=:0

# Check X server
xset q
```

#### 3. Permission Issues
```bash
# Add user to video group
sudo usermod -a -G video $USER

# Check group membership
groups $USER
```

#### 4. Build Errors
```bash
# Install missing Qt modules
sudo apt install qt6-process-dev

# If Qt6 Process module is not available, the app will still build
# but camera preview will use fallback methods
# Check if module is available:
pkg-config --exists Qt6Process

# Clean and rebuild
cd build
make clean
cmake ..
make
```

#### 5. Qt6 Process Module Not Available
If you see the message "Qt6 Process module not available - camera preview will use fallback methods":

- This is normal on some Raspberry Pi OS versions
- The app will still build and run
- Camera capture will work using `rpicam-still` or `raspistill`
- Camera preview will show a message that preview is not available
- Face recognition functionality will work normally

To check Qt6 Process module availability:
```bash
pkg-config --exists Qt6Process
echo $?  # 0 = available, 1 = not available
```

### Debug Information
The application provides debug output for camera operations:

```bash
# Run with debug output
QT_LOGGING_RULES="qt.qpa.*=true" ./pbl5_facelogin
```

## Performance Considerations

### Camera Resolution
- Preview: 640x480 (optimized for performance)
- Capture: 640x480 (balanced quality/speed)
- Adjustable in `CameraManager::startPreview()`

### Process Management
- Preview process runs continuously
- Automatic cleanup on app exit
- Memory-efficient image capture

## Security Notes

- Camera access requires appropriate permissions
- Display access needed for preview functionality
- Process isolation for camera operations

## Future Enhancements

- Support for multiple camera modules
- Configurable camera parameters
- Advanced image processing
- Network camera support

## Support

For issues related to:
- **Camera hardware**: Check Raspberry Pi documentation
- **rpicam-apps**: Check libcamera documentation
- **Qt integration**: Check application logs and debug output
- **Build issues**: Verify Qt installation and dependencies
