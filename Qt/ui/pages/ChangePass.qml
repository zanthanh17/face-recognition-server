// ChangePass.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: changePassPage
    signal backRequested()
    
    property bool wifiConnected: true // Will be set from parent
    property string currentPassword: ""
    property string newPassword: ""
    property bool isCurrentPasswordMode: true // true = entering current password, false = entering new password
    property bool showSuccessMessage: false
    
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
                onClicked: changePassPage.backRequested()
            }
        }
        
        // Title
        Text {
            anchors.centerIn: parent
            text: "CHANGE PASSWORD"
            color: "#2C3E50"
            font.pixelSize: 28
            font.bold: true
        }
    }
    
    // Password input fields
    Column {
        id: passwordFields
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: header.bottom
        anchors.topMargin: 30
        spacing: 20
        z: 1
        
        // Current Password Field
        Column {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            
            Text {
                text: "Current Password"
                color: "#2C3E50"
                font.pixelSize: 16
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Rectangle {
                id: currentPasswordField
                width: 300
                height: 60
                color: isCurrentPasswordMode ? "#E3F2FD" : "white"
                border.color: isCurrentPasswordMode ? "#2196F3" : "#BDC3C7"
                border.width: isCurrentPasswordMode ? 3 : 2
                radius: 8
                anchors.horizontalCenter: parent.horizontalCenter
                
                Text {
                    anchors.centerIn: parent
                    text: "●".repeat(currentPassword.length)
                    font.pixelSize: 24
                    color: "#2C3E50"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        isCurrentPasswordMode = true
                    }
                }
            }
        }
        
        // New Password Field
        Column {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            
            Text {
                text: "New Password"
                color: "#2C3E50"
                font.pixelSize: 16
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Rectangle {
                id: newPasswordField
                width: 300
                height: 60
                color: !isCurrentPasswordMode ? "#E3F2FD" : "white"
                border.color: !isCurrentPasswordMode ? "#2196F3" : "#BDC3C7"
                border.width: !isCurrentPasswordMode ? 3 : 2
                radius: 8
                anchors.horizontalCenter: parent.horizontalCenter
                
                Text {
                    anchors.centerIn: parent
                    text: "●".repeat(newPassword.length)
                    font.pixelSize: 24
                    color: "#2C3E50"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        isCurrentPasswordMode = false
                    }
                }
            }
        }
    }
    
    // Success Message Overlay
    // Success Message Overlay
Rectangle {
    id: successOverlay
    visible: showSuccessMessage
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.7)   // <— fixed
    z: 100

    Rectangle {
        width: 300
        height: 200
        color: "white"
        radius: 15
        anchors.centerIn: parent

        Column {
            anchors.centerIn: parent
            spacing: 20

            Image {
                source: "qrc:/assets/icons/success-check.png"
                width: 60
                height: 60
                anchors.horizontalCenter: parent.horizontalCenter
                fillMode: Image.PreserveAspectFit
            }

            Text {
                text: "Password Changed\nSuccessfully!"
                color: "#27AE60"
                font.pixelSize: 18
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    Timer {
        id: successTimer
        interval: 2000
        running: showSuccessMessage
        onTriggered: {
            showSuccessMessage = false
            changePassPage.backRequested()
        }
    }
}

    
    // Numeric keypad - occupies 2/3 of screen
    Rectangle {
        id: keypadArea
        width: parent.width * 0.95
        height: parent.height * 0.55
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
                            if (isCurrentPasswordMode) {
                                if (currentPassword.length < 20) {
                                    currentPassword += modelData
                                }
                            } else {
                                if (newPassword.length < 20) {
                                    newPassword += modelData
                                }
                            }
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
                        if (isCurrentPasswordMode) {
                            if (currentPassword.length > 0) {
                                currentPassword = currentPassword.slice(0, -1)
                            }
                        } else {
                            if (newPassword.length > 0) {
                                newPassword = newPassword.slice(0, -1)
                            }
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
                        if (isCurrentPasswordMode) {
                            if (currentPassword.length < 20) {
                                currentPassword += "0"
                            }
                        } else {
                            if (newPassword.length < 20) {
                                newPassword += "0"
                            }
                        }
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
                        if (isCurrentPasswordMode) {
                            // Verify current password
                            if (currentPassword.length > 0) {
                                console.log("Verifying current password:", currentPassword)
                                let isValid = backend.verifyCurrentPassword(currentPassword)
                                if (isValid) {
                                    // Switch to new password mode
                                    isCurrentPasswordMode = false
                                } else {
                                    // Show error - incorrect current password
                                    console.log("Incorrect current password")
                                    currentPassword = ""
                                }
                            }
                        } else {
                            // Change to new password
                            if (newPassword.length > 0 && currentPassword.length > 0) {
                                console.log("Changing password from", currentPassword, "to", newPassword)
                                let success = backend.changePassword(currentPassword, newPassword)
                                if (success) {
                                    // Show success message
                                    showSuccessMessage = true
                                } else {
                                    // Show error
                                    console.log("Failed to change password")
                                    currentPassword = ""
                                    newPassword = ""
                                    isCurrentPasswordMode = true
                                }
                            }
                        }
                    }
                    
                    onPressed: parent.color = "#0056CC"
                    onReleased: parent.color = "#007AFF"
                }
            }
        }
    }
}