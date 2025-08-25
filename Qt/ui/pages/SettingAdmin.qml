// ui/pages/SettingAdmin.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"   // HeaderBar.qml

Item {
    id: adminPage
    // ---- Signals cho điều hướng ----
    signal backRequested()
    signal editUserInfoClicked()
    signal networkSettingsClicked()
    signal historyClicked()
    signal monitorClicked()
    signal boxSettingsClicked()
    signal logsClicked()
    
    property bool wifiConnected: true // Will be set from parent

    // ===== Header =====
    HeaderBar {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        wifiConnected: adminPage.wifiConnected
    }

    // ===== Tiêu đề + avatar + nút back =====
    RowLayout {
        id: titleRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.margins: 12
        spacing: 8
        height: 56

        // nút back tròn
        ToolButton {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            background: Rectangle { radius: width/2; color: "#ECEFF4"; border.color: "#D2D7DE" }
            contentItem: Label {
                text: "\u2039" // ‹
                font.pixelSize: 22
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: "#333"
            }
            onClicked: adminPage.backRequested()
        }

        // avatar + greeting
        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                width: 40; height: 40; radius: 20
                color: "#EAF2FF"
                border.color: "#D2D7DE"
                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: "qrc:/assets/images/user.png"  // thay bằng ảnh của bạn
                    fillMode: Image.PreserveAspectFit
                    clip: true
                }
            }

            Label {
                text: "Hello, Staff"
                font.pixelSize: 20
                font.bold: true
                color: "#333"
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    // ===== Component item card tái dùng =====
    component SettingItem: Rectangle {
        id: card
        property url iconSource: ""
        property string title: ""
        signal clicked()

        Layout.fillWidth: true
        height: 74
        radius: 16
        color: "#FFFFFF"
        border.color: "#C9CED6"
        antialiasing: true

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Image {
                source: card.iconSource
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                fillMode: Image.PreserveAspectFit
            }

            Label {
                text: card.title
                font.pixelSize: 16
                font.bold: true
                color: "#333"
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
            }

            Label {
                text: "\u203A" // ›
                font.pixelSize: 20
                color: "#333"
                verticalAlignment: Text.AlignVCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.clicked()
        }
    }

    // ===== Danh sách mục =====
    ColumnLayout {
        anchors.top: titleRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        spacing: 14

        SettingItem {
            iconSource: "qrc:/assets/icons/edit_user.png"
            title: "Edit User Info"
            onClicked: adminPage.editUserInfoClicked()
        }

        SettingItem {
            iconSource: "qrc:/assets/icons/network.png"
            title: "Network Settings"
            onClicked: adminPage.networkSettingsClicked()
        }

        SettingItem {
            iconSource: "qrc:/assets/icons/history.png"
            title: "History IN/OUT"
            onClicked: adminPage.historyClicked()
        }

        SettingItem {
            iconSource: "qrc:/assets/icons/monitor.png"
            title: "Monitor"
            onClicked: adminPage.monitorClicked()
        }

        Item { Layout.fillHeight: true }
    }
}
