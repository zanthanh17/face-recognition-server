#!/bin/bash

# Script to install camera dependencies for Qt face recognition app on Raspberry Pi OS
# This script installs rpicam-apps and other required packages

echo "Installing camera dependencies for Qt face recognition app..."

# Update package list
sudo apt update

# Install rpicam-apps (new camera stack for Raspberry Pi)
echo "Installing rpicam-apps..."
sudo apt install -y rpicam-apps

# Install additional camera tools (fallbacks)
echo "Installing additional camera tools..."
sudo apt install -y raspistill raspivid

# Install Qt development dependencies
echo "Installing Qt development dependencies..."
sudo apt install -y qt6-base-dev qt6-declarative-dev qt6-multimedia-dev qt6-quickcontrols2-dev qt6-qml-dev

# Try to install Qt6 Process module (may not be available on all systems)
echo "Installing Qt6 Process module..."
if sudo apt install -y qt6-process-dev 2>/dev/null; then
    echo "✓ Qt6 Process module installed successfully"
else
    echo "⚠ Qt6 Process module not available - camera preview will use fallback methods"
    echo "  This is normal on some Raspberry Pi OS versions"
fi

# Install build tools
echo "Installing build tools..."
sudo apt install -y cmake build-essential

# Install OpenCV (optional, for face recognition)
echo "Installing OpenCV..."
sudo apt install -y python3-opencv libopencv-dev

# Install additional system dependencies
echo "Installing system dependencies..."
sudo apt install -y libcamera-tools v4l-utils

# Check if camera is accessible
echo "Checking camera accessibility..."
if command -v rpicam-hello &> /dev/null; then
    echo "✓ rpicam-hello is available"
else
    echo "✗ rpicam-hello not found"
fi

if command -v rpicam-still &> /dev/null; then
    echo "✓ rpicam-still is available"
else
    echo "✗ rpicam-still not found"
fi

if command -v raspistill &> /dev/null; then
    echo "✓ raspistill is available"
else
    echo "✗ raspistill not found"
fi

# Check Qt6 Process module
echo "Checking Qt6 Process module..."
if pkg-config --exists Qt6Process 2>/dev/null; then
    echo "✓ Qt6 Process module is available"
elif dpkg -l | grep -q qt6-process-dev; then
    echo "✓ Qt6 Process module is installed"
else
    echo "⚠ Qt6 Process module not available - camera preview will use fallback methods"
fi

# Check camera device
echo "Checking camera devices..."
ls -la /dev/video* 2>/dev/null || echo "No video devices found"

# Test camera with rpicam-hello
echo "Testing camera with rpicam-hello..."
if command -v rpicam-hello &> /dev/null; then
    echo "Running rpicam-hello test (will show camera info)..."
    timeout 5 rpicam-hello --list-cameras || echo "Camera test failed"
else
    echo "rpicam-hello not available for testing"
fi

echo ""
echo "Installation completed!"
echo ""
echo "To test the camera manually, run:"
echo "  DISPLAY=:0 rpicam-hello -t 0"
echo ""
echo "To build the Qt app, run:"
echo "  mkdir build && cd build"
echo "  cmake .."
echo "  make"
echo ""
echo "Note: Make sure you're running on a display (not headless) for camera preview to work."
