// NumericKeypad.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: numericKeypadPage
    signal backToHomeRequested()
    
    // Background image
    Image {
        anchors.fill: parent
        source: "qrc:/assets/images/background.png"
        fillMode: Image.PreserveAspectCrop
        z: 0
    }
    
    // Header with back button and title
    Rectangle {
        id: header
        width: parent.width
        height: 80
        color: "transparent"
        z: 1
        
        // Back button
        Rectangle {
            width: 60
            height: 60
            color: "transparent"
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            
            Image {
                anchors.centerIn: parent
                source: "qrc:/assets/icons/back.png"
                width: 40
                height: 40
                fillMode: Image.PreserveAspectFit
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: numericKeypadPage.backToHomeRequested()
            }
        }
        
        // Title
        Text {
            anchors.centerIn: parent
            text: "PASSWORD"
            color: "#2C3E50"
            font.pixelSize: 32
            font.bold: true
        }
    }
    
    // Password input field
    Rectangle {
        id: passwordField
        width: 300
        height: 60
        color: "white"
        border.color: "#BDC3C7"
        border.width: 2
        radius: 8
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: header.bottom
        anchors.topMargin: 40
        z: 1
        
        TextInput {
            id: passwordInput
            anchors.centerIn: parent
            font.pixelSize: 24
            horizontalAlignment: Text.AlignHCenter
            maximumLength: 20
            echoMode: TextInput.Password
            passwordCharacter: "●"
            inputMethodHints: Qt.ImhDigitsOnly
        }
    }
    
    // Numeric keypad - occupies 2/3 of screen
    Rectangle {
        id: keypadArea
        width: parent.width * 0.95
        height: parent.height * 0.75
        color: "transparent"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        z: 1
        
        Grid {
            id: keypadGrid
            columns: 3
            spacing: 15
            anchors.centerIn: parent
            
            // Numbers 1-9
            Repeater {
                model: ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
                
                Rectangle {
                    width: 100
                    height: 100
                    color: "white"
                    border.color: "#E0E0E0"
                    border.width: 1
                    radius: 10
                    
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 40
                        font.bold: true
                        color: "#2C3E50"
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            passwordInput.text += modelData
                        }
                        
                        onPressed: parent.color = "#F0F0F0"
                        onReleased: parent.color = "white"
                    }
                }
            }
            
            // Bottom row: Remove, 0, Enter
            Rectangle {
                width: 100
                height: 100
                color: "white"
                border.color: "#E0E0E0"
                border.width: 1
                radius: 10
                
                Image {
                    anchors.centerIn: parent
                    source: "qrc:/assets/icons/remove.png"
                    width: 50
                    height: 50
                    fillMode: Image.PreserveAspectFit
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (passwordInput.text.length > 0) {
                            passwordInput.text = passwordInput.text.slice(0, -1)
                        }
                    }
                    
                    onPressed: parent.color = "#F0F0F0"
                    onReleased: parent.color = "white"
                }
            }
            
            Rectangle {
                width: 100
                height: 100
                color: "white"
                border.color: "#E0E0E0"
                border.width: 1
                radius: 10
                
                Text {
                    anchors.centerIn: parent
                    text: "0"
                    font.pixelSize: 40
                    font.bold: true
                    color: "#2C3E50"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        passwordInput.text += "0"
                    }
                    
                    onPressed: parent.color = "#F0F0F0"
                    onReleased: parent.color = "white"
                }
            }
            
            Rectangle {
                width: 100
                height: 100
                color: "#007AFF"
                border.color: "#007AFF"
                border.width: 1
                radius: 10
                
                Image {
                    anchors.centerIn: parent
                    source: "qrc:/assets/icons/enter.png"
                    width: 50
                    height: 50
                    fillMode: Image.PreserveAspectFit
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Password entered:", passwordInput.text)
                        // Add your authentication logic here
                        // For example: backend.authenticateWithPassword(passwordInput.text)
                    }
                    
                    onPressed: parent.color = "#0056CC"
                    onReleased: parent.color = "#007AFF"
                }
            }
        }
    }
}