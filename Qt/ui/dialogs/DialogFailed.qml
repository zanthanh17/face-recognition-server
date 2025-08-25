import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Popup {
    id: dlg
    modal: true
    focus: true
    padding: 0
    Overlay.modal: Rectangle { color: "#00000066" }

    // API
    property string name: "Unknown"
    property string message: "Unknown!\nPlease scan face again 🥲"
    property url    avatar: "qrc:/assets/images/user.png"
    property int    autoCloseMs: 2500
    signal done(string result)

    width: 340
    background: Rectangle { radius: 18; color: "white"; border.color: "#F0D2D5" }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 20; spacing: 12

        // icon tròn mờ + dấu X
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 80; height: 80
            Rectangle { anchors.fill: parent; radius: width/2; color: "#E0313177" }
            Image {
                anchors.centerIn: parent
                source: "qrc:/assets/icons/portrait-circle.png"
                width: 56; height: 56; fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
            }
            Text { anchors.centerIn: parent; text: "✗"; font.pixelSize: 42; color: "#B02A37";
                   visible: !parent.children[1].visible }
        }

        // Title
        Label {
            text: "Login failed"
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: 22; font.bold: true; color: "#B02A37"
        }

        // ===== HÀNG NGANG: avatar + tên =====
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            // Avatar tròn viền đỏ
            Rectangle {
                width: 56; height: 56; radius: 28
                color: "transparent"
                border.color: "#DC3545"; border.width: 2
                Image {
                    anchors.fill: parent
                    source: dlg.avatar; fillMode: Image.PreserveAspectFill
                }
            }

            // Tên (Unknown)
            Label {
                text: dlg.name
                font.pixelSize: 20; font.bold: true; color: "#B02A37"
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Bong bóng thông báo
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 300; radius: 12
            color: "#FFF5F5"; border.color: "#F5C2C7"; border.width: 2
            Text {
                anchors.fill: parent; anchors.margins: 10
                wrapMode: Text.WordWrap
                text: dlg.message; color: "#842029"; font.pixelSize: 14
            }
        }

        Item { Layout.fillHeight: true }
    }

    // Helper
    function openWith(nameText, msg, avatarUrl) {
        name = nameText || "Unknown"
        message = msg || "Unknown!\nPlease scan face again 🥲"
        if (avatarUrl) avatar = avatarUrl
        open()
    }
    
    function openWithCaptureImage(nameText, title, msg, captureImageData) {
        name = nameText || "Unknown"
        message = msg || "Unknown!\nPlease scan face again 🥲"
        if (captureImageData) {
            // captureImageData is already a base64 string, just add the data URL prefix
            avatar = "data:image/jpeg;base64," + captureImageData
        }
        open()
    }

    onOpened: t.restart()
    onClosed: done("failed")
    Timer { id: t; interval: dlg.autoCloseMs; repeat: false; onTriggered: dlg.close() }
}
