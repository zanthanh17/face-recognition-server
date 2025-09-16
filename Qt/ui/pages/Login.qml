// Login.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtMultimedia
import "../dialogs"

Window {
    id: loginPage
    signal openSettingsRequested()
    signal backToHomeRequested()
    
    // Store last captured image for avatar
    property string lastCapturedImage: ""
    
    // Camera device property
    property var usbDvCameraDevice: null
    
    // Property to track if we're currently processing face recognition
    property bool isProcessingFace: false
    
    // Property to track consecutive failed recognitions
    property int consecutiveFailures: 0
    
    // Property to track if face was detected in last check
    property bool lastCaptureHadFace: false
    
    // Window properties
    width: 480
    height: 800
    visible: true
    title: "Face Login"
    
    // Expose function to deactivate camera from outside if needed
    function deactivateCamera() { 
        if (cam) cam.active = false 
    }
    
    // Function to show camera error messages
    function showCameraError(message) {
        errorMessageLabel.text = message
        errorMessage.visible = true
        errorTimer.start()
    }
    
    // Focus scope for keyboard handling
    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: true
        
        // Background color
        Rectangle {
            anchors.fill: parent
            color: "#EDEFF2"
        }
    
    // Expose function to activate camera from outside if needed
    function activateCamera() { 
        if (cam) cam.active = true 
    }

    // ====== dialogs ======
    DialogSuccess { id: dlgSuccess; anchors.centerIn: parent }
    DialogFailed  { id: dlgFailed;  anchors.centerIn: parent }

    // ====== top left logo ======
    Rectangle {
        id: topLeftLogo
        width: 50
        height: 50
        color: "transparent"
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 16
        z: 10

        Image {
            id: logoImage
            anchors.fill: parent
            source: "qrc:/assets/icons/logo.jpg"
            fillMode: Image.PreserveAspectFit
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                loginPage.backToHomeRequested()
            }
        }
    }

    // ====== camera & overlay ======
    // Camera device for USB DV camera
    property var usbDvCameraDevice: null
    
    Rectangle {
        id: cameraFrame
        anchors.fill: parent
        color: "#EDEFF2"

        MediaDevices {
            id: mediaDevices
        }

        Camera {
            id: cam
            active: false
            cameraDevice: usbDvCameraDevice
            
            onCameraDeviceChanged: {
                // Camera device changed
            }
            
            // Optimize camera settings to reduce corruption
            focusMode: Camera.FocusModeAuto
            flashMode: Camera.FlashOff
            
            // Error handling
            onErrorOccurred: function(error, errorString) {
                console.log("Camera error:", errorString)
                if (error === Camera.CameraError.CameraNotAvailable) {
                    // Try to use default camera as fallback
                    cam.cameraDevice = mediaDevices.defaultVideoInput
                } else if (error === Camera.CameraError.CameraPermissionDenied) {
                    showCameraError("Camera permission denied. Please check camera permissions.")
                } else if (error === Camera.CameraError.CameraInUse) {
                    showCameraError("Camera is in use by another application. Please close other camera applications.")
                } else {
                    showCameraError("Camera error: " + errorString)
                }
            }
            
            onActiveChanged: {
                console.log("Camera active state changed:", active)
                if (active) {
                    console.log("Camera activated - timer should start")
                } else {
                    console.log("Camera deactivated - timer should stop")
                }
            }
        }

        VideoOutput {
            id: preview
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
            
            onVisibleChanged: {
                // VideoOutput visible changed
            }
        }

        CaptureSession {
            id: captureSession
            camera: cam
            videoOutput: preview
            imageCapture: imageCapture
        }

        ImageCapture {
            id: imageCapture
        }

        Connections {
            target: cam
            function onActiveChanged() {
                // Camera active changed
            }
        }
        
        // Initialize camera selection on component creation
        Component.onCompleted: {
            // Get camera device from C++ CameraManager
            var cameraDevice = backend.getSelectedCameraDevice()
            if (cameraDevice && cameraDevice !== null) {
                usbDvCameraDevice = cameraDevice
                
                // Setup capture session
                captureSession.camera = cam
                captureSession.videoOutput = preview
                captureSession.imageCapture = imageCapture
            } else {
                console.log("Using default camera device")
                // Try to use default camera device
                usbDvCameraDevice = mediaDevices.defaultVideoInput
                
                // Setup capture session with default camera
                captureSession.camera = cam
                captureSession.videoOutput = preview
                captureSession.imageCapture = imageCapture
            }
            
            // Check if running on Raspberry Pi and show appropriate message
            if (cameraDevice === null || cameraDevice === undefined) {
                showCameraError("No camera detected. Please check camera connection and permissions.")
            }
        }
        
        
        
        // Handle page visibility changes
        onVisibleChanged: {
            if (visible) {
                cam.active = true
                // Force camera selection after a short delay
                cameraSelectionTimer.start()
            } else {
                cam.active = false
                cameraSelectionTimer.stop()
            }
        }
        
        // Timer to force camera selection
        Timer {
            id: cameraSelectionTimer
            interval: 5000 
            repeat: false
            onTriggered: {
                // Get available cameras
                var cameras = QtMultimedia.MediaDevices.videoInputs()
                
                // Find USB camera (DV20 USB)
                for (var i = 0; i < cameras.length; i++) {
                    if (cameras[i].description.includes("DV20") || 
                        cameras[i].description.includes("USB Composite") ||
                        cameras[i].id.includes("video0") ||
                        cameras[i].id.includes("video1")) {
                        cam.cameraDevice = cameras[i]
                        break
                    }
                }
            }
        }
        
        // Camera preview is already defined above

        // Image capture is already defined above
        Connections {
            target: imageCapture
            function onImageCaptured(id, preview) {
                // Crop image to face frame and convert to base64 for avatar
                var croppedImage = backend.cropImageToFaceFrame(preview, preview.width, preview.height)
                loginPage.lastCapturedImage = croppedImage
                
                // Start timeout timer to prevent stuck processing
                processingTimeoutTimer.start()
                
                // Send to server for face detection and recognition
                // Server will first detect face, then recognize if face is found
                backend.captureAndRecognizeFromQML(preview, loginPage.lastCapturedImage)
            }
            function onErrorOccurred(id, error, errorString) {
                console.log("Image capture error:", errorString)
            }
        }
        
        // Remove duplicate CaptureSession since we already have one above

        Image {
            anchors.centerIn: parent
            width: parent.width * 0.78
            height: parent.height * 0.78
            fillMode: Image.PreserveAspectFit
            source: "qrc:/assets/icons/face-frame.png"
            opacity: 0.95
            z: 2
        }
        
        // Smart touch area - only capture when user intentionally interacts
        MouseArea {
            anchors.fill: parent
            z: 1
            hoverEnabled: true
            
            onClicked: {
                if (cam.active && imageCapture.readyForCapture && !loginPage.isProcessingFace) {
                    console.log("Smart capture triggered by user tap")
                    imageCapture.capture()
                }
            }
            
            // Optional: Capture when user moves mouse into frame area (uncomment if needed)
            // onEntered: {
            //     console.log("User entered frame area")
            // }
        }

        Label {
            text: {
                if (!cam.active) {
                    return "Đang mở camera..."
                } else if (loginPage.isProcessingFace) {
                    return "Đang nhận diện khuôn mặt..."
                } else {
                    return "Chạm vào màn hình để chụp ảnh"
                }
            }
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 60
            font.bold: true
            color: "#222"
            z: 3
        }
        
        // Error message
        Rectangle {
            id: errorMessage
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 100
            width: parent.width - 40
            height: 40
            color: "#ffebee"
            border.color: "#f44336"
            border.width: 1
            radius: 4
            visible: false
            z: 4
            
            Label {
                id: errorMessageLabel
                anchors.centerIn: parent
                text: ""
                color: "#d32f2f"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
        
        // Timer to hide error message
        Timer {
            id: errorTimer
            interval: 5000
            repeat: false
            onTriggered: {
                errorMessage.visible = false
            }
        }
        
        // Frame area detection - DISABLED: Only capture on user interaction
        Timer {
            id: frameDetectionTimer
            interval: 3000
            repeat: true
            running: false // DISABLED - No automatic timer capture
            
            onTriggered: {
                // Timer disabled - no automatic capture
            }
        }
        
        // Timer to reset processing flag if stuck
        Timer {
            id: processingTimeoutTimer
            interval: 5000 // 5 seconds timeout
            repeat: false
            
            onTriggered: {
                if (loginPage.isProcessingFace) {
                    console.log("Processing timeout - resetting flag")
                    loginPage.isProcessingFace = false
                }
            }
        }
    }

    // ====== backend connections ======
    Connections {
        target: backend
        function onFaceRecognized(userId, userName) {
            console.log("FACE RECOGNITION SUCCESS:", userName)
            
            // Reset processing flag
            loginPage.isProcessingFace = false
            processingTimeoutTimer.stop()
            
            // Reset consecutive failures counter
            loginPage.consecutiveFailures = 0
            
            // Face was detected successfully
            loginPage.lastCaptureHadFace = true
            
            // Use captured image as avatar instead of server image
            var avatarUrl = ""
            if (loginPage.lastCapturedImage && loginPage.lastCapturedImage.length > 0) {
                avatarUrl = loginPage.lastCapturedImage
            } else {
                // Fallback to server image if no captured image
                if (userId && userId !== "") {
                    avatarUrl = "http://localhost:5000/api/users/" + userId + "/avatar"
                } else {
                    avatarUrl = "qrc:/assets/images/user.png"
                }
            }
            
            // Show success dialog with captured image as avatar
            dlgSuccess.openWithCaptureImage(userName, "Employee", "Welcome back! 👋", loginPage.lastCapturedImage)
            
            // Add recognition event with captured image
            backend.addRecognitionEventWithImage(userName, true, loginPage.lastCapturedImage)
        }
        
        function onFaceRecognitionFailed() {
            console.log("FACE RECOGNITION FAILED - No face detected or unknown face")
            
            // Reset processing flag
            loginPage.isProcessingFace = false
            processingTimeoutTimer.stop()
            
            // Increment consecutive failures counter
            loginPage.consecutiveFailures++
            
            // No face detected
            loginPage.lastCaptureHadFace = false
            
            // Use captured image as avatar for failed recognition too
            var avatarUrl = ""
            if (loginPage.lastCapturedImage && loginPage.lastCapturedImage.length > 0) {
                avatarUrl = loginPage.lastCapturedImage
            } else {
                avatarUrl = "qrc:/assets/images/user.png"
            }
            
            // Show failed dialog with captured image as avatar
            dlgFailed.openWithCaptureImage("Unknown", "Employee", "Please try again", loginPage.lastCapturedImage)
            
            // Add recognition event with captured image
            backend.addRecognitionEventWithImage("Unknown", false, loginPage.lastCapturedImage)
        }
        
        function onServerConnectionTested(success, message) {
            // Server connection test completed
        }
    }

        // ====== keyboard shortcuts ======
        Keys.onReleased: function(ev) {
            if (ev.key === Qt.Key_R) {
                console.log("Keyboard capture triggered (R key)")
                if (cam.active && imageCapture.readyForCapture && !loginPage.isProcessingFace) {
                    imageCapture.capture()
                }
            } else if (ev.key === Qt.Key_Space) {
                console.log("Keyboard capture triggered (Space key)")
                if (cam.active && imageCapture.readyForCapture && !loginPage.isProcessingFace) {
                    imageCapture.capture()
                }
            }
        }
    }

    // Handle page visibility changes
    onVisibleChanged: {
        if (visible) {
            // Page became visible - activate camera
            cam.active = true
        } else {
            // Page became hidden - deactivate camera
            cam.active = false
        }
    }
    
    // Also handle when page is loaded
    Component.onCompleted: {
        // Clear recognition history on app start to prevent showing old results
        backend.clearRecognitionHistory()
        
        if (visible) {
            cam.active = true
        }
    }
}
