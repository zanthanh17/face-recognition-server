import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: passwordDialog
    anchors.fill: parent

    // Properties
    property bool showPassword: false
    property bool showNumbers: false

    // Semi-transparent background overlay
    Rectangle {
        anchors.fill: parent
        color: "#80000000"
        opacity: 0.5
    }

    // Main dialog container
    Rectangle {
        id: dialogContainer
        width: Math.min(parent.width * 0.9, 400)
        height: 200
        radius: 8
        color: "#ffffff"
        border.color: "#000000"
        border.width: 1
        anchors.centerIn: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // Title
            Text {
                text: "Enter password"
                font.pixelSize: 18
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            // Password input field
            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: 4
                border.color: "#cccccc"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    TextInput {
                        id: passwordInput
                        Layout.fillWidth: true
                        text: ""
                        font.pixelSize: 16
                        echoMode: showPassword ? TextInput.Normal : TextInput.Password
                        verticalAlignment: TextInput.AlignVCenter
                        focus: true

                        // Show keyboard when focused
                        onFocusChanged: {
                            if (focus) {
                                Qt.inputMethod.show()
                            }
                        }
                    }

                    // Eye icon to toggle password visibility
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 4
                        color: showPassword ? "#3498db" : "#e0e0e0"
                        border.color: "#cccccc"
                        border.width: 1

                        Text {
                            text: showPassword ? "👁" : "👁‍🗨"
                            anchors.centerIn: parent
                            font.pixelSize: 14
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: showPassword = !showPassword
                        }
                    }
                }
            }

            // Buttons row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Button {
                    text: "Cancel"
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: "#e74c3c"
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 14
                    }
                    onClicked: passwordDialog.cancelClicked()
                }

                Button {
                    text: "Done"
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: "#3498db"
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 14
                    }
                    onClicked: passwordDialog.doneClicked()
                }
            }
        }
    }

    // Virtual keyboard
    Rectangle {
        id: keyboard
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 200
        color: "#f0f0f0"
        border.color: "#cccccc"
        border.width: 1

        // Letter keyboard
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4
            visible: !showNumbers

            // Top row: Q W E R T Y U I O P
            RowLayout {
                Layout.fillWidth: true
                spacing: 2
                Repeater {
                    model: ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
                    delegate: Button {
                        text: modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 35
                        background: Rectangle {
                            color: "#ffffff"
                            border.color: "#cccccc"
                            border.width: 1
                            radius: 2
                        }
                        onClicked: passwordInput.insert(passwordInput.cursorPosition, text)
                    }
                }
            }

            // Middle row: A S D F G H J K L
            RowLayout {
                Layout.fillWidth: true
                spacing: 2
                Item { Layout.preferredWidth: 20 }
                Repeater {
                    model: ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
                    delegate: Button {
                        text: modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 35
                        background: Rectangle {
                            color: "#ffffff"
                            border.color: "#cccccc"
                            border.width: 1
                            radius: 2
                        }
                        onClicked: passwordInput.insert(passwordInput.cursorPosition, text)
                    }
                }
                Item { Layout.preferredWidth: 20 }
            }

            // Bottom row: Shift Z X C V B N M Backspace
            RowLayout {
                Layout.fillWidth: true
                spacing: 2
                Button {
                    text: "⇧"
                    Layout.preferredWidth: 50
                    Layout.preferredHeight: 35
                    background: Rectangle {
                        color: "#ffffff"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 2
                    }
                }
                Repeater {
                    model: ["Z", "X", "C", "V", "B", "N", "M"]
                    delegate: Button {
                        text: modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 35
                        background: Rectangle {
                            color: "#ffffff"
                            border.color: "#cccccc"
                            border.width: 1
                            radius: 2
                        }
                        onClicked: passwordInput.insert(passwordInput.cursorPosition, text)
                    }
                }
                Button {
                    text: "⌫"
                    Layout.preferredWidth: 50
                    Layout.preferredHeight: 35
                    background: Rectangle {
                        color: "#ffffff"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 2
                    }
                    onClicked: passwordInput.remove(passwordInput.cursorPosition - 1, passwordInput.cursorPosition)
                }
            }

            // Bottom row: 123 Space Return
            RowLayout {
                Layout.fillWidth: true
                spacing: 2
                Button {
                    text: "123"
                    Layout.preferredWidth: 50
                    Layout.preferredHeight: 35
                    background: Rectangle {
                        color: "#3498db"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 2
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: showNumbers = true
                }
                Button {
                    text: "Space"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    background: Rectangle {
                        color: "#ffffff"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 2
                    }
                    onClicked: passwordInput.insert(passwordInput.cursorPosition, " ")
                }
                Button {
                    text: "Return"
                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 35
                    background: Rectangle {
                        color: "#ffffff"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 2
                    }
                    onClicked: passwordDialog.doneClicked()
                }
            }
        }

        // Number keyboard
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4
            visible: showNumbers

            // Top row: 1 2 3 4 5 6 7 8 9 0
            RowLayout {
                Layout.fillWidth: true
                spacing: 2
                Repeater {
                    model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
                    delegate: Button {
                        text: modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 35
                        background: Rectangle {
                            color: "#ffffff"
                            border.color: "#cccccc"
                            border.width: 1
                            radius: 2
                        }
                        onClicked: passwordInput.insert(passwordInput.cursorPosition, text)
                    }
                }
            }

            // Middle row: - / : ; ( ) $ & @ "
            RowLayout {
                Layout.fillWidth: true
                spacing: 2
                Repeater {
                    model: ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""]
                    delegate: Button {
                        text: modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 35
                        background: Rectangle {
                            color: "#ffffff"
                            border.color: "#cccccc"
                            border.width: 1
                            radius: 2
                        }
                        onClicked: passwordInput.insert(passwordInput.cursorPosition, text)
                    }
                }
            }

            // Bottom row: . , ? ! ' Backspace
            RowLayout {
                Layout.fillWidth: true
                spacing: 2
                Repeater {
                    model: [".", ",", "?", "!", "'"]
                    delegate: Button {
                        text: modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 35
                        background: Rectangle {
                            color: "#ffffff"
                            border.color: "#cccccc"
                            border.width: 1
                            radius: 2
                        }
                        onClicked: passwordInput.insert(passwordInput.cursorPosition, text)
                    }
                }
                Button {
                    text: "⌫"
                    Layout.preferredWidth: 50
                    Layout.preferredHeight: 35
                    background: Rectangle {
                        color: "#ffffff"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 2
                    }
                    onClicked: passwordInput.remove(passwordInput.cursorPosition - 1, passwordInput.cursorPosition)
                }
            }

            // Bottom row: ABC Space Return
            RowLayout {
                Layout.fillWidth: true
                spacing: 2
                Button {
                    text: "ABC"
                    Layout.preferredWidth: 50
                    Layout.preferredHeight: 35
                    background: Rectangle {
                        color: "#3498db"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 2
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: showNumbers = false
                }
                Button {
                    text: "Space"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    background: Rectangle {
                        color: "#ffffff"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 2
                    }
                    onClicked: passwordInput.insert(passwordInput.cursorPosition, " ")
                }
                Button {
                    text: "Return"
                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 35
                    background: Rectangle {
                        color: "#ffffff"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 2
                    }
                    onClicked: passwordDialog.doneClicked()
                }
            }
        }
    }

    // API
    signal cancelClicked()
    signal doneClicked()

    // Public properties
    property string password: passwordInput.text

    // Functions
    function show() {
        passwordDialog.visible = true
        passwordInput.focus = true
        passwordInput.text = ""
        showPassword = false
        showNumbers = false
    }

    function hide() {
        passwordDialog.visible = false
        Qt.inputMethod.hide()
    }
}
