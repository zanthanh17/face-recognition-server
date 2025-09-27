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
    property int  filteredCount: 0
    property bool wifiConnected: true

    // ===== Background =====
    Image {
        anchors.fill: parent
        source: "qrc:/assets/images/background.png"
        fillMode: Image.PreserveAspectCrop
        z: 0
    }

    function recomputeFilteredCount() {
        const key = (searchField.text || "").toLowerCase()
        let n = 0
        if (backend.users) {
            for (let i = 0; i < backend.users.length; ++i) {
                const it = backend.users[i]
                const ok = key.length === 0
                           || it.name.toLowerCase().indexOf(key) !== -1
                           || it.id.toString().toLowerCase().indexOf(key) !== -1
                if (ok) n++
            }
        }
        filteredCount = n
    }

    function loadUserAvatar(userId, userName, avatarImage) {
        var userImageData = backend.getUserImage(userId)
        if (userImageData && userImageData.length > 0)
            avatarImage.source = "data:image/jpeg;base64," + userImageData
        else
            avatarImage.source = "qrc:/assets/images/user.png"
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
            MouseArea { anchors.fill: parent; onClicked: page.backRequested() }
        }

        // Title
        Text {
            anchors.centerIn: parent
            text: "USER LIST"
            color: "#2C3E50"
            font.pixelSize: 32; font.bold: true
        }
    }

    // ===== Search =====
    Rectangle {
        id: searchSection
        width: 300; height: 50
        color: "white"
        border.color: "#BDC3C7"; border.width: 2; radius: 8
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: headerSection.bottom; anchors.topMargin: 30
        z: 1

        Row {
            anchors.fill: parent; anchors.margins: 10; spacing: 10

            Rectangle {
                width: 30; height: 30; color: "transparent"
                anchors.verticalCenter: parent.verticalCenter
                Image { anchors.centerIn: parent; source: "qrc:/assets/icons/search.png"; width: 24; height: 24; fillMode: Image.PreserveAspectFit }
                MouseArea { anchors.fill: parent; onClicked: { searchField.forceActiveFocus(); page.keyboardOpened = true } }
            }

            TextField {
                id: searchField
                width: parent.width - 50; height: 30
                anchors.verticalCenter: parent.verticalCenter
                placeholderText: "Search users..."; placeholderTextColor: "#999"
                readOnly: true; font.pixelSize: 16; color: "#333"
                background: Rectangle { color: "transparent" }
                Keys.onPressed: (e)=> e.accepted = true
                Keys.onReleased:(e)=> e.accepted = true
                onTextChanged: page.recomputeFilteredCount()
                MouseArea { anchors.fill: parent; onClicked: { searchField.forceActiveFocus(); page.keyboardOpened = true } }
            }
        }
    }

    // ===== List =====
    ListView {
        id: listView
        visible: page.filteredCount > 0
        width: parent.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: searchSection.bottom; anchors.topMargin: 20
        anchors.bottom: parent.bottom; anchors.bottomMargin: 20
        clip: true; spacing: 10; z: 1

        model: backend.users || []
        
        // Enable scroll bar
        ScrollBar.vertical: ScrollBar {
            active: true
            policy: ScrollBar.AlwaysOn
            width: 8
            background: Rectangle {
                color: "#E0E0E0"
                radius: 4
            }
            contentItem: Rectangle {
                color: "#BDBDBD"
                radius: 4
                opacity: parent.pressed ? 1.0 : 0.7
                
                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }
        }
        
        // Footer để đảm bảo có đủ khoảng trống cuối list
        footer: Item { height: 20; width: 1 }

        Component.onCompleted: {
            page.recomputeFilteredCount()
            backend.loadUsersFromBackend()
        }
        Connections {
            target: backend
            function onUsersChanged() { page.recomputeFilteredCount() }
        }

        delegate: Item {
            width: listView.width
            height: visible ? 70 : 0

            property string key: searchField.text.toLowerCase()
            visible: key.length === 0
                     || modelData.name.toLowerCase().indexOf(key) !== -1
                     || modelData.id.toString().toLowerCase().indexOf(key) !== -1

            // Card
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 64
                radius: 10
                color: "white"
                border.color: "#E0E0E0"; border.width: 1

                // dùng Layout để căn giữa theo dọc
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // Avatar tròn, ảnh fill kín
                    Rectangle {
                        id: avatarWrap
                        width: 40; height: 40
                        radius: width/2
                        color: "#FFF"
                        border.color: "#FF4757"; border.width: 2
                        clip: true
                        Layout.alignment: Qt.AlignVCenter

                        Image {
                            id: userAvatar
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            smooth: true; antialiasing: true
                            Component.onCompleted: {
                                if (modelData && modelData.id)
                                    loadUserAvatar(modelData.id, modelData.name, userAvatar)
                            }
                        }

                        // Fallback chữ cái
                        Rectangle {
                            anchors.fill: parent
                            radius: width/2
                            visible: userAvatar.status !== Image.Ready
                            color: "#FF6B6B"
                            Text {
                                anchors.centerIn: parent
                                text: modelData ? modelData.name.charAt(0).toUpperCase() : ""
                                font.pixelSize: 18; font.bold: true; color: "white"
                            }
                        }
                    }

                    // Thông tin user – CĂN GIỮA THEO DỌC
                    Column {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter
                        Text { text: modelData.name; font.pixelSize: 18; font.bold: true; color: "#2C3E50" }
                        Text { text: modelData.position || "Dev"; font.pixelSize: 14; color: "#7F8C8D" }
                    }

                    // Spacer đẩy mũi tên sang phải
                    Item { Layout.fillWidth: true }

                    // Arrow sát phải, căn giữa theo dọc
                    Text {
                        text: "›"
                        font.pixelSize: 22
                        color: "#BDC3C7"
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var avatarUrl = userAvatar.source
                        page.userClicked(modelData.id.toString(),
                                         modelData.name,
                                         modelData.position || "Employee",
                                         avatarUrl)
                    }
                }
            }
        }
    }

    // ===== Empty state =====
    Column {
        visible: page.filteredCount === 0
        anchors.centerIn: parent
        spacing: 20; z: 1
        Image { anchors.horizontalCenter: parent.horizontalCenter; source: "qrc:/assets/icons/empty_search.png"; width: 80; height: 80; fillMode: Image.PreserveAspectFit }
        Text  { text: "No users found"; color: "#2C3E50"; font.pixelSize: 20; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
        Text  { text: "Try searching with a different name or ID"; color: "#7F8C8D"; font.pixelSize: 16; anchors.horizontalCenter: parent.horizontalCenter }
    }

    // ===== Dismiss keyboard =====
    MouseArea {
        id: dismissArea
        anchors.fill: parent; z: 999
        visible: page.keyboardOpened
        propagateComposedEvents: true
        onClicked: (ev) => {
            if (ev.y < keyboard.y) { page.keyboardOpened = false; searchField.focus = false }
        }
    }

    // ===== Keyboard =====
    Keyboard {
        id: keyboard
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        target: searchField
        opened: page.keyboardOpened
        z: 1000
        onOpenedChanged: if (!opened) { page.keyboardOpened = false; searchField.focus = false }
    }
}
