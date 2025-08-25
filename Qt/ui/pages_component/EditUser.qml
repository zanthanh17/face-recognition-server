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
            console.log("Recomputing filtered count, backend.users.length:", backend.users.length)
            for (let i = 0; i < backend.users.length; ++i) {
                const it = backend.users[i]
                console.log("Checking user:", it.name, "id:", it.id)
                const ok =
                    key.length === 0 ||
                    it.name.toLowerCase().indexOf(key) !== -1 ||
                    it.id.toString().toLowerCase().indexOf(key)  !== -1
                if (ok) n++
            }
        } else {
            console.log("backend.users is null or undefined")
        }
        console.log("Filtered count:", n, "key:", key)
        filteredCount = n
    }
    
    function loadUserAvatar(userId, userName, avatarImage) {
        console.log("Loading avatar for user:", userName, "ID:", userId)
        // Load user image from server
        var userImageData = backend.getUserImage(userId)
        console.log("getUserImage result:", typeof userImageData, "length:", userImageData ? userImageData.length : "null")
        if (userImageData && userImageData.length > 0) {
            avatarImage.source = "data:image/jpeg;base64," + userImageData
            console.log("✅ Set server image for:", userName)
        } else {
            avatarImage.source = "qrc:/assets/images/user.png"
            console.log("❌ Using default image for:", userName)
        }
    }

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
            text: "Edit Face"
            font.pixelSize: 20
            font.bold: true
            color: "#333"
            Layout.alignment: Qt.AlignVCenter
        }
    }

    ColumnLayout {
        id: body
        anchors.top: titleRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        spacing: 10

        Label { text: "Find User"; font.pixelSize: 14; color: "#333" }

        // ô tìm + nút kính lúp
        Rectangle {
            Layout.fillWidth: true
            height: 38
            radius: 8
            color: "#FFFFFF"
            border.color: "#C9CED6"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "Type name or ID..."
                    readOnly: true
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

        Label { text: "Users"; font.pixelSize: 14; color: "#333"; topPadding: 6 }

        // ===== List khi có kết quả =====
        ListView {
            id: listView
            visible: page.filteredCount > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10

            model: backend.users || []

            // cập nhật filteredCount khi mới vào trang
            Component.onCompleted: {
                page.recomputeFilteredCount()
                backend.loadUsersFromBackend()
            }
            
            // Reload users when backend.users changes
            Connections {
                target: backend
                function onUsersChanged() {
                    console.log("Users changed, backend.users.length:", backend.users ? backend.users.length : 0)
                    page.recomputeFilteredCount()
                }
            }

            delegate: Item {
                width: listView.width
                height: visible ? 66 : 0

                property string key: searchField.text.toLowerCase()
                visible: key.length === 0
                         || modelData.name.toLowerCase().indexOf(key) !== -1
                         || modelData.id.toString().toLowerCase().indexOf(key)  !== -1

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 60
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#C9CED6"
                    antialiasing: true

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Rectangle {
                            width: 36; height: 36; radius: 18
                            color: "#EAF2FF"; border.color: "#D2D7DE"
                            
                            // Avatar image or placeholder
                            Image { 
                                id: userAvatar
                                anchors.fill: parent; 
                                source: "qrc:/assets/images/user.png"; 
                                fillMode: Image.PreserveAspectFill
                                layer.enabled: true
                                layer.smooth: true
                                
                                // Load user image from server
                                Component.onCompleted: {
                                    console.log("Avatar Component.onCompleted for:", modelData ? modelData.name : "unknown")
                                    if (modelData && modelData.id) {
                                        console.log("Calling loadUserAvatar for:", modelData.name, "ID:", modelData.id)
                                        loadUserAvatar(modelData.id, modelData.name, userAvatar)
                                    } else {
                                        console.log("No modelData or modelData.id")
                                    }
                                }
                            }
                            
                            // Fallback placeholder with initials
                            Rectangle {
                                id: placeholderAvatar
                                anchors.fill: parent
                                radius: 18
                                visible: userAvatar.status !== Image.Ready
                                
                                Component.onCompleted: {
                                    if (modelData && modelData.name) {
                                        let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F"]
                                        let colorIndex = modelData.name.charCodeAt(0) % colors.length
                                        placeholderAvatar.color = colors[colorIndex]
                                    }
                                }
                                
                                Label {
                                    anchors.centerIn: parent
                                    text: modelData ? modelData.name.split(' ').map(n => n.charAt(0)).join('').toUpperCase() : ""
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "white"
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label { text: modelData.name; font.bold: true; color: "#333" }
                            Label { text: modelData.position || "Employee"; color: "#666"; font.pixelSize: 12 }
                        }

                        Label { text: "\u203A"; font.pixelSize: 20; color: "#333"; verticalAlignment: Text.AlignVCenter }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var avatarUrl = userAvatar.source
                            page.userClicked(modelData.id.toString(), modelData.name, modelData.position || "Employee", avatarUrl)
                        }
                    }
                }
            }

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            footer: Item { height: 8; width: 1 }
        }

        // ===== Empty state khi không có user =====
        Column {
            visible: page.filteredCount === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            spacing: 8

            Label {
                text: "User does not exist"
                color: "#666"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
            Image {
                source: "qrc:/assets/icons/empty_search.png" // đặt icon như hình mẫu
                width: 120; height: 120
                fillMode: Image.PreserveAspectFit
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
        // khi nhấn return trong Keyboard.qml sẽ set opened=false,
        // ở đây mình đồng bộ lại:
        onOpenedChanged: if (!opened) { page.keyboardOpened = false; searchField.focus = false }
    }
}
