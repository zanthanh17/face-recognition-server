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
    
    // Expose function to deactivate camera from outside if needed
    function deactivateCamera() { 
        console.log("Deactivating camera from external call")
        if (cam) cam.active = false 
    }
    
    // Expose function to activate camera from outside if needed
    function activateCamera() { 
        console.log("Activating camera from external call")
        if (cam) cam.active = true 
    }

    width: 480
    height: 800
    visible: true
    title: "Face Login"
    color: "#EDEFF2"

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
                console.log("Logo clicked - going back to Home")
                loginPage.backToHomeRequested()
            }
        }
    }

    // ====== camera & overlay ======
    Rectangle {
        id: cameraFrame
        anchors.fill: parent
        color: "#EDEFF2"

        Camera {
            id: cam
            active: false // Start inactive, will be activated when page becomes visible
        }
        
        VideoOutput {
            id: preview
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
        }
        
        ImageCapture {
            id: imageCapture
            onImageCaptured: (id, preview) => {
                console.log("Image captured with id:", id)
                // Crop image to face frame and convert to base64 for avatar
                var croppedImage = backend.cropImageToFaceFrame(preview, preview.width, preview.height)
                loginPage.lastCapturedImage = croppedImage
                console.log("Cropped image to face frame, length:", croppedImage.length)
                // Convert preview to base64 and send to server with captured image
                backend.captureAndRecognizeFromQML(preview, loginPage.lastCapturedImage)
            }
            onErrorOccurred: (id, error, errorString) => {
                console.log("Image capture error:", errorString)
            }
        }
        
        CaptureSession {
            id: captureSession
            camera: cam
            videoOutput: preview
            imageCapture: imageCapture
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

        Label {
            text: cam.active ? "Vui lòng đưa mặt vào khung" : "Đang mở camera..."
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 60
            font.bold: true
            color: "#222"
            z: 3
        }
        
        // Capture button
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
                console.log("Capture button clicked")
                // Capture current frame using QML ImageCapture
                if (imageCapture.readyForCapture) {
                    imageCapture.capture()
                } else {
                    console.log("Image capture not ready")
                }
            }
        }
    }

    // ====== backend connections ======
    Connections {
        target: backend
        function onFaceRecognized(userId, userName) {
            console.log("=== FACE RECOGNITION SUCCESS ===")
            console.log("userId:", userId)
            console.log("userName:", userName)
            
            // Use captured image as avatar instead of server image
            var avatarUrl = ""
            if (loginPage.lastCapturedImage && loginPage.lastCapturedImage.length > 0) {
                avatarUrl = loginPage.lastCapturedImage
                console.log("Using captured image as avatar")
            } else {
                // Fallback to server image if no captured image
                if (userId && userId !== "") {
                    avatarUrl = "http://localhost:5000/api/users/" + userId + "/avatar"
                } else {
                    avatarUrl = "qrc:/assets/images/user.png"
                }
                console.log("Using server image as fallback avatar")
            }
            
            // Show success dialog with captured image as avatar
            dlgSuccess.openWithCaptureImage(userName, "Employee", "Welcome back! 👋", loginPage.lastCapturedImage)
            
            // Add recognition event with captured image
            backend.addRecognitionEventWithImage(userName, true, loginPage.lastCapturedImage)
            
            console.log("=== END FACE RECOGNITION ===")
        }
        
        function onFaceRecognitionFailed() {
            console.log("=== FACE RECOGNITION FAILED ===")
            
            // Use captured image as avatar for failed recognition too
            var avatarUrl = ""
            if (loginPage.lastCapturedImage && loginPage.lastCapturedImage.length > 0) {
                avatarUrl = loginPage.lastCapturedImage
                console.log("Using captured image as avatar for failed recognition")
            } else {
                avatarUrl = "qrc:/assets/images/user.png"
                console.log("No captured image available for failed recognition")
            }
            
            // Show failed dialog with captured image as avatar
            dlgFailed.openWithCaptureImage("Unknown", "Employee", "Please try again", loginPage.lastCapturedImage)
            
            // Add recognition event with captured image
            backend.addRecognitionEventWithImage("Unknown", false, loginPage.lastCapturedImage)
            
            console.log("=== END FACE RECOGNITION FAILED ===")
        }
        
        function onServerConnectionTested(success, message) {
            console.log("Server connection test:", success, message)
        }
    }

    // ====== keyboard shortcuts ======
    Keys.onReleased: (ev) => {
        if (ev.key === Qt.Key_R) {
            console.log("Manual recognition triggered")
            backend.captureAndRecognize()
        }
    }

    // Handle page visibility changes
    onVisibleChanged: {
        console.log("Login page visibility:", visible)
        if (visible) {
            // Page became visible - activate camera
            console.log("Activating camera...")
            cam.active = true
        } else {
            // Page became hidden - deactivate camera
            console.log("Deactivating camera...")
            cam.active = false
        }
    }
    
    // Also handle when page is loaded
    Component.onCompleted: {
        console.log("Login page completed, camera active:", cam.active)
        
        // Clear recognition history on app start to prevent showing old results
        console.log("Clearing recognition history on app start")
        backend.clearRecognitionHistory()
        
        if (visible) {
            cam.active = true
        }
    }
}
