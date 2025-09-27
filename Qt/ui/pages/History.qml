// ui/pages/History.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Item {
    id: historyPage
    signal backRequested()

    property bool  wifiConnected: true
    property bool  keyboardOpened: false
    property int   filteredCount: 0

    // Real history data from API / backend
    property var   historyData: []
    property bool  isLoading: false
    property string errorMessage: ""

    // ===== Utils =====
    function recomputeFilteredCount() {
        const key = (searchField.text || "").toLowerCase()
        let n = 0
        if (historyData) {
            for (let i = 0; i < historyData.length; ++i) {
                const it = historyData[i]
                const ok = key.length === 0
                           || (it.name || "").toLowerCase().indexOf(key) !== -1
                           || (it.time || "").toLowerCase().indexOf(key) !== -1
                           || (it.date || "").toLowerCase().indexOf(key) !== -1
                if (ok) n++
            }
        }
        filteredCount = n
    }

    // Background
    Image {
        anchors.fill: parent
        source: "qrc:/assets/images/background.png"
        fillMode: Image.PreserveAspectCrop
        z: 0
    }

    // Mock loading → rồi nạp từ backend global history
    function loadHistoryData() {
        isLoading = true
        errorMessage = ""
        loadingTimer.start()
    }
    Timer {
        id: loadingTimer
        interval: 500
        repeat: false
        onTriggered: {
            isLoading = false
            loadGlobalRecognitionHistory()
        }
    }

    function loadGlobalRecognitionHistory() {
        var globalHistory = backend.recognitionHistory
        if (globalHistory && globalHistory.length > 0) {
            historyData = globalHistory.map(function(item) {
                var avatarUrl = "qrc:/assets/images/user.png"
                if (item.captured_image && item.captured_image.length > 0) {
                    avatarUrl = item.captured_image.startsWith("data:")
                              ? item.captured_image
                              : "data:image/jpeg;base64," + item.captured_image
                }
                return {
                    name: item.name || "Unknown",
                    time: item.time || "00:00:00",
                    date: item.date || "2024-01-01",
                    avatar: avatarUrl,
                    type: item.type || "checkin",
                    status: item.status || "failed"
                }
            })
        } else {
            errorMessage = "No history logs yet. Try scanning your face!"
        }
        historyPage.recomputeFilteredCount()
    }

    function addRecognitionEvent(userName, success, capturedImage) {
        var now = new Date()
        var avatarUrl = "qrc:/assets/images/user.png"
        if (capturedImage && capturedImage.length > 0)
            avatarUrl = capturedImage.startsWith("data:")
                      ? capturedImage
                      : "data:image/jpeg;base64," + capturedImage
        historyData.unshift({
            name: userName || "Unknown",
            time: Qt.formatTime(now, "hh:mm:ss"),
            date: Qt.formatDate(now, "yyyy-MM-dd"),
            avatar: avatarUrl,
            type: success ? "checkin" : "checkout",
            status: success ? "success" : "failed"
        })
        historyPage.recomputeFilteredCount()
    }

    // ===== Header =====
    Rectangle {
        id: headerSection
        width: parent.width; height: 80
        color: "transparent"; z: 1

        Rectangle {
            width: 60; height: 60; color: "transparent"
            anchors.left: parent.left; anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            Image { anchors.centerIn: parent; source: "qrc:/assets/icons/back.png"; width: 40; height: 40; fillMode: Image.PreserveAspectFit }
            MouseArea { anchors.fill: parent; onClicked: historyPage.backRequested() }
        }

        Text {
            anchors.centerIn: parent
            text: "HISTORY IN/OUT"
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
                MouseArea { anchors.fill: parent; onClicked: { searchField.forceActiveFocus(); historyPage.keyboardOpened = true } }
            }

            TextField {
                id: searchField
                width: parent.width - 50; height: 30
                anchors.verticalCenter: parent.verticalCenter
                placeholderText: "Search history..."; placeholderTextColor: "#999"
                readOnly: true; font.pixelSize: 16; color: "#333"
                background: Rectangle { color: "transparent" }
                Keys.onPressed:  (e)=> e.accepted = true
                Keys.onReleased: (e)=> e.accepted = true
                onTextChanged: historyPage.recomputeFilteredCount()
                MouseArea { anchors.fill: parent; onClicked: { searchField.forceActiveFocus(); historyPage.keyboardOpened = true } }
            }
        }
    }

    // ===== Loading & Error overlays =====
    Rectangle {
        anchors.fill: parent
        color: "white"
        opacity: isLoading ? 0.8 : 0
        visible: isLoading
        z: 10
        ColumnLayout {
            anchors.centerIn: parent; spacing: 16
            BusyIndicator { Layout.alignment: Qt.AlignHCenter; running: isLoading }
            Label { text: "Loading history..."; font.pixelSize: 16; color: "#666"; Layout.alignment: Qt.AlignHCenter }
        }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Rectangle {
        anchors.fill: parent
        color: "#FFF3E0"
        opacity: errorMessage !== "" ? 1 : 0
        visible: errorMessage !== ""
        z: 10
        ColumnLayout {
            anchors.centerIn: parent; spacing: 16
            Label { text: "⚠️"; font.pixelSize: 48; Layout.alignment: Qt.AlignHCenter }
            Label {
                text: errorMessage; font.pixelSize: 16; color: "#E65100"
                Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            }
            Button { text: "Retry"; Layout.alignment: Qt.AlignHCenter; onClicked: loadHistoryData() }
        }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // ===== History List =====
    ScrollView {
        id: scrollView
        anchors.top: searchSection.bottom
        anchors.left: parent.left; anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 20; anchors.leftMargin: 20
        anchors.rightMargin: 20; anchors.bottomMargin: 20
        clip: true; z: 1

        ListView {
            id: historyList
            spacing: 10
            model: historyData
            visible: historyPage.filteredCount > 0

            boundsBehavior: Flickable.DragOverBounds
            boundsMovement: Flickable.StopAtBounds
            flickDeceleration: 1500
            maximumFlickVelocity: 2000

            cacheBuffer: 320
            topMargin: 8; bottomMargin: 8
            
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

            delegate: Item {
                width: historyList.width
                height: visible ? 70 : 0

                property string key: searchField.text.toLowerCase()
                visible: key.length === 0
                         || (modelData.name || "").toLowerCase().indexOf(key) !== -1
                         || (modelData.time || "").toLowerCase().indexOf(key) !== -1
                         || (modelData.date || "").toLowerCase().indexOf(key) !== -1

                Rectangle {
                    id: historyItem
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 64
                    radius: 10
                    color: getBackgroundColor(modelData.type, modelData.status)
                    border.color: getBorderColor(modelData.type, modelData.status)
                    border.width: 2

                    // RowLayout để tất cả thành phần được căn giữa theo dọc
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        // Avatar / Captured image
                        Rectangle {
                            width: 40; height: 40
                            radius: 20
                            color: "#F5F5F5"
                            border.color: "#E0E0E0"; border.width: 1
                            clip: true
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                id: capturedImage
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: modelData.avatar || "qrc:/assets/images/user.png"
                                smooth: true; antialiasing: true
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 20
                                visible: capturedImage.status !== Image.Ready
                                color: "#E0E0E0"
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                                    font.pixelSize: 16; font.bold: true; color: "#666"
                                }
                            }
                        }

                        // Tên người dùng – căn giữa theo dọc, chiếm phần còn lại
                        Text {
                            text: modelData.name || "Unknown"
                            font.pixelSize: 18; font.bold: true
                            color: "#2C3E50"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Cột Time + Date ở cạnh phải
                        Column {
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                            Text {
                                text: modelData.time || "00:00:00"
                                font.pixelSize: 16; font.bold: true
                                color: "#2C3E50"
                                horizontalAlignment: Text.AlignRight
                            }
                            Text {
                                text: modelData.date || Qt.formatDate(new Date(), "yyyy-MM-dd")
                                font.pixelSize: 12
                                color: "#607D8B"
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: console.log("Clicked:", modelData.name, modelData.type, modelData.time, modelData.date)
                    }
                }
            }
            
            // Footer để đảm bảo có đủ khoảng trống cuối list
            footer: Item { height: 20; width: 1 }

            Component.onCompleted: {
                historyPage.recomputeFilteredCount()
            }
            Connections {
                target: historyPage
                function onHistoryDataChanged() { historyPage.recomputeFilteredCount() }
            }
        }
    }

    // ===== Empty state =====
    Column {
        visible: historyPage.filteredCount === 0 && !isLoading && errorMessage === ""
        anchors.centerIn: parent
        spacing: 20; z: 1
        Image { anchors.horizontalCenter: parent.horizontalCenter; source: "qrc:/assets/icons/empty_search.png"; width: 80; height: 80; fillMode: Image.PreserveAspectFit }
        Text  { text: "No history found"; color: "#2C3E50"; font.pixelSize: 20; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
        Text  { text: "Try searching with a different name, date or time"; color: "#7F8C8D"; font.pixelSize: 16; anchors.horizontalCenter: parent.horizontalCenter }
    }

    // ===== Helpers for styles =====
    function getBackgroundColor(type, status) {
        if (status === "failed") return "#FFEBEE" // Light red
        return "#E8F5E8"                           // Light green
    }
    function getBorderColor(type, status) {
        if (status === "failed") return "#F44336" // Red
        return "#4CAF50"                          // Green
    }

    // ===== Keyboard overlay =====
    MouseArea {
        id: dismissArea
        anchors.fill: parent; z: 999
        visible: historyPage.keyboardOpened
        propagateComposedEvents: true
        onClicked: (ev) => {
            if (ev.y < keyboard.y) { historyPage.keyboardOpened = false; searchField.focus = false }
        }
    }
    Keyboard {
        id: keyboard
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        target: searchField
        opened: historyPage.keyboardOpened
        z: 1000
        onOpenedChanged: if (!opened) { historyPage.keyboardOpened = false; searchField.focus = false }
    }

    // ===== Init & backend hooks =====
    Component.onCompleted: {
        loadHistoryData()
        historyPage.recomputeFilteredCount()
    }
    Connections {
        target: backend
        function onRecognitionHistoryChanged() {
            loadGlobalRecognitionHistory()
        }
        function onRecognitionEventAdded(userName, success, ts) {
            addRecognitionEvent(userName, success)
        }
        function onFaceRecognized(userId, userName) {
            addRecognitionEvent(userName, true)
        }
        function onFaceRecognitionFailed() {
            addRecognitionEvent("Unknown", false)
        }
    }
}
