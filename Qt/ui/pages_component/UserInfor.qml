import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Item {
    id: page

    // Inputs
    property string userId: ""
    property string userName: ""
    property string userDepartment: ""
    property url userAvatar: "qrc:/assets/images/user.png"
    property bool wifiConnected: true // Will be set from parent

    // Signals
    signal backRequested()
    signal editRequested(string userId)
    signal openCaptureRequested(string userId, string userName, string userDepartment, url currentAvatar)

    HeaderBar {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        wifiConnected: page.wifiConnected
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
            onClicked: page.backRequested()
        }

        Label {
            text: "User Info"
            font.pixelSize: 20
            font.bold: true
            color: "#333"
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
        }

        Button {
            id: editBtn
            text: "Edit"
            background: Rectangle { radius: 8; color: "#2E7D32" }
            contentItem: Label { text: editBtn.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            onClicked: page.openCaptureRequested(page.userId, page.userName, page.userDepartment, page.userAvatar)
        }
    }

    ColumnLayout {
        id: body
        anchors.top: titleRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        spacing: 16

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 120; height: 120; radius: 60
            color: "#EAF2FF"
            border.color: "#D2D7DE"
            Image {
                anchors.fill: parent
                source: page.userAvatar
                fillMode: Image.PreserveAspectFill
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Label { text: page.userName; font.bold: true; font.pixelSize: 20; color: "#333" }
            Label { text: "ID: " + page.userId; color: "#555" }
            Label { text: "Department: " + page.userDepartment; color: "#555" }
        }

        Item { Layout.fillHeight: true }
    }
} 
