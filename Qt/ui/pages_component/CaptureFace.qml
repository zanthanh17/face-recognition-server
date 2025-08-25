import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import "../components"

Item {
    id: page

    property string userId: ""
    property string userName: ""
    property string userDepartment: ""
    property url currentAvatar: "qrc:/assets/images/user.png"

    signal backRequested()
    signal captureAccepted(url newAvatarUrl)

    property url  capturedAvatarUrl: ""
    property bool previewOpen: false

    // ===== Camera (Qt 5) =====
    Camera {
        id: cam
        active: true
    }

    // Camera preview only - no capture functionality
    // This page is now used only for camera preview

    // Handle page visibility changes
    onVisibleChanged: {
        console.log("CaptureFace page visibility:", visible)
    }

    // ===== UI =====
    VideoOutput {
        id: preview
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }
    
    CaptureSession {
        id: captureSession
        camera: cam
        videoOutput: preview
    }

    // Back
    ToolButton {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 12
        z: 10
        background: Rectangle { radius: 16; color: "#ECEFF4"; border.color: "#D2D7DE" }
        contentItem: Label { text: "\u2039"; font.pixelSize: 22; color: "#333"; padding: 8;
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        onClicked: page.backRequested()
    }

    // Frame overlay
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
        text: cam.active ? "Camera Preview Mode" : "Đang mở camera..."
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 64
        font.bold: true
        color: "#222"
        z: 3
    }

    // Capture button (always clickable unless preview is open)
    Button {
        id: btnCapture
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        text: "Capture"
        enabled: !previewOpen
        background: Rectangle { radius: 8; color: enabled ? "#1976D2" : "#9BBCE3" }
        contentItem: Label { text: btnCapture.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; padding: 10 }
        z: 4
        onClicked: {
            page.capturedAvatarUrl = ""
            if (!cam.active) cam.active = true
            if (imageCap.readyForCapture) {
                imageCap.captureToFile()
            } else {
                console.log("[UI] Not ready -> wait then capture")
                captureRetry.start()
            }
        }
    }

    // Preview dialog
    Dialog {
        id: confirmDialog
        modal: true
        focus: true
        x: (page.width - width) / 2
        y: (page.height - height) / 2
        width: Math.min(page.width - 40, 320)
        background: Rectangle { radius: 14; color: "#FFFFFF"; border.color: "#C9CED6" }
        onClosed: previewOpen = false
        Overlay.modal: Rectangle { color: "#000"; opacity: 0.25 }

        header: Label {
            text: "Ảnh vừa chụp"
            font.bold: true
            padding: 12
            horizontalAlignment: Text.AlignHCenter
        }

        contentItem: Column {
            width: 300
            height: 320
            spacing: 12
            Image {
                source: page.capturedAvatarUrl
                width: 220; height: 220
                fillMode: Image.PreserveAspectFit
                smooth: true
                cache: false
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Label {
                width: 280
                text: "Chọn Confirm để cập nhật avatar hoặc Retake để chụp lại."
                color: "#555"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        footer: RowLayout {
            Layout.fillWidth: true
            spacing: 8
            anchors.margins: 12

            Button {
                text: "Retake"
                Layout.fillWidth: true
                background: Rectangle { color: "#ECEFF4"; radius: 8; border.color: "#D2D7DE" }
                onClicked: confirmDialog.close()
            }
            Button {
                id: btnConfirm
                text: "Confirm"
                Layout.fillWidth: true
                background: Rectangle { color: "#1976D2"; radius: 8 }
                contentItem: Label { text: btnConfirm.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: {
                    confirmDialog.close()
                    
                    // Register face with server
                    if (page.capturedAvatarUrl !== "") {
                        let imageData = backend.readImageFile(page.capturedAvatarUrl)
                        if (imageData.length > 0) {
                            let success = backend.registerFaceWithServer(
                                imageData, 
                                page.userName, 
                                page.userDepartment
                            )
                            
                            if (success) {
                                page.captureAccepted(page.capturedAvatarUrl)
                            } else {
                                // Show error dialog
                                console.log("Registration failed")
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("[Component] Camera device:", cam.cameraDevice ? cam.cameraDevice.description : "<none>")
        console.log("[Component] readyForCapture =", imageCapture.readyForCapture)
    }
}
