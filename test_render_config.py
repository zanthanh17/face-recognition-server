#!/usr/bin/env python3
"""
Test script để kiểm tra cấu hình Render trước khi deploy
"""

import os
import sys
import subprocess
from pathlib import Path

def test_requirements():
    """Test requirements-render.txt"""
    print("🔍 Testing requirements-render.txt...")
    
    requirements_file = Path("server/requirements-render.txt")
    if not requirements_file.exists():
        print("❌ requirements-render.txt not found")
        return False
    
    try:
        # Test import các package chính
        import fastapi
        import uvicorn
        import numpy
        import cv2
        import deepface
        print("✅ All main packages can be imported")
        return True
    except ImportError as e:
        print(f"❌ Import error: {e}")
        return False

def test_start_server():
    """Test start_server.py"""
    print("🔍 Testing start_server.py...")
    
    start_script = Path("scripts/start_server.py")
    if not start_script.exists():
        print("❌ start_server.py not found")
        return False
    
    # Test syntax
    try:
        with open(start_script, 'r') as f:
            code = f.read()
        compile(code, start_script, 'exec')
        print("✅ start_server.py syntax is valid")
        return True
    except SyntaxError as e:
        print(f"❌ Syntax error in start_server.py: {e}")
        return False

def test_render_yaml():
    """Test render.yaml"""
    print("🔍 Testing render.yaml...")
    
    render_file = Path("render.yaml")
    if not render_file.exists():
        print("❌ render.yaml not found")
        return False
    
    try:
        import yaml
        with open(render_file, 'r') as f:
            config = yaml.safe_load(f)
        
        # Kiểm tra cấu trúc cơ bản
        if 'services' not in config:
            print("❌ No 'services' key in render.yaml")
            return False
        
        services = config['services']
        if len(services) < 1:
            print("❌ No services defined")
            return False
        
        # Kiểm tra web service
        web_service = None
        for service in services:
            if service.get('type') == 'web':
                web_service = service
                break
        
        if not web_service:
            print("❌ No web service defined")
            return False
        
        # Kiểm tra các field bắt buộc
        required_fields = ['name', 'env', 'buildCommand', 'startCommand']
        for field in required_fields:
            if field not in web_service:
                print(f"❌ Missing required field: {field}")
                return False
        
        print("✅ render.yaml structure is valid")
        return True
    except Exception as e:
        print(f"❌ Error parsing render.yaml: {e}")
        return False

def test_environment_variables():
    """Test environment variables"""
    print("🔍 Testing environment variables...")
    
    # Set test environment
    os.environ['HOST'] = '0.0.0.0'
    os.environ['PORT'] = '8000'
    os.environ['RECOGNITION_THRESHOLD'] = '0.45'
    os.environ['DEEPFACE_MODEL'] = 'ArcFace'
    
    try:
        from scripts.start_server import main
        print("✅ Environment variables are properly configured")
        return True
    except Exception as e:
        print(f"❌ Error with environment variables: {e}")
        return False

def main():
    """Main test function"""
    print("🚀 Testing Render deployment configuration...\n")
    
    tests = [
        test_requirements,
        test_start_server,
        test_render_yaml,
        test_environment_variables
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        if test():
            passed += 1
        print()
    
    print(f"📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Ready for Render deployment.")
        return 0
    else:
        print("❌ Some tests failed. Please fix issues before deploying.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
