#!/usr/bin/env python3
"""
Test script for Face Recognition Server
"""

import requests
import base64
import json
import os
from PIL import Image, ImageDraw

def create_test_image(name, size=(640, 480)):
    """Create a simple test image with text"""
    img = Image.new('RGB', size, color='lightblue')
    draw = ImageDraw.Draw(img)
    
    # Draw a simple face-like shape
    draw.ellipse([size[0]//4, size[1]//4, 3*size[0]//4, 3*size[1]//4], fill='lightpink', outline='black', width=3)
    # Eyes
    draw.ellipse([size[0]//3, size[1]//3, size[0]//3 + 30, size[1]//3 + 30], fill='black')
    draw.ellipse([2*size[0]//3 - 30, size[1]//3, 2*size[0]//3, size[1]//3 + 30], fill='black')
    # Mouth
    draw.arc([size[0]//2 - 40, size[1]//2, size[0]//2 + 40, size[1]//2 + 40], start=0, end=180, fill='black', width=3)
    
    # Add name text
    draw.text((size[0]//2 - 50, size[1] - 50), name, fill='black')
    
    return img

def image_to_base64(image):
    """Convert PIL Image to base64 string"""
    import io
    buffer = io.BytesIO()
    image.save(buffer, format='JPEG')
    img_str = base64.b64encode(buffer.getvalue()).decode()
    return img_str

def test_server(base_url="http://localhost:5000"):
    """Test all server endpoints"""
    
    print(f"🧪 Testing Face Recognition Server at {base_url}")
    print("=" * 50)
    
    # Test 1: Health check
    print("\n1. Testing health check...")
    try:
        response = requests.get(f"{base_url}/")
        if response.status_code == 200:
            print("✅ Health check passed")
            print(f"   Response: {response.json()}")
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return
    except Exception as e:
        print(f"❌ Cannot connect to server: {e}")
        return
    
    # Test 2: Register users
    print("\n2. Testing user registration...")
    test_users = [
        {"name": "Nguyễn Văn An", "department": "IT Department", "email": "an@test.com"},
        {"name": "Trần Thị Bình", "department": "HR Department", "email": "binh@test.com"},
        {"name": "Lê Văn Cường", "department": "Finance Department", "email": "cuong@test.com"}
    ]
    
    registered_users = []
    
    for user in test_users:
        try:
            # Create test image for user
            test_image = create_test_image(user["name"])
            image_base64 = image_to_base64(test_image)
            
            # Register user
            user_data = user.copy()
            user_data["face_image"] = image_base64
            
            response = requests.post(
                f"{base_url}/api/users/register",
                json=user_data,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 201:
                result = response.json()
                print(f"✅ Registered user: {user['name']} (ID: {result['user_id']})")
                registered_users.append(result)
            else:
                print(f"❌ Failed to register {user['name']}: {response.status_code}")
                print(f"   Error: {response.text}")
                
        except Exception as e:
            print(f"❌ Error registering {user['name']}: {e}")
    
    # Test 3: Get all users
    print("\n3. Testing get users...")
    try:
        response = requests.get(f"{base_url}/api/users")
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Retrieved {result['count']} users")
            for user in result['users']:
                print(f"   - {user['name']} ({user['department']})")
        else:
            print(f"❌ Failed to get users: {response.status_code}")
    except Exception as e:
        print(f"❌ Error getting users: {e}")
    
    # Test 4: Face recognition
    print("\n4. Testing face recognition...")
    if registered_users:
        try:
            # Test with the first registered user's "face"
            first_user = test_users[0]
            test_image = create_test_image(first_user["name"])
            image_base64 = image_to_base64(test_image)
            
            response = requests.post(
                f"{base_url}/api/auth/recognize",
                json={"face_image": image_base64},
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                result = response.json()
                if result['success']:
                    print(f"✅ Face recognized: {result['user_name']} ({result['confidence']}% confidence)")
                else:
                    print(f"⚠️ Face not recognized: {result.get('error')}")
                    print(f"   Best match confidence: {result.get('best_match_confidence', 0)}%")
            else:
                print(f"❌ Recognition failed: {response.status_code}")
                print(f"   Error: {response.text}")
                
        except Exception as e:
            print(f"❌ Error during recognition: {e}")
    
    # Test 5: Get login history
    print("\n5. Testing login history...")
    try:
        response = requests.get(f"{base_url}/api/history")
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Retrieved {result['count']} login attempts")
            for attempt in result['history'][:3]:  # Show first 3
                print(f"   - {attempt['user_name']}: {attempt['status']} ({attempt['confidence']}% confidence)")
        else:
            print(f"❌ Failed to get history: {response.status_code}")
    except Exception as e:
        print(f"❌ Error getting history: {e}")
    
    print("\n" + "=" * 50)
    print("🎉 Server testing completed!")
    print("\n📝 Next steps:")
    print("1. Deploy this server to Railway")
    print("2. Update Qt app to use the server API")
    print("3. Test with real camera images")

if __name__ == "__main__":
    import sys
    
    # Allow custom server URL
    server_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:5000"
    test_server(server_url) 