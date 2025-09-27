// ui/pages/SettingAdmin.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"   // HeaderBar.qml

Item {
    id: adminPage
    // ---- Signals cho điều hướng ----
    signal backRequested()
    signal networkSettingsClicked()
    signal changePasswordClicked()
    signal monitorClicked()
    
    property bool wifiConnected: true // Will be set from parent
    
    // ===== Background =====
    Image {
        anchors.fill: parent
        source: "qrc:/assets/images/background.png"
        fillMode: Image.PreserveAspectCrop
        z: 0
    }

    // ===== Header =====
    Rectangle {
        id: headerSection
        width: parent.width; height: 80
        color: "transparent"; z: 1

        // Back
        Rectangle {
            width: 60; height: 60; color: "transparent"
            anchors.left: parent.left; anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            Image { anchors.centerIn: parent; source: "qrc:/assets/icons/back.png"; width: 40; height: 40; fillMode: Image.PreserveAspectFit }
            MouseArea { anchors.fill: parent; onClicked: adminPage.backRequested() }
        }

        // Title
        Text {
            anchors.centerIn: parent
            text: "SYSTEM SETTING"
            color: "#2C3E50"
            font.pixelSize: 32; font.bold: true
        }
    }

    // ===== Component item card tái dùng =====
    component SettingItem: Rectangle {
        id: card
        property url iconSource: ""
        property string title: ""
        signal clicked()

        width: 350
        height: 80
        radius: 40
        color: "white"
        border.color: "#E0E0E0"
        border.width: 2
        antialiasing: true

        Row {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            Image {
                source: card.iconSource
                width: 40
                height: 40
                fillMode: Image.PreserveAspectFit
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: card.title
                font.pixelSize: 20
                font.bold: true
                color: "#2C3E50"
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 40 - 20 - 40 - 20
            }

            Text {
                text: ">"
                font.pixelSize: 24
                color: "#BDC3C7"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: card.clicked()
        }
    }

    // ===== Danh sách mục =====
    Column {
        anchors.top: headerSection.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 50
        spacing: 30
        z: 1

        SettingItem {
            iconSource: "qrc:/assets/icons/network.png"
            title: "Network"
            onClicked: adminPage.networkSettingsClicked()
        }

        SettingItem {
            iconSource: "qrc:/assets/icons/password.png"
            title: "Change Password"
            onClicked: adminPage.changePasswordClicked()
        }

        SettingItem {
            iconSource: "qrc:/assets/icons/monitor.png"
            title: "Monitor"
            onClicked: adminPage.monitorClicked()
        }
    }
}
