#!/bin/bash

# Qt Face Recognition App Build Script
# This script builds the Qt application with proper configuration

set -e  # Exit on any error

echo "🚀 Building Qt Face Recognition App"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "CMakeLists.txt" ]; then
    echo "❌ Error: CMakeLists.txt not found. Please run this script from the Qt directory."
    exit 1
fi

# Check Qt installation
echo "🔍 Checking Qt installation..."
if ! command -v qmake &> /dev/null; then
    echo "❌ Error: Qt not found. Please install Qt 6.x"
    echo "   Ubuntu/Debian: sudo apt install qt6-base-dev"
    echo "   macOS: brew install qt6"
    echo "   Windows: Download from https://www.qt.io/download"
    exit 1
fi

# Check CMake
echo "🔍 Checking CMake..."
if ! command -v cmake &> /dev/null; then
    echo "❌ Error: CMake not found. Please install CMake 3.16+"
    echo "   Ubuntu/Debian: sudo apt install cmake"
    echo "   macOS: brew install cmake"
    echo "   Windows: Download from https://cmake.org/download/"
    exit 1
fi

# Create build directory
echo "📁 Creating build directory..."
if [ -d "build" ]; then
    echo "   Removing existing build directory..."
    rm -rf build
fi
mkdir build
cd build

# Configure with CMake
echo "⚙️  Configuring with CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build the application
echo "🔨 Building application..."
make -j$(nproc)

# Check if build was successful
if [ -f "pbl5_facelogin" ]; then
    echo "✅ Build successful!"
    echo "📱 Executable: $(pwd)/pbl5_facelogin"
    echo ""
    echo "🎯 Next steps:"
    echo "1. Start the server: docker compose up -d"
    echo "2. Run the app: ./pbl5_facelogin"
    echo "3. Configure server URL in Network Settings"
    echo "4. Test face recognition in Login screen"
    echo ""
    echo "🧪 Run integration test:"
    echo "   cd .. && python3 test_integration.py"
else
    echo "❌ Build failed! Check the error messages above."
    exit 1
fi

echo ""
echo "🎉 Ready to run! Use './pbl5_facelogin' to start the application."


