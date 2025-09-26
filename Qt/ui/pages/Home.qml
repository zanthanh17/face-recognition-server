// Home.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../dialogs"

Item {
    id: homePage
    signal openSettingsRequested()
    signal startFaceRecognition()
    
    // Store last captured image for avatar
    property string lastCapturedImage: ""
    
    // Expose function to deactivate camera from outside if needed
    function deactivateCamera() {
        console.log("Home page: No camera to deactivate")
    }
    
    // Expose function to activate camera from outside if needed
    function activateCamera() {
        console.log("Home page: No camera to activate")
    }

    // ====== dialogs ======
    DialogSuccess { id: dlgSuccess; anchors.centerIn: parent }
    DialogFailed  { id: dlgFailed;  anchors.centerIn: parent }

    // ====== top bar ======
    Rectangle {
        id: topBar
        height: 50
        width: parent.width
        color: "transparent"
        anchors.top: parent.top
        anchors.topMargin: 0
        z: 10

        // WiFi icon sát góc trái
        Image {
            id: wifiIcon
            source: backend.getWifiConnected() ? "qrc:/assets/icons/wifi.png" : "qrc:/assets/icons/disconnectwifi.png"
            fillMode: Image.PreserveAspectFit
            width: 32
            height: 32
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.top: parent.top
            anchors.topMargin: 0
        }

        // Setting icon sát góc phải
        ToolButton {
            id: settingButton
            icon.source: "qrc:/assets/icons/setting.png"
            width: 32
            height: 32
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.top: parent.top
            anchors.topMargin: 0
            background: Rectangle {
                id: settingButtonBg
                color: "transparent"
                radius: 4
            }
            onClicked: homePage.openSettingsRequested()
            
            // Handle press state
            onPressedChanged: {
                if (pressed) {
                    settingButtonBg.color = "rgba(0, 0, 0, 0.1)"
                } else {
                    settingButtonBg.color = "transparent"
                }
            }
        }
    }

    // ====== background image ======
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: "qrc:/assets/images/background.jpg"
        // fillMode: Image.Cover
        z: 1
    }

    // ====== main content overlay ======
    Rectangle {
        id: mainContent
        anchors.fill: parent
        color: "transparent"
        z: 2

        // Main logo ở giữa màn hình
        Image {
            id: mainLogo
            source: "qrc:/assets/icons/logo.jpg"
            width: 120
            height: 120
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 100
        }

        // Emoticon face
        Rectangle {
            id: emoticonFace
            width: 80
            height: 80
            color: "transparent"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 280

            // Eyes
            Rectangle {
                width: 12
                height: 8
                color: "black"
                radius: 4
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.top: parent.top
                anchors.topMargin: 25
            }

            Rectangle {
                width: 12
                height: 8
                color: "black"
                radius: 4
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.top: parent.top
                anchors.topMargin: 25
            }

            // Smile (main)
            Rectangle {
                width: 40
                height: 6
                color: "black"
                radius: 3
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
            }

            // Frown (background, faded)
            Rectangle {
                width: 35
                height: 4
                color: "gray"
                radius: 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 22
                opacity: 0.5
            }
        }

        // Clickable area for emoticon
        MouseArea {
            anchors.fill: emoticonFace
            onClicked: {
                console.log("Emoticon clicked - starting face recognition")
                homePage.startFaceRecognition()
            }
        }
    }

    // ====== bottom text overlay ======
    Column {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8
        z: 3

        Text {
            id: timeText
            text: Qt.formatTime(new Date(), "HH:mm")
            color: "black"
            font.pixelSize: 20
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            id: dateText
            text: Qt.formatDate(new Date(), "dddd dd-MM-yyyy")
            color: "black"
            font.pixelSize: 18
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "How do you feel today?"
            color: "black"
            font.pixelSize: 18
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            timeText.text = Qt.formatTime(new Date(), "HH:mm")
            dateText.text = Qt.formatDate(new Date(), "dddd dd-MM-yyyy")
        }
    }



    // ====== Backend signal connections ======
    Connections {
        target: backend
        function onServerConnectionTested(success, message) {
            console.log("Server connection test:", success, message)
        }
        
        // Lắng nghe sự kiện thay đổi wifi status
        function onWifiConnectedChanged() {
            console.log("WiFi status changed")
            if (backend.getWifiConnected()) {
                wifiIcon.source = "qrc:/assets/icons/wifi.png"
            } else {
                wifiIcon.source = "qrc:/assets/icons/disconnectwifi.png"
            }
        }
    }
    
    // ====== phím tắt test ======
    focus: true
    Keys.onReleased: (ev) => {
        if (ev.key === Qt.Key_S) dlgSuccess.openWith("Demo User", "Employee", "Hi 👋")
        if (ev.key === Qt.Key_F) dlgFailed.openWith("Unknown", "Employee", "Please try again")
    }

    // Handle page visibility changes
    onVisibleChanged: {
        console.log("Home page visibility:", visible)
    }
    
    // Also handle when page is loaded
    Component.onCompleted: {
        console.log("Home page completed")
        
        // Cập nhật wifi status khi page được load
        if (backend.getWifiConnected()) {
            wifiIcon.source = "qrc:/assets/icons/wifi.png"
        } else {
            wifiIcon.source = "qrc:/assets/icons/disconnectwifi.png"
        }
    }
}

