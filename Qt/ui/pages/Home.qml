// Home.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../dialogs"

Item {
    id: homePage
    signal openSettingsRequested()
    signal startFaceRecognition()
    signal openNumericKeypad()
    signal openUserListRequested()
    signal openHistoryRequested()

    // Store last captured image for avatar
    property string lastCapturedImage: ""
    
    // WiFi connection status
    property bool wifiConnected: true

    // Expose function to deactivate camera from outside if needed
    function deactivateCamera() {
        // No camera on home page
    }

    // ====== dialogs ======
    DialogSuccess { id: dlgSuccess; anchors.centerIn: parent }
    DialogFailed  { id: dlgFailed;  anchors.centerIn: parent }

    // ====== background image ======
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: "qrc:/assets/images/background.png"
        fillMode: Image.PreserveAspectCrop
        z: 0
    }

    // ====== header with logo and title ======
    Rectangle {
        id: header
        width: parent.width
        height: 120
        color: "transparent"
        z: 1

        // Logo
        Image {
            id: logo
            source: "qrc:/assets/icons/logo.jpg"
            width: 80
            height: 80
            fillMode: Image.PreserveAspectFit
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.top: parent.top
            anchors.topMargin: 20
        }

        // Title text
        Column {
            anchors.left: logo.right
            anchors.right: wifiIndicator.left
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.verticalCenter: logo.verticalCenter

            Text {
                text: "WELCOME TO DUT"
                font.pixelSize: 32
                font.bold: true
                color: "#2C3E50"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
            Text {
                text: "ATTENDANCES"
                font.pixelSize: 32
                font.bold: true
                color: "#2C3E50"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
        }
        
        // WiFi Indicator (top right)
        Rectangle {
            id: wifiIndicator
            width: 60
            height: 60
            color: "transparent"
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.top: parent.top
            anchors.topMargin: 20
            
            Image {
                anchors.centerIn: parent
                source: wifiConnected ? "qrc:/assets/icons/wifi.png" : "qrc:/assets/icons/disconnectwifi.png"
                width: 40
                height: 40
                fillMode: Image.PreserveAspectFit
            }
        }
    }

    // ====== time display (đặt trước để có z cao hơn nav) ======
    Column {
        id: timeDisplay
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomArea.top      // kẹp lên trên nav bar
        anchors.bottomMargin: 20
        spacing: 8
        z: 3  // cao hơn bottomArea để không bị che

        Text {
            id: timeText
            text: Qt.formatTime(new Date(), "h:mm AP")
            color: "#2C3E50"
            font.pixelSize: 48
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
        }
        Text {
            id: dateText
            text: Qt.formatDate(new Date(), "dddd, MMMM dd")
            color: "#2C3E50"
            font.pixelSize: 24
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
        }
    }

    // ====== Network Error Notification (center) ======
    Rectangle {
        id: networkErrorNotification
        visible: !wifiConnected
        width: 400
        height: 120
        color: "#FFEBEE"
        border.color: "#F44336"
        border.width: 2
        radius: 15
        anchors.centerIn: parent
        z: 10
        
        // Drop shadow
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 3
            anchors.leftMargin: 3
            radius: 15
            color: "#20000000"
            z: -1
        }
        
        Row {
            anchors.centerIn: parent
            spacing: 20
            
            // Error icon
            Image {
                source: "qrc:/assets/icons/network_error.png"
                width: 60
                height: 60
                fillMode: Image.PreserveAspectFit
                anchors.verticalCenter: parent.verticalCenter
            }
            
            // Error text
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5
                
                Text {
                    text: "Network Error"
                    font.pixelSize: 24
                    font.bold: true
                    color: "#D32F2F"
                }
                
                Text {
                    text: "Please! Connect to wifi"
                    font.pixelSize: 18
                    color: "#666666"
                }
            }
        }
        
        // Blinking animation
        SequentialAnimation on opacity {
            running: !wifiConnected
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 1000 }
            NumberAnimation { to: 1.0; duration: 1000 }
        }
    }

    // ====== main content area ======
    Rectangle {
        id: mainContent
        anchors.top: header.bottom
        anchors.bottom: timeDisplay.top     // kẹp xuống dưới đồng hồ
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 20
        color: "transparent"
        z: 2

        // Face icon (left side)
        Rectangle {
            id: faceArea
            width: 160
            height: 160
            color: "transparent"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 60

            Image {
                id: faceIcon
                source: "qrc:/assets/icons/face.png"
                width: 140
                height: 140
                fillMode: Image.PreserveAspectFit
                anchors.centerIn: parent
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    console.log("Face recognition clicked")
                    homePage.startFaceRecognition()
                }
            }
        }

        // Numeric keypad (right side)
        Rectangle {
            id: numericArea
            width: 160
            height: 160
            color: "transparent"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 60

            Image {
                id: numericIcon
                source: "qrc:/assets/icons/numeric.png"
                width: 140
                height: 140
                fillMode: Image.PreserveAspectFit
                anchors.centerIn: parent
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    console.log("Numeric keypad clicked")
                    homePage.openNumericKeypad()
                }
            }
        }
    }

    // ====== bottom area with navigation ======
    Rectangle {
        id: bottomArea
        width: parent.width
        height: 100
        color: "transparent"
        anchors.bottom: parent.bottom
        z: 2

        // Bottom navigation bar
        Rectangle {
            id: navBar
            width: 350
            height: 70
            color: "white"
            border.color: "#BDC3C7"
            border.width: 2
            radius: 35
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20

            Row {
                anchors.centerIn: parent
                spacing: 80

                // User list icon
                Rectangle {
                    width: 50; height: 50; color: "transparent"
                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/assets/icons/user_list.png"
                        width: 40; height: 40; fillMode: Image.PreserveAspectFit
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("User list clicked")
                            homePage.openUserListRequested()
                        }
                    }
                }

                // Home icon
                Rectangle {
                    width: 50; height: 50; color: "transparent"
                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/assets/icons/system.png"
                        width: 40; height: 40; fillMode: Image.PreserveAspectFit
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("System settings clicked")
                            homePage.openSettingsRequested()
                        }
                    }
                }

                // History icon
                Rectangle {
                    width: 50; height: 50; color: "transparent"
                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/assets/icons/history.png"
                        width: 40; height: 40; fillMode: Image.PreserveAspectFit
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("History clicked")
                            homePage.openHistoryRequested()
                        }
                    }
                }
            }
        }
    }

    // ====== Timer for time updates ======
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            timeText.text = Qt.formatTime(new Date(), "h:mm AP")
            dateText.text = Qt.formatDate(new Date(), "dddd, MMMM dd")
        }
    }

    // ====== Backend signal connections ======
    Connections {
        target: backend
        function onServerConnectionTested(success, message) {
            console.log("Server connection test:", success, message)
        }
        function onWifiConnectedChanged() {
            homePage.wifiConnected = backend.getWifiConnected()
            console.log("WiFi status changed:", homePage.wifiConnected)
        }
    }
    
    // Update WiFi status on page load
    Component.onCompleted: {
        console.log("Home page completed")
        if (typeof backend !== "undefined") {
            homePage.wifiConnected = backend.getWifiConnected()
        }
    }

    // ====== Keyboard shortcuts for testing ======
    focus: true
    Keys.onReleased: (ev) => {
        if (ev.key === Qt.Key_S) dlgSuccess.openWith("Demo User", "Employee", "Hi 👋")
        if (ev.key === Qt.Key_F) dlgFailed.openWith("Unknown", "Employee", "Please try again")
    }

    // Handle page visibility changes
    onVisibleChanged: {
        console.log("Home page visibility:", visible)
        if (visible && typeof backend !== "undefined") {
            homePage.wifiConnected = backend.getWifiConnected()
        }
    }
}
