import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"   // HeaderBar.qml + Keyboard.qml

Item {
    id: settingPage
    signal backRequested()
    signal passwordAuthenticated()
    
    property bool wifiConnected: true // Will be set from parent

    HeaderBar {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        wifiConnected: settingPage.wifiConnected
    }

    RowLayout {
        id: titleRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.margins: 12
        spacing: 8
        height: 48

        ToolButton {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            background: Rectangle { radius: width/2; color: "#ECEFF4"; border.color: "#D2D7DE" }
            contentItem: Label {
                text: "\u2039"
                font.pixelSize: 22
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: "#333"
            }
            onClicked: settingPage.backRequested()
        }

        Label {
            text: "Setting"
            font.pixelSize: 20
            font.bold: true
            color: "#333"
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Image {
        id: authButton
        anchors {
            left: parent.left
            right: parent.right
            top: titleRow.bottom   // Đặt ngay dưới hàng tiêu đề
            leftMargin: 16
            rightMargin: 16
            topMargin: 24
        }
        source: "qrc:/assets/icons/btn_auth.png"
        fillMode: Image.PreserveAspectFit

        // Clickable
        signal authenticationClicked()
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                authButton.authenticationClicked()
                passwordDialogLoader.active = true
            }
        }
    }


    // Password Dialog
    Loader {
        id: passwordDialogLoader
        anchors.fill: parent
        source: "qrc:/ui/dialogs/dialog_password_auth.qml"
        active: false

        onLoaded: {
            if (item) {
                item.cancelClicked.connect(function() {
                    item.hide()
                    passwordDialogLoader.active = false
                })
                item.doneClicked.connect(function() {
                    var enteredPassword = item.password
                    if (enteredPassword === "123456") {
                        console.log("Password correct!")
                        item.hide()
                        passwordDialogLoader.active = false
                        settingPage.passwordAuthenticated() // Emit signal for successful authentication
                    } else {
                        console.log("Incorrect password!")
                        // Show error message
                        errorMessage.visible = true
                        errorTimer.start()
                    }
                })
            }
        }
    }

    // Error message
    Rectangle {
        id: errorMessage
        anchors.centerIn: parent
        width: 300
        height: 60
        radius: 8
        color: "#e74c3c"
        border.color: "#c0392b"
        border.width: 1
        visible: false

        Text {
            anchors.centerIn: parent
            text: "Incorrect password"
            color: "#ffffff"
            font.pixelSize: 16
            font.bold: true
        }

        Timer {
            id: errorTimer
            interval: 2000
            onTriggered: errorMessage.visible = false
        }
    }

    function back() {
        if (settingsPage.parent && settingsPage.parent.StackView) {
            // no-op, main handles stack; keep function for external hookup if needed
        }
        settingsPage.backRequested()
    }
}
