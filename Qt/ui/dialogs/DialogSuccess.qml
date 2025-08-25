import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Popup {
    id: dlg
    modal: true
    focus: true
    padding: 0
    Overlay.modal: Rectangle { color: "#00000066" }

    property string empName: "Phạm Quang Tài"
    property string empTitle: "Intern"
    property url    avatar: "qrc:/assets/images/user.png"
    property string message: "Hi, " + empName + "\nHope your day is going smoothly 😊"
    property int    autoCloseMs: 2500
    signal done(string result)

    width: 340
    background: Rectangle { radius: 18; color: "white"; border.color: "#EAEAEA" }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 20; spacing: 12

        // icon tròn mờ + check
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 80; height: 80
            Rectangle { anchors.fill: parent; radius: width/2; color: "#2ECC7077" }
            Image {
                anchors.centerIn: parent
                source: "qrc:/assets/icons/success-check.png"
                width: 56; height: 56; fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
            }
            Text { anchors.centerIn: parent; text: "✓"; font.pixelSize: 42; color: "#1E7E34";
                   visible: !parent.children[1].visible }
        }

        // Title "Successful"
        Label {
            text: "Successful"
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: 22; font.bold: true; color: "#1E7E34"
        }

        // ===== HÀNG NGANG: avatar + (title, name) =====
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            // Avatar tròn có viền xanh
            Rectangle {
                width: 56; height: 56; radius: 28
                color: "transparent"
                border.color: "#2ECC71"; border.width: 2
                Image {
                    anchors.fill: parent
                    source: dlg.avatar; fillMode: Image.PreserveAspectFill
                }
            }

            // Chức danh nhỏ ở trên, tên đậm ở dưới
            Column {
                spacing: 2
                Label { text: dlg.empTitle; color: "#6c757d"; font.pixelSize: 13 }
                Label { text: dlg.empName;  font.pixelSize: 20; font.bold: true; color: "#000" }
            }
        }

        // Bong bóng lời chào
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 300; radius: 12; color: "#F3FFF6"; border.color: "#2ECC71"; border.width: 2
            Text {
                anchors.fill: parent; anchors.margins: 10
                wrapMode: Text.WordWrap
                text: dlg.message; color: "#0F5132"; font.pixelSize: 14
            }
        }

        Item { Layout.fillHeight: true }
    }

    function openWith(name, title, msg, avatarUrl) {
        empName = name || empName
        empTitle = title || ""
        message = msg || ("Hi, " + empName + "\nHope your day is going smoothly 😊")
        if (avatarUrl) avatar = avatarUrl
        open()
    }
    
    function openWithCaptureImage(name, title, msg, captureImageData) {
        empName = name || empName
        empTitle = title || ""
        message = msg || ("Hi, " + empName + "\nHope your day is going smoothly 😊")
        if (captureImageData) {
            // captureImageData is already a base64 string, just add the data URL prefix
            avatar = "data:image/jpeg;base64," + captureImageData
        }
        open()
    }

    onOpened: t.restart()
    onClosed: done("success")
    Timer { id: t; interval: dlg.autoCloseMs; repeat: false; onTriggered: dlg.close() }
}
