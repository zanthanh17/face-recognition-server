// ui/pages/History.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Item {
    id: historyPage
    signal backRequested()
    
    property bool wifiConnected: true // Will be set from parent

    // Real history data from API
    property var historyData: []
    property bool isLoading: false
    property string errorMessage: ""
    
    // Load history data from API
    function loadHistoryData() {
        isLoading = true
        errorMessage = ""
        
        console.log("Loading history data...")
        
        // Simulate loading delay
        loadingTimer.start()
    }
    
            // Timer to simulate loading
        Timer {
            id: loadingTimer
            interval: 500
            repeat: false
            onTriggered: {
                isLoading = false
                
                // Load global recognition history from backend
                loadGlobalRecognitionHistory()
            }
        }
    
    // Load global recognition history from backend
    function loadGlobalRecognitionHistory() {
        var globalHistory = backend.recognitionHistory
        console.log("Loading global recognition history, length:", globalHistory.length)
        
        if (globalHistory && globalHistory.length > 0) {
            historyData = globalHistory.map(function(item) {
                // Use captured image if available, otherwise fallback to default
                var avatarUrl = "qrc:/assets/images/user.png"
                if (item.captured_image && item.captured_image.length > 0) {
                    // Add data URL prefix if it's a base64 string
                    if (item.captured_image.startsWith("data:")) {
                        avatarUrl = item.captured_image
                    } else {
                        avatarUrl = "data:image/jpeg;base64," + item.captured_image
                    }
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
            console.log("Loaded", historyData.length, "recognition events from global history")
        } else {
            errorMessage = "No history logs yet. Try scanning your face!"
            console.log("No global recognition history found")
        }
    }
    
    // Function to add recognition event when face is recognized
    function addRecognitionEvent(userName, success, capturedImage) {
        var now = new Date()
        var avatarUrl = "qrc:/assets/images/user.png"
        if (capturedImage && capturedImage.length > 0) {
            // Add data URL prefix if it's a base64 string
            if (capturedImage.startsWith("data:")) {
                avatarUrl = capturedImage
            } else {
                avatarUrl = "data:image/jpeg;base64," + capturedImage
            }
        }
        
        var event = {
            name: userName || "Unknown",
            time: Qt.formatTime(now, "hh:mm:ss"),
            date: Qt.formatDate(now, "yyyy-MM-dd"),
            avatar: avatarUrl,
            type: success ? "checkin" : "checkout",
            status: success ? "success" : "failed"
        }
        
        // Add to beginning of history
        historyData.unshift(event)
        
        console.log("Added recognition event:", event)
        console.log("History data updated, length:", historyData.length)
    }
    
    // Handle history data loaded from backend
    function onHistoryDataLoaded(data) {
        isLoading = false
        console.log("Processing history data:", data)
        
        if (data && Array.isArray(data)) {
            try {
                historyData = data.map(function(item) {
                    // Ensure all fields exist with safe defaults
                    var safeItem = {
                        id: item.id || 0,
                        ts: item.ts || 0,
                        name: item.name || "Unknown",
                        matched: item.matched || false,
                        distance: item.distance || 0.0,
                        device_id: item.device_id || "Unknown"
                    }
                    
                    var date = new Date(safeItem.ts * 1000)
                    return {
                        id: safeItem.id,
                        name: safeItem.name,
                        time: Qt.formatTime(date, "hh:mm:ss"),
                        date: Qt.formatDate(date, "yyyy-MM-dd"),
                        avatar: "qrc:/assets/images/user.png",
                        type: safeItem.matched ? "checkin" : "checkout",
                        status: safeItem.matched ? "success" : "failed",
                        distance: safeItem.distance,
                        device_id: safeItem.device_id
                    }
                })
                console.log("Processed", historyData.length, "history items")
            } catch (error) {
                console.error("Error processing history data:", error)
                errorMessage = "Error processing history data: " + error
            }
        } else {
            console.log("Invalid history data format:", data)
            errorMessage = "Invalid history data format"
        }
    }
    
        // Real-time recognition history data from global backend
    property var recognitionHistory: []

    HeaderBar {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        wifiConnected: historyPage.wifiConnected
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
            onClicked: historyPage.backRequested()
        }

        Label {
            text: "History"
            font.pixelSize: 20
            font.bold: true
            color: "#333"
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        // Filter/Search button (optional)
        ToolButton {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            background: Rectangle { radius: width/2; color: "#E3F2FD"; border.color: "#1976D2" }
            contentItem: Label {
                text: "⟳"
                font.pixelSize: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: "#1976D2"
            }
            onClicked: refreshHistory()
        }
    }

    // Loading indicator
    Rectangle {
        id: loadingOverlay
        anchors.fill: parent
        color: "white"
        opacity: isLoading ? 0.8 : 0
        visible: isLoading
        z: 10
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16
            
            BusyIndicator {
                Layout.alignment: Qt.AlignHCenter
                running: isLoading
            }
            
            Label {
                text: "Loading history..."
                font.pixelSize: 16
                color: "#666"
                Layout.alignment: Qt.AlignHCenter
            }
        }
        
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
    }
    
    // Error message
    Rectangle {
        id: errorOverlay
        anchors.fill: parent
        color: "#FFF3E0"
        opacity: errorMessage !== "" ? 1 : 0
        visible: errorMessage !== ""
        z: 10
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16
            
            Label {
                text: "⚠️"
                font.pixelSize: 48
                Layout.alignment: Qt.AlignHCenter
            }
            
            Label {
                text: errorMessage
                font.pixelSize: 16
                color: "#E65100"
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
            
            Button {
                text: "Retry"
                Layout.alignment: Qt.AlignHCenter
                onClicked: loadHistoryData()
            }
        }
        
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
    }

    // History List
    ScrollView {
        id: scrollView
        anchors.top: titleRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        clip: true
        
        // Enable smooth scrolling - Remove these lines that cause grouped property error

        ListView {
            id: historyList
            spacing: 2
            model: historyData
            
            // Smooth scrolling properties
            boundsBehavior: Flickable.DragOverBounds
            boundsMovement: Flickable.StopAtBounds
            flickDeceleration: 1500
            maximumFlickVelocity: 2000
            
            // Enable caching for better performance
            cacheBuffer: 320
            
            // Add margins for better visual spacing
            topMargin: 8
            bottomMargin: 8

            delegate: Rectangle {
                id: historyItem
                width: historyList.width
                height: 60
                color: getBackgroundColor(modelData.type, modelData.status)
                border.width: 0

                // Left border color indicator
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 4
                    color: getBorderColor(modelData.type, modelData.status)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    spacing: 12

                    // Avatar
                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 22
                        color: "#F5F5F5"
                        border.color: "#E0E0E0"
                        border.width: 1
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: modelData.avatar
                            fillMode: Image.PreserveAspectCrop
                        }
                    }

                    // Name and details
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: modelData.name
                            font.pixelSize: 16
                            font.bold: true
                            color: "#333"
                        }

                        RowLayout {
                            spacing: 8

                            Label {
                                text: getStatusText(modelData.type, modelData.status)
                                font.pixelSize: 12
                                color: getTextColor(modelData.type, modelData.status)
                            }

                            Label {
                                text: "•"
                                font.pixelSize: 12
                                color: "#999"
                            }

                            Label {
                                text: modelData.date
                                font.pixelSize: 12
                                color: "#666"
                            }
                        }
                    }

                    // Time
                    Label {
                        text: modelData.time
                        font.pixelSize: 14
                        font.bold: true
                        color: "#333"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Status icon
                    Image {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        source: getStatusIcon(modelData.type, modelData.status)
                        fillMode: Image.PreserveAspectFit
                        visible: modelData.status === "failed"
                    }
                }

                // Hover effect
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.opacity = 0.8
                    onExited: parent.opacity = 1.0
                    onClicked: {
                        console.log("Clicked on:", modelData.name, modelData.type, modelData.time)
                        // Could open detail view here
                    }
                }
            }
        }
    }
    
    // Custom scroll bar as separate component
    ScrollBar {
        id: verticalScrollBar
        anchors.right: scrollView.right
        anchors.top: scrollView.top
        anchors.bottom: scrollView.bottom
        anchors.rightMargin: 2
        
        policy: ScrollBar.AlwaysOn
        orientation: Qt.Vertical
        size: scrollView.height / historyList.contentHeight
        position: historyList.contentY / historyList.contentHeight
        
        onPositionChanged: {
            if (pressed) {
                historyList.contentY = position * historyList.contentHeight
            }
        }
        
        background: Rectangle {
            color: "#F0F0F0"
            radius: 4
            width: 8
        }
        
        contentItem: Rectangle {
            color: verticalScrollBar.pressed ? "#888888" : "#CCCCCC"
            radius: 4
            width: 8
            
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }
    }

    // Remove scroll position indicator since we have custom scroll bar

    // Scroll to top button (appears when scrolled down)
    Rectangle {
        id: scrollToTopButton
        visible: historyList.contentY > 200
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 60  // More space to avoid scroll bar
        anchors.bottomMargin: 20
        width: 48
        height: 48
        radius: 24
        color: "#2196F3"
        border.color: "#1976D2"
        border.width: 1
        z: 10
        
        // Shadow effect
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 2
            radius: parent.radius
            color: "#000000"
            opacity: 0.1
            z: -1
        }
        
        Label {
            anchors.centerIn: parent
            text: "↑"
            font.pixelSize: 20
            font.bold: true
            color: "white"
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                scrollAnimation.to = 0
                scrollAnimation.start()
            }
        }
        
        // Fade in/out animation
        Behavior on visible {
            NumberAnimation { 
                property: "opacity"
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }
    }
    
    // Smooth scroll to top animation
    NumberAnimation {
        id: scrollAnimation
        target: historyList
        property: "contentY"
        duration: 500
        easing.type: Easing.OutCubic
    }

    // Helper functions for styling
    function getBackgroundColor(type, status) {
        if (status === "failed") {
            return "#FFEBEE" // Light red
        }
        
        switch(type) {
            case "checkin":
                return "#E8F5E8" // Light green
            case "checkout": 
                return "#FFF3E0" // Light orange
            default:
                return "#F5F5F5" // Light gray
        }
    }

    function getBorderColor(type, status) {
        if (status === "failed") {
            return "#F44336" // Red
        }
        
        switch(type) {
            case "checkin":
                return "#4CAF50" // Green
            case "checkout":
                return "#FF9800" // Orange
            default:
                return "#9E9E9E" // Gray
        }
    }

    function getTextColor(type, status) {
        if (status === "failed") {
            return "#D32F2F" // Dark red
        }
        
        switch(type) {
            case "checkin":
                return "#2E7D32" // Dark green
            case "checkout":
                return "#F57C00" // Dark orange
            default:
                return "#616161" // Dark gray
        }
    }

    function getStatusText(type, status) {
        if (status === "failed") {
            return type === "checkin" ? "Check-in Failed" : "Check-out Failed"
        }
        
        switch(type) {
            case "checkin":
                return "Check-in Success"
            case "checkout":
                return "Check-out Success"
            default:
                return "Unknown"
        }
    }

    function getStatusIcon(type, status) {
        if (status === "failed") {
            return "qrc:/assets/icons/portrait-circle.png" // Error icon
        }
        return "qrc:/assets/icons/success-check.png" // Success icon
    }

    function refreshHistory() {
        console.log("Refreshing history...")
        
        // Simple refresh animation
        refreshAnimation.start()
        
        // Load fresh data from API
        loadHistoryData()
        
        // Scroll to top after refresh
        scrollToTop()
    }
    
    function scrollToTop() {
        scrollAnimation.to = 0
        scrollAnimation.start()
    }
    
    function scrollToBottom() {
        scrollAnimation.to = historyList.contentHeight - historyList.height
        scrollAnimation.start()
    }

    // Refresh animation
    SequentialAnimation {
        id: refreshAnimation
        
        PropertyAnimation {
            target: historyList
            property: "opacity"
            from: 1.0
            to: 0.5
            duration: 200
        }
        
        PropertyAnimation {
            target: historyList
            property: "opacity" 
            from: 0.5
            to: 1.0
            duration: 200
        }
    }

    // Filter controls (can be expanded)
    property string filterType: "all" // all, checkin, checkout, failed
    property string filterDate: "today" // today, week, month, all

    function applyFilters() {
        // This would filter the historyData based on current filters
        // For now just a placeholder
        console.log("Applying filters:", filterType, filterDate)
    }
    
    // Load data when page is completed
    Component.onCompleted: {
        console.log("History page completed, loading data...")
        loadHistoryData()
    }
    
    // Backend signal connections
    Connections {
        target: backend
        function onRecognitionHistoryChanged() {
            console.log("Global recognition history changed, reloading...")
            loadGlobalRecognitionHistory()
        }
        
        function onRecognitionEventAdded(userName, success, timestamp) {
            console.log("Recognition event received in History:", userName, success, timestamp)
            addRecognitionEvent(userName, success)
        }
        
        function onFaceRecognized(userId, userName) {
            console.log("Face recognized in History page:", userName)
            // Add recognition event to history
            addRecognitionEvent(userName, true)
        }
        
        function onFaceRecognitionFailed() {
            console.log("Face recognition failed in History page")
            // Add failed recognition event to history
            addRecognitionEvent("Unknown", false)
        }
        
        function onHistoryDataLoaded(data) {
            console.log("History data loaded from backend, type:", typeof data)
            console.log("History data loaded from backend, length:", data ? data.length : "undefined")
            console.log("History data loaded from backend, first item:", data && data.length > 0 ? data[0] : "none")
            onHistoryDataLoaded(data)
        }
        
        function onHistoryDataLoadedJson(jsonData) {
            console.log("History data loaded as JSON, length:", jsonData.length)
            try {
                var data = JSON.parse(jsonData)
                console.log("Parsed JSON data, type:", typeof data, "length:", data.length)
                onHistoryDataLoaded(data)
            } catch (error) {
                console.error("Error parsing JSON:", error)
                errorMessage = "Error parsing history data: " + error
            }
        }
        
        function onHistoryDataLoadFailed(error) {
            console.log("History data load failed:", error)
            isLoading = false
            errorMessage = "Failed to load history: " + error
            // Fallback to mock data for testing
            historyData = mockHistoryData
        }
    }
    
    // Keyboard navigation support
    focus: true
    Keys.onPressed: (event) => {
        switch(event.key) {
            case Qt.Key_Home:
                scrollToTop()
                event.accepted = true
                break
            case Qt.Key_End:
                scrollToBottom() 
                event.accepted = true
                break
            case Qt.Key_PageUp:
                historyList.contentY = Math.max(0, historyList.contentY - historyList.height * 0.8)
                event.accepted = true
                break
            case Qt.Key_PageDown:
                historyList.contentY = Math.min(historyList.contentHeight - historyList.height, 
                                               historyList.contentY + historyList.height * 0.8)
                event.accepted = true
                break
            case Qt.Key_F5:
                refreshHistory()
                event.accepted = true
                break
        }
    }
}
