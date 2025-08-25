import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: parent ? parent.width : 400
    height: 40

    property alias logoSource: logo.source
    property bool wifiConnected: true         // trạng thái wifi
    property int wifiStrength: 3               // 1..3 nếu cần hiển thị cường độ
    property url wifiIcon: wifiConnected ? "qrc:/assets/icons/wifi.png"
                                         : "qrc:/assets/icons/disconnectwifi.png"

    signal leftClicked()
    signal rightClicked()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 6

        // Logo bên trái
        Image {
            id: logo
            source: "qrc:/assets/icons/logo.jpg"
            fillMode: Image.PreserveAspectFit
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            MouseArea {
                anchors.fill: parent
                onClicked: root.leftClicked()
            }
        }

        // Đồng hồ giữa
        Label {
            id: clockLabel
            text: Qt.formatTime(new Date(), "h:mm AP")
            font.bold: true
            font.pointSize: 14
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clockLabel.text = Qt.formatTime(new Date(), "h:mm AP")
        }

        // Icon wifi bên phải
        Image {
            id: wifiImg
            source: root.wifiIcon
            fillMode: Image.PreserveAspectFit
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            MouseArea {
                anchors.fill: parent
                onClicked: root.rightClicked()
            }
        }
    }
}
