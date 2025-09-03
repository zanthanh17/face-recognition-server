#!/bin/bash

# Build script optimized for Raspberry Pi 3B+
# This script includes compiler optimizations for ARM architecture

echo "Building Qt app for Raspberry Pi 3B+ with optimizations..."

# Create build directory
mkdir -p build
cd build

# Configure with RPi optimizations
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-O2 -march=armv8-a -mtune=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard" \
    -DCMAKE_C_FLAGS="-O2 -march=armv8-a -mtune=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard" \
    -DQT_QMAKE_TARGET_MKSPEC=linux-rasp-pi4-v3d-g++ \
    -DCMAKE_PREFIX_PATH=/usr/lib/qt6 \
    -DCMAKE_INSTALL_PREFIX=/usr/local

# Build with multiple cores (adjust based on your RPi)
make -j4

echo "Build completed for Raspberry Pi 3B+"
echo "Optimizations applied:"
echo "- ARM NEON optimizations enabled"
echo "- Cortex-A53 tuning"
echo "- Release build with -O2 optimization"
echo "- Hardware floating point"
