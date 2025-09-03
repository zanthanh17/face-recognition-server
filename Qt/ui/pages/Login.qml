// Login.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import "../dialogs"

Item {
    id: loginPage
    signal openSettingsRequested()
    signal backToHomeRequested()
    
    // Store last captured image for avatar
    property string lastCapturedImage: ""
    
    // Expose function to deactivate camera from outside if needed
    function deactivateCamera() { 
        // console.log("Deactivating camera from external call") // Disabled for RPi optimization
        // Camera is handled by backend on Raspberry Pi
    }
    
    // Expose function to activate camera from outside if needed
    function activateCamera() { 
        // console.log("Activating camera from external call") // Disabled for RPi optimization
        // Camera is handled by backend on Raspberry Pi
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
                // console.log("Logo clicked - going back to Home") // Disabled for RPi optimization
                loginPage.backToHomeRequested()
            }
        }
    }



    // ====== camera & overlay ======
    Rectangle {
        id: cameraFrame
        anchors.fill: parent
        color: "#EDEFF2"

@        // Real camera preview using rpicam-apps
        Rectangle {
            id: cameraPreview
            anchors.fill: parent
            color: "#2C3E50"
            
            // Camera preview container
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.8
                height: parent.height * 0.6
                color: "#34495E"
                radius: 8
                
                // Camera preview will be shown here
                // We'll use a background process to capture frames
                Rectangle {
                    id: cameraView
                    anchors.fill: parent
                    anchors.margins: 4
                    color: "#1a1a1a"
                    radius: 4
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Camera Preview\nĐang khởi tạo..."
                        color: "white"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                    }
                    
                    // Camera status indicator
                    Rectangle {
                        id: cameraStatus
                        width: 12
                        height: 12
                        radius: 6
                        color: "#e74c3c" // Red initially
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 10
                    }
                }
            }
        }
        
        // Remove the problematic Camera, VideoOutput, ImageCapture, and CaptureSession elements
        // These will be replaced with backend-based camera handling
        
        Image {
            anchors.centerIn: parent
            width: parent.width * 0.78
            height: parent.height * 0.78
            fillMode: Image.PreserveAspectFit
            source: "qrc:/assets/icons/face-frame.png"
            opacity: 0.95
            z: 2
        }

        Label {
            text: "Camera đã sẵn sàng - Vui lòng đưa mặt vào khung"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 60
            font.bold: true
            color: "#222"
            z: 3
        }
        
        // Capture button - modified to use backend camera
        Button {
            id: captureBtn
            text: "Capture & Recognize"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            width: 200
            height: 40
            z: 3
            
            background: Rectangle {
                radius: 8
                color: captureBtn.pressed ? "#1a5f7a" : "#2E7D32"
                border.color: "#1b5e20"
                border.width: 1
            }
            
            contentItem: Label {
                text: captureBtn.text
                color: "white"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            onClicked: {
                // Use backend camera capture instead of QML ImageCapture
                backend.captureAndRecognize()
            }
        }
        
        // Timer to update camera status
        Timer {
            id: cameraStatusTimer
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                // Check if camera is available
                if (backend.getCameraAvailable()) {
                    cameraStatus.color = "#27AE60" // Green
                    cameraView.children[0].text = "Camera Preview\nĐang hoạt động"
                } else {
                    cameraStatus.color = "#e74c3c" // Red
                    cameraView.children[0].text = "Camera Preview\nKhông khả dụng"
                }
            }
        }
    }

    // ====== Auto recognition timer ======
    // Commented out to prevent automatic recognition spam
    // Timer {
    //     id: recognitionTimer
    //     interval: 3000 // Check every 3 seconds
    //     running: cam.active && backend.wifiConnected
    //     repeat: true
    //     onTriggered: {
    //         if (cam.active) {
    //             // Auto recognition every 3 seconds
    //             console.log("Auto recognition triggered")
    //             backend.captureAndRecognize()
    //         }
    //     }
    // }
    
    // ====== Backend signal connections ======
    Connections {
        target: backend
        function onFaceRecognized(userId, userName) {
            // console.log("=== FACE RECOGNITION SUCCESS ===") // Disabled for RPi optimization
            // console.log("userId:", userId) // Disabled for RPi optimization
            // console.log("userName:", userName) // Disabled for RPi optimization
            
            // Use captured image as avatar instead of server image
            var avatarUrl = ""
            if (loginPage.lastCapturedImage && loginPage.lastCapturedImage.length > 0) {
                avatarUrl = loginPage.lastCapturedImage
                // console.log("Using captured image as avatar") // Disabled for RPi optimization
            } else {
                // Fallback to server image if no captured image
                var userImageData = backend.getUserImage(userId)
                if (userImageData && userImageData.length > 0) {
                    avatarUrl = "data:image/jpeg;base64," + userImageData
                } else {
                    avatarUrl = "qrc:/assets/images/user.png"
                }
                // console.log("Using server image as fallback avatar") // Disabled for RPi optimization
            }
            
            // Use captured image as avatar in dialog
            dlgSuccess.openWithCaptureImage(userName, "Employee", "Welcome back! 👋", loginPage.lastCapturedImage)
            
            // Add recognition event with captured image
            backend.addRecognitionEventWithImage(userName, true, loginPage.lastCapturedImage)
            
            // console.log("=== END FACE RECOGNITION ===") // Disabled for RPi optimization
        }
        
        function onFaceRecognitionFailed() {
            // console.log("=== FACE RECOGNITION FAILED ===") // Disabled for RPi optimization
            
            // Use captured image as avatar for failed recognition too
            var avatarUrl = ""
            if (loginPage.lastCapturedImage && loginPage.lastCapturedImage.length > 0) {
                avatarUrl = loginPage.lastCapturedImage
                // console.log("Using captured image as avatar for failed recognition") // Disabled for RPi optimization
            } else {
                avatarUrl = "qrc:/assets/images/user.png"
                // console.log("No captured image available for failed recognition") // Disabled for RPi optimization
            }
            
            // Show failed dialog with captured image
            dlgFailed.openWithCaptureImage("Unknown", "Employee", "Please try again", loginPage.lastCapturedImage)
            
            // Add recognition event with captured image (even for failed recognition)
            backend.addRecognitionEventWithImage("Unknown", false, loginPage.lastCapturedImage)
            
            // console.log("=== END FACE RECOGNITION FAILED ===") // Disabled for RPi optimization
        }
        
        function onServerConnectionTested(success, message) {
            // console.log("Server connection test:", success, message) // Disabled for RPi optimization
        }
    }
    
    // ====== phím tắt test ======
    focus: true
    Keys.onReleased: (ev) => {
        if (ev.key === Qt.Key_R) {
            // console.log("Manual recognition triggered") // Disabled for RPi optimization
            backend.captureAndRecognize()
        }
        if (ev.key === Qt.Key_S) dlgSuccess.openWith("Demo User", "Employee", "Hi 👋")
        if (ev.key === Qt.Key_F) dlgFailed.openWith("Unknown", "Employee", "Please try again")
    }

    // Handle page visibility changes
    onVisibleChanged: {
        // console.log("Login page visibility:", visible) // Disabled for RPi optimization
        if (visible) {
            // Page became visible - camera is handled by backend
            // console.log("Page visible - camera ready") // Disabled for RPi optimization
        } else {
            // Page became hidden - camera is handled by backend
            // console.log("Page hidden") // Disabled for RPi optimization
        }
    }
    
    // Also handle when page is loaded
    Component.onCompleted: {
        // console.log("Login page completed") // Disabled for RPi optimization
        
        // Clear recognition history on app start to prevent showing old results
        // console.log("Clearing recognition history on app start") // Disabled for RPi optimization
        backend.clearRecognitionHistory()
    }
}
