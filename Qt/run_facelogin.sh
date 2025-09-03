#!/bin/bash

# Run Qt app on Raspberry Pi with portrait mode (480x800)
# This script sets up the correct environment for EGLFS display

echo "Starting FaceLogin app in portrait mode (480x800)..."

# Set display environment for RPi
export QT_QPA_PLATFORM=eglfs
export QT_QPA_EGLFS_PHYSICAL_WIDTH=480
export QT_QPA_EGLFS_PHYSICAL_HEIGHT=800
export QT_QPA_EGLFS_ROTATION=90
export QT_LOGGING_RULES="qt.qpa.*=false"
export QT_QUICK_BACKEND=software

# Disable debug logs for better performance
export QT_LOGGING_RULES="*.debug=false;qt.qpa.*=false"

# Run the application
cd "$(dirname "$0")/build"
./pbl5_facelogin

echo "Application stopped."
