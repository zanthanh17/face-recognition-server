// ui/pages/EditUser.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"    // HeaderBar.qml + Keyboard.qml

Item {
    id: page
    signal backRequested()
    signal userClicked(string userId, string userName, string userDepartment, url userAvatar)

    property bool keyboardOpened: false
    property int filteredCount: 0
    property bool wifiConnected: true // Will be set from parent

    function recomputeFilteredCount() {
        const key = (searchField.text || "").toLowerCase()
        let n = 0
        if (backend.users) {
            // console.log("Recomputing filtered count, backend.users.length:", backend.users.length) // Disabled for RPi optimization
            for (let i = 0; i < backend.users.length; ++i) {
                const it = backend.users[i]
                // console.log("Checking user:", it.name, "id:", it.id) // Disabled for RPi optimization
                const ok =
                    key.length === 0 ||
                    it.name.toLowerCase().indexOf(key) !== -1 ||
                    it.id.toString().toLowerCase().indexOf(key)  !== -1
                if (ok) n++
            }
        } else {
            // console.log("backend.users is null or undefined") // Disabled for RPi optimization
        }
        // console.log("Filtered count:", n, "key:", key) // Disabled for RPi optimization
        filteredCount = n
    }
    
    function loadUserAvatar(userId, userName, avatarImage) {
        // console.log("Loading avatar for user:", userName, "ID:", userId) // Disabled for RPi optimization
        // Load user image from server
        var userImageData = backend.getUserImage(userId)
        // console.log("getUserImage result:", typeof userImageData, "length:", userImageData ? userImageData.length : "null") // Disabled for RPi optimization
        if (userImageData && userImageData.length > 0) {
            avatarImage.source = "data:image/jpeg;base64," + userImageData
            // console.log("✅ Set server image for:", userName) // Disabled for RPi optimization
        } else {
            avatarImage.source = "qrc:/assets/images/user.png"
            // console.log("❌ Using default image for:", userName) // Disabled for RPi optimization
        }
    }

    HeaderBar {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        wifiConnected: page.wifiConnected
    }

    // Header section - đơn giản và cân xứng
    RowLayout {
        id: headerSection
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.margins: 12
        height: 40
        spacing: 8

        // Back button đơn giản
        Image {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            source: "qrc:/assets/icons/btn_back.png"
            fillMode: Image.PreserveAspectFit
            
            MouseArea {
                anchors.fill: parent
                onClicked: page.backRequested()
            }
        }

        // Title
        Label {
            text: "Edit Face"
            font.pixelSize: 18
            font.bold: true
            color: "#333333"
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Main content - layout đơn giản và cân xứng
    ColumnLayout {
        id: body
        anchors.top: headerSection.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        spacing: 12

        // Search section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Label { 
                text: "Find User"
                font.pixelSize: 14
                color: "#333333"
            }

            // Search input đơn giản
            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 6
                color: "#FFFFFF"
                border.color: "#E0E0E0"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    Label {
                        text: "🔍"
                        font.pixelSize: 14
                        color: "#666666"
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Type name or ID..."
                        placeholderTextColor: "#999999"
                        readOnly: true
                        font.pixelSize: 14
                        color: "#333333"
                        background: Rectangle { color: "transparent" }
                        
                        Keys.onPressed: (e)=> e.accepted = true
                        Keys.onReleased:(e)=> e.accepted = true
                        onTextChanged: page.recomputeFilteredCount()

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                searchField.forceActiveFocus()
                                page.keyboardOpened = true
                            }
                        }
                    }
                }
            }
        }

        // Users section
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            Label { 
                text: "Users"
                font.pixelSize: 14
                color: "#333333"
            }

            // User list đơn giản
            ListView {
                id: listView
                visible: page.filteredCount > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6

                model: backend.users || []

                Component.onCompleted: {
                    page.recomputeFilteredCount()
                    backend.loadUsersFromBackend()
                }
                
                Connections {
                    target: backend
                    function onUsersChanged() {
                        // console.log("Users changed, backend.users.length:", backend.users ? backend.users.length : 0) // Disabled for RPi optimization
                        page.recomputeFilteredCount()
                    }
                }

                delegate: Item {
                    width: listView.width
                    height: visible ? 56 : 0

                    property string key: searchField.text.toLowerCase()
                    visible: key.length === 0
                             || modelData.name.toLowerCase().indexOf(key) !== -1
                             || modelData.id.toString().toLowerCase().indexOf(key)  !== -1

                    // User card đơn giản
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 48
                        radius: 6
                        color: "#FFFFFF"
                        border.color: "#E0E0E0"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 0

                            // Avatar đơn giản
                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: "#F5F5F5"
                                border.color: "#E0E0E0"
                                border.width: 1
                                
                                Image { 
                                    id: userAvatar
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    
                                    
                                    Component.onCompleted: {
                                        // console.log("Avatar Component.onCompleted for:", modelData ? modelData.name : "unknown") // Disabled for RPi optimization
                                        if (modelData && modelData.id) {
                                            // console.log("Calling loadUserAvatar for:", modelData.name, "ID:", modelData.id) // Disabled for RPi optimization
                                            loadUserAvatar(modelData.id, modelData.name, userAvatar)
                                        } else {
                                            // console.log("No modelData or modelData.id") // Disabled for RPi optimization
                                        }
                                    }
                                }
                                
                                // Fallback placeholder
                                Rectangle {
                                    id: placeholderAvatar
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    radius: 18
                                    visible: userAvatar.status !== Image.Ready
                                    color: "#E0E0E0"
                                    
                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData ? modelData.name.charAt(0).toUpperCase() : ""
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "#666666"
                                    }
                                }
                            }

                            // User info sát bên trái avatar
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignLeft
                                spacing: 2

                                Label { 
                                    text: modelData.name
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#333333"
                                    horizontalAlignment: Text.AlignLeft
                                }
                                
                                Label { 
                                    text: modelData.position || "Employee"
                                    font.pixelSize: 12
                                    color: "#666666"
                                    horizontalAlignment: Text.AlignLeft
                                }
                            }

                            // Arrow sát bên phải
                            Label { 
                                text: "→"
                                font.pixelSize: 16
                                color: "#666666"
                                verticalAlignment: Text.AlignVCenter
                                Layout.alignment: Qt.AlignRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var avatarUrl = userAvatar.source
                                page.userClicked(modelData.id.toString(), modelData.name, modelData.position || "Employee", avatarUrl)
                            }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar { 
                    policy: ScrollBar.AsNeeded
                }
                footer: Item { height: 8; width: 1 }
            }

            // Empty state đơn giản
            Column {
                visible: page.filteredCount === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                spacing: 12

                Label {
                    text: "👤"
                    font.pixelSize: 48
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }

                Label {
                    text: "No users found"
                    color: "#666666"
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }

                Label {
                    text: "Try searching with a different name or ID"
                    color: "#999999"
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
            }
        }
    }

    // Click ngoài khu vực keyboard để tắt
    MouseArea {
        id: dismissArea
        anchors.fill: parent
        z: 999
        visible: page.keyboardOpened
        propagateComposedEvents: true
        onClicked: (ev) => {
            if (ev.y < keyboard.y) {
                page.keyboardOpened = false
                searchField.focus = false
            }
        }
    }

    // Bàn phím ảo
    Keyboard {
        id: keyboard
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        target: searchField
        opened: page.keyboardOpened
        z: 1000
        onOpenedChanged: if (!opened) { page.keyboardOpened = false; searchField.focus = false }
    }
}
