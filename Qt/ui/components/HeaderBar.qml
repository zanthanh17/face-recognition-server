import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: headerRoot
    width: parent.width
    height: 60
    color: "#2C3E50"

    property string title: "Face Recognition System"
    property string subtitle: ""
    property bool showBackButton: false
    property bool showUserMenu: true
    
    // Keep original properties for backward compatibility
    property alias logoSource: logo.source
    property bool wifiConnected: true
    property int wifiStrength: 3
    property url wifiIcon: wifiConnected ? "qrc:/assets/icons/wifi.png"
                                         : "qrc:/assets/icons/disconnectwifi.png"

    signal backClicked()
    signal userMenuClicked()
    
    // Keep original signals for backward compatibility
    signal leftClicked()
    signal rightClicked()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 20

        // Back button (optional)
        ToolButton {
            visible: showBackButton
            text: "←"
            font.pixelSize: 20
            onClicked: headerRoot.backClicked()
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40

            background: Rectangle {
                color: "transparent"
                border.color: parent.hovered ? "#3498DB" : "transparent"
                border.width: 1
                radius: 4
            }

            contentItem: Text {
                text: parent.text
                color: parent.hovered ? "#3498DB" : "#ECF0F1"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Logo area - keep original logo for compatibility
        Rectangle {
            width: 40
            height: 40
            color: "transparent"
            radius: 20

            Image {
                id: logo
                source: "qrc:/assets/icons/logo.jpg"
                fillMode: Image.PreserveAspectFit
                anchors.fill: parent
                MouseArea {
                    anchors.fill: parent
                    onClicked: headerRoot.leftClicked()
                }
            }
            
            // Fallback FR text if logo not available
            Text {
                anchors.centerIn: parent
                text: "FR"
                color: "#3498DB"
                font.pixelSize: 16
                font.bold: true
                visible: logo.status !== Image.Ready
            }
        }

        

        // Right side controls
        Row {
            spacing: 10
            visible: showUserMenu

            // WiFi status - keep original functionality
            Image {
                id: wifiImg
                source: headerRoot.wifiIcon
                fillMode: Image.PreserveAspectFit
                width: 32
                height: 32
                MouseArea {
                    anchors.fill: parent
                    onClicked: headerRoot.rightClicked()
                }
            }

            ToolButton {
                text: "👤"
                font.pixelSize: 16
                onClicked: headerRoot.userMenuClicked()
                width: 40
                height: 40

                background: Rectangle {
                    color: "transparent"
                    border.color: parent.hovered ? "#3498DB" : "transparent"
                    border.width: 1
                    radius: 4
                }
            }

            ToolButton {
                text: "⋮"
                font.pixelSize: 16
                onClicked: optionsMenu.open()
                width: 40
                height: 40

                background: Rectangle {
                    color: "transparent"
                    border.color: parent.hovered ? "#3498DB" : "transparent"
                    border.width: 1
                    radius: 4
                }

                Menu {
                    id: optionsMenu
                    y: parent.height

                    MenuItem {
                        text: "Settings"
                        onTriggered: console.log("Settings clicked")
                    }

                    MenuItem {
                        text: "About"
                        onTriggered: console.log("About clicked")
                    }

                    MenuSeparator {}

                    MenuItem {
                        text: "Exit"
                        onTriggered: Qt.quit()
                    }
                }
            }
        }
    }

    // Bottom border
    Rectangle {
        width: parent.width
        height: 1
        color: "#34495E"
        anchors.bottom: parent.bottom
    }
}
