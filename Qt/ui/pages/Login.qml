// Login.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../dialogs"

Item {
    id: loginPage
    signal openSettingsRequested()
    signal backToHomeRequested()
    
    // Store last captured image for avatar
    property string lastCapturedImage: ""
    
    // Timer for capturing frames
    property bool cameraRunning: false
    
    // Property to track if we're currently processing face recognition
    property bool isProcessingFace: false
    
    // Property to track consecutive failed recognitions
    property int consecutiveFailures: 0
    
    // Property to track if face was detected in last check
    property bool lastCaptureHadFace: false
    
    // Property to track face detection status
    property bool faceDetected: false
    property bool autoCapturePending: false
    
    // Expose function to deactivate camera from outside if needed
    function deactivateCamera() { 
        backend.stopFaceDetection()
        backend.stopCameraGrabber()
        cameraRunning = false
        faceDetected = false
        autoCapturePending = false
        autoCaptureTimer.stop()
    }
    
    // Function to show camera error messages
    function showCameraError(message) {
        errorMessageLabel.text = message
        errorMessage.visible = true
        errorTimer.start()
    }
    
    // Expose function to activate camera from outside if needed
    function activateCamera() { 
        backend.startCameraGrabber(30)
        cameraRunning = true
        backend.startFaceDetection()
    }
    
    // Background color
    Rectangle {
        anchors.fill: parent
        color: "#EDEFF2"
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
    Rectangle {
        id: cameraFrame
        anchors.fill: parent
        color: "#EDEFF2"

        // Camera preview using image provider from C++
        Image {
            id: cameraPreview
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: "image://frames/current"
            cache: false
        }
        
        // Update preview when new frame is ready
        Connections {
            target: backend
            function onFrameReady() {
                // Update camera preview with timestamp to force refresh
                cameraPreview.source = "image://frames/current?ts=" + Date.now()
            }
        }
        
        
        
        // Function to capture current frame for face recognition
        function captureForRecognition() {
            if (!loginPage.isProcessingFace && cameraRunning) {
                loginPage.isProcessingFace = true
                
                // Get current frame from grabber
                var capturedImage = backend.captureFromGrabber()
                if (capturedImage && !capturedImage.isNull) {
                    // Convert to base64 and crop for avatar
                    var croppedImage = backend.cropImageToFaceFrame(capturedImage, capturedImage.width, capturedImage.height)
                    loginPage.lastCapturedImage = croppedImage
                    
                    // Start timeout timer
                    processingTimeoutTimer.start()
                    
                    // Send to server for recognition
                    backend.captureAndRecognizeFromQML(capturedImage, loginPage.lastCapturedImage)
                } else {
                    loginPage.isProcessingFace = false
                }
            }
        }

        // Face frame overlay - visual indicator
        Image {
            id: faceFrameOverlay
            anchors.centerIn: parent
            width: parent.width * 0.78
            height: parent.height * 0.78
            fillMode: Image.PreserveAspectFit
            source: "qrc:/assets/icons/face-frame.png"
            opacity: faceDetected ? 0.8 : 0.95
            z: 2
            
            // Visual feedback when face is detected - using Rectangle overlay instead
            Rectangle {
                anchors.fill: parent
                color: faceDetected ? "#4CAF50" : "transparent"
                opacity: faceDetected ? 0.2 : 0
                radius: 10
                
                Behavior on opacity {
                    NumberAnimation { duration: 300 }
                }
            }
        }

        Label {
            text: {
                if (!cameraRunning) {
                    return "Đang mở camera..."
                } else if (loginPage.isProcessingFace) {
                    return "Đang nhận diện khuôn mặt..."
                } else if (faceDetected) {
                    return "Khuôn mặt đã được phát hiện - Đang chụp ảnh..."
                } else {
                    return "Đưa khuôn mặt vào khung để nhận diện"
                }
            }
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 60
            font.bold: true
            color: faceDetected ? "#4CAF50" : "#222"
            z: 3
            
            Behavior on color {
                ColorAnimation { duration: 300 }
            }
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
        
        // No more timer - using event-driven approach
        
        // Auto capture timer - captures after face is detected and stable
        Timer {
            id: autoCaptureTimer
            interval: 1000 // Wait 1 second after face detection
            repeat: false
            
            onTriggered: {
                if (faceDetected && autoCapturePending && !loginPage.isProcessingFace) {
                    console.log("Auto-capturing face after detection")
                    autoCapturePending = false
                    cameraFrame.captureForRecognition()
                }
            }
        }
        
        // Timer to reset processing flag if stuck
        Timer {
            id: processingTimeoutTimer
            interval: 5000 // 5 seconds timeout
            repeat: false
            
            onTriggered: {
                if (loginPage.isProcessingFace) {
                    console.log("Processing timeout - resetting flags")
                    loginPage.isProcessingFace = false
                    
                    // Also reset face detection status
                    faceDetected = false
                    autoCapturePending = false
                    autoCaptureTimer.stop()
                }
            }
        }
    }

    // ====== backend connections ======
    Connections {
        target: backend
        
        // Handle face detection events
        function onFaceDetectionChanged(detected) {
            console.log("Face detection changed:", detected)
            
            if (detected && !faceDetected && !loginPage.isProcessingFace) {
                // Face just detected
                console.log("Face detected - preparing to capture")
                faceDetected = true
                autoCapturePending = true
                
                // Wait a moment for user to position properly, then capture
                autoCaptureTimer.start()
            } else if (!detected && faceDetected) {
                // Face lost
                console.log("Face lost")
                faceDetected = false
                autoCapturePending = false
                autoCaptureTimer.stop()
            }
        }
        
        function onFaceRecognized(userId, userName) {
            console.log("FACE RECOGNITION SUCCESS:", userName)
            
            // Reset processing flag
            loginPage.isProcessingFace = false
            processingTimeoutTimer.stop()
            
            // Reset face detection status
            faceDetected = false
            autoCapturePending = false
            autoCaptureTimer.stop()
            
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
            
            // Reset face detection status
            faceDetected = false
            autoCapturePending = false
            autoCaptureTimer.stop()
            
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
            if (cameraRunning && !loginPage.isProcessingFace) {
                cameraFrame.captureForRecognition()
            }
        } else if (ev.key === Qt.Key_Space) {
            console.log("Keyboard capture triggered (Space key)")
            if (cameraRunning && !loginPage.isProcessingFace) {
                cameraFrame.captureForRecognition()
            }
        }
    }
    
    // Enable focus for keyboard handling
    focus: true

    // Handle page visibility changes
    onVisibleChanged: {
        if (visible) {
            // Page became visible - activate camera grabber and face detection
            backend.startCameraGrabber(30)
            cameraRunning = true
            backend.startFaceDetection()
        } else {
            // Page became hidden - deactivate camera grabber and face detection
            backend.stopFaceDetection()
            backend.stopCameraGrabber()
            cameraRunning = false
            faceDetected = false
            autoCapturePending = false
            autoCaptureTimer.stop()
        }
    }
    
    // Also handle when page is loaded
    Component.onCompleted: {
        // Clear recognition history on app start to prevent showing old results
        backend.clearRecognitionHistory()
        
        if (visible) {
            backend.startCameraGrabber(30)
            cameraRunning = true
            backend.startFaceDetection()
        }
    }
}
