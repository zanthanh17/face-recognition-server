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
    
    // Expose function to deactivate camera from outside if needed
    function deactivateCamera() { 
        backend.stopCameraGrabber()
        cameraRunning = false
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
                if (cameraRunning && !loginPage.isProcessingFace) {
                    console.log("Smart capture triggered by user tap")
                    cameraFrame.captureForRecognition()
                }
            }
            
            // Optional: Capture when user moves mouse into frame area (uncomment if needed)
            // onEntered: {
            //     console.log("User entered frame area")
            // }
        }

        Label {
            text: {
                if (!cameraRunning) {
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
            // Page became visible - activate camera grabber
            backend.startCameraGrabber(30)
            cameraRunning = true
        } else {
            // Page became hidden - deactivate camera grabber
            backend.stopCameraGrabber()
            cameraRunning = false
        }
    }
    
    // Also handle when page is loaded
    Component.onCompleted: {
        // Clear recognition history on app start to prevent showing old results
        backend.clearRecognitionHistory()
        
        if (visible) {
            backend.startCameraGrabber(30)
            cameraRunning = true
        }
    }
}
