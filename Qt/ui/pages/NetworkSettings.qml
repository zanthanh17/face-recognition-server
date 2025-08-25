// ui/pages/NetworkSettings.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import "../components"

Item {
    id: networkPage
    signal backRequested()
    signal wifiConfigured(bool success)

    property bool wifiEnabled: false // Start with WiFi off, will be updated when loading networks
    property bool isConnecting: false
    property string currentSSID: ""
    property int signalStrength: 0
    property bool isConnected: false
    property bool keyboardOpened: false
    property string connectionStatus: "" // "success", "incorrect", "not_wifi", "fail", ""

    // Real WiFi networks data from backend
    property var availableNetworks: []

    HeaderBar {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        wifiConnected: isConnected
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
            onClicked: networkPage.backRequested()
        }

        Label {
            text: "Wi-fi"
            font.pixelSize: 20
            font.bold: true
            color: "#333"
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        // Refresh button
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
            onClicked: {
                console.log("Refreshing WiFi networks...")
                backend.refreshNetworks()
                loadNetworks()
            }
        }
    }

    ColumnLayout {
        anchors.top: titleRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        spacing: 16



        // WiFi Enable/Disable Toggle
        Rectangle {
            Layout.fillWidth: true
            height: 60
            radius: 12
            color: "#FFFFFF"
            border.color: "#E0E0E0"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Label {
                    text: "Wi-fi"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#333"
                    Layout.fillWidth: true
                }

                Switch {
                    id: wifiSwitch
                    checked: wifiEnabled
                    onCheckedChanged: {
                        console.log("WiFi toggle changed to:", checked)
                        
                        // Call backend to actually enable/disable WiFi
                        let success = backend.setWifiEnabled(checked)
                        
                        if (success) {
                            wifiEnabled = checked
                            
                            if (checked) {
                                // Turn on WiFi - load networks and try to reconnect
                                loadNetworks()
                                
                                // Try to reconnect to last connected network
                                if (!isConnected) {
                                    console.log("Attempting to reconnect to last network...")
                                    let reconnectSuccess = backend.reconnectToLastNetwork()
                                    if (reconnectSuccess) {
                                        console.log("Auto-reconnected to last network")
                                        // Refresh networks to update UI
                                        loadNetworks()
                                    } else {
                                        console.log("Failed to auto-reconnect to last network")
                                    }
                                }
                            } else {
                                // Turn off WiFi - clear networks and disconnect
                                availableNetworks = []
                                isConnected = false
                                currentSSID = ""
                                connectionStatus = ""
                                networkPage.wifiConfigured(false)
                            }
                        } else {
                            // If failed, revert the switch
                            wifiSwitch.checked = !checked
                            console.log("Failed to change WiFi state")
                        }
                    }
                }
            }
        }

        // Connected Network Status (when connected)
        Rectangle {
            visible: wifiEnabled && isConnected
            Layout.fillWidth: true
            height: 80
            radius: 12
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1976D2" }
                GradientStop { position: 1.0; color: "#1565C0" }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Image {
                    source: "qrc:/assets/icons/wifi.png"
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    fillMode: Image.PreserveAspectFit
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: currentSSID
                        font.pixelSize: 18
                        font.bold: true
                        color: "white"
                    }

                    Label {
                        text: "Connected"
                        font.pixelSize: 14
                        color: "white"
                        opacity: 0.9
                    }
                }
            }
        }

        // WiFi List Label
        Label {
            visible: wifiEnabled
            text: "Wi-fi list"
            font.pixelSize: 16
            font.bold: true
            color: "#333"
            Layout.topMargin: 16
        }

        // WiFi Networks List with ScrollView
        ScrollView {
            visible: wifiEnabled
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 8

                Repeater {
                    model: wifiEnabled ? availableNetworks : []
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 50
                        radius: 8
                        color: "#FFFFFF"
                        border.color: "#E0E0E0"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            // WiFi signal icon
                            Image {
                                source: "qrc:/assets/icons/wifi.png"
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                fillMode: Image.PreserveAspectFit
                                opacity: modelData.strength / 3.0
                            }

                            // Network name
                            Label {
                                text: modelData.ssid
                                font.pixelSize: 14
                                color: "#333"
                                Layout.fillWidth: true
                            }

                            // Security icon (lock for secured networks)
                            Image {
                                visible: modelData.secured
                                source: "qrc:/assets/icons/lock.png"
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                fillMode: Image.PreserveAspectFit
                            }

                            // Arrow indicator
                            Label {
                                text: "\u203A"
                                font.pixelSize: 16
                                color: "#666"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !isConnecting && wifiEnabled
                            onClicked: connectToNetwork(modelData)
                        }
                    }
                }
            }
        }

        // WiFi Disabled State
        Rectangle {
            visible: !wifiEnabled
            Layout.fillWidth: true
            height: 120
            radius: 12
            color: "#F5F5F5"
            border.color: "#E0E0E0"
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                Image {
                    source: "qrc:/assets/icons/disconnectwifi.png"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.5
                }

                Label {
                    text: "Device is Offline. Please turn on WiFi to\nuse network connection."
                    font.pixelSize: 14
                    color: "#666"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        Item { Layout.preferredHeight: 20 } // Bottom spacing
    }

    // Fail Status (full screen overlay)
    Rectangle {
        visible: connectionStatus === "fail"
        anchors.fill: parent
        color: "#FFFFFF"
        z: 100

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 80
                height: 80
                radius: 40
                color: "#F44336"

                Label {
                    anchors.centerIn: parent
                    text: "✗"
                    font.pixelSize: 40
                    color: "white"
                    font.bold: true
                }
            }

            Label {
                text: "Fail"
                font.pixelSize: 24
                font.bold: true
                color: "#F44336"
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Timer {
            interval: 2000
            running: connectionStatus === "fail"
            onTriggered: {
                connectionStatus = ""
                passwordDialog.close()
            }
        }
    }

        // Password Dialog - using custom implementation like Setting page
    Rectangle {
        id: passwordDialog
        anchors.fill: parent
        visible: false
        z: 100

        property string targetSSID: ""
        property bool showPassword: false

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
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 50

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // Title
                Text {
                    text: passwordDialog.targetSSID
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
                            echoMode: passwordDialog.showPassword ? TextInput.Normal : TextInput.Password
                            verticalAlignment: TextInput.AlignVCenter
                            focus: true

                            // Show keyboard when focused
                            onFocusChanged: {
                                if (focus) {
                                    networkPage.keyboardOpened = true
                                }
                            }
                        }

                        // Eye icon to toggle password visibility
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 4
                            color: passwordDialog.showPassword ? "#3498db" : "#e0e0e0"
                            border.color: "#cccccc"
                            border.width: 1

                            Text {
                                text: passwordDialog.showPassword ? "👁" : "👁‍🗨"
                                anchors.centerIn: parent
                                font.pixelSize: 14
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: passwordDialog.showPassword = !passwordDialog.showPassword
                            }
                        }
                    }
                }

                // Error message for incorrect password
                Text {
                    visible: connectionStatus === "incorrect"
                    text: "Incorrect Password"
                    color: "#F44336"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
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
                        onClicked: {
                            networkPage.keyboardOpened = false
                            passwordDialog.hide()
                            connectionStatus = ""
                        }
                    }

                    Button {
                        text: "Connect"
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
                        onClicked: {
                            networkPage.keyboardOpened = false
                            performConnection(passwordDialog.targetSSID, passwordInput.text)
                        }
                    }
                }
            }
        }

        // Virtual keyboard using existing component
        Keyboard {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            target: passwordInput
            opened: passwordDialog.visible && networkPage.keyboardOpened
            z: 1001
        }

        // Functions
        function show() {
            passwordDialog.visible = true
            passwordInput.focus = true
            passwordInput.text = ""
            passwordDialog.showPassword = false
            connectionStatus = ""
            networkPage.keyboardOpened = true
        }

        function hide() {
            passwordDialog.visible = false
            networkPage.keyboardOpened = false
        }
    }

    // Helper functions
    function connectToNetwork(network) {
        if (!wifiEnabled) return
        
        if (network.secured) {
            passwordDialog.targetSSID = network.ssid
            passwordDialog.show()
        } else {
            performConnection(network.ssid, "")
        }
    }

    function performConnection(ssid, password) {
        isConnecting = true
        connectionStatus = ""
        
        console.log("Attempting to connect to:", ssid)
        
        // Use real backend connection to connect to actual device WiFi
        let success = backend.connectToNetwork(ssid, password)
        
        if (success) {
            console.log("Connection successful!")
            isConnected = true
            currentSSID = ssid
            networkPage.wifiConfigured(true)
            
            // Refresh networks to update the list
            loadNetworks()
        } else {
            console.log("Connection failed!")
            connectionStatus = "incorrect"
            isConnected = false
            currentSSID = ""
            networkPage.wifiConfigured(false)
        }
        
        isConnecting = false
    }

    // Load networks from backend
    function loadNetworks() {
        // First, check WiFi radio status (enabled/disabled)
        let wifiRadioEnabled = backend.isWifiEnabled()
        
        // Update WiFi toggle to reflect actual radio status
        wifiSwitch.checked = wifiRadioEnabled
        wifiEnabled = wifiRadioEnabled
        
        if (!wifiRadioEnabled) {
            // WiFi is disabled, clear everything
            availableNetworks = []
            isConnected = false
            currentSSID = ""
            console.log("WiFi radio is disabled")
            return
        }
        
        // WiFi is enabled, get networks
        let networks = backend.getAvailableNetworks()
        let otherNetworks = []
        
        // Check current connection status
        isConnected = backend.getWifiConnected()
        if (isConnected) {
            currentSSID = backend.getCurrentNetwork()
        }
        
        for (let i = 0; i < networks.length; i++) {
            let network = networks[i]
            let networkObj = {
                ssid: network.ssid,
                strength: Math.floor(network.signal_strength / 25), // Convert to 1-4 scale
                secured: network.secured,
                connected: network.connected || false
            }
            
            // Only add networks that are NOT currently connected
            if (!network.connected && network.ssid !== currentSSID) {
                otherNetworks.push(networkObj)
            }
        }
        
        // Sort other networks by signal strength (strongest first)
        otherNetworks.sort((a, b) => b.strength - a.strength)
        
        // Only show non-connected networks in the list
        availableNetworks = otherNetworks
        
        console.log("WiFi radio enabled:", wifiRadioEnabled, "Loaded", availableNetworks.length, "networks, connected to:", currentSSID)
    }
    


    // Initialize page
    Component.onCompleted: {
        // Load networks immediately when page opens
        loadNetworks()
        
        // Refresh networks every 10 seconds
        refreshTimer.start()
    }
    
    // Load networks when page becomes visible
    onVisibleChanged: {
        if (visible) {
            console.log("Network page became visible, loading networks...")
            loadNetworks()
        }
    }
    
    // Timer to refresh networks
    Timer {
        id: refreshTimer
        interval: 10000 // 10 seconds
        repeat: true
        onTriggered: {
            if (wifiEnabled) {
                loadNetworks()
            }
        }
    }




}
