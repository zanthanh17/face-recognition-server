// ui/pages/SystemMonitor.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Item {
    id: monitorPage
    signal backRequested()
    
    property bool wifiConnected: true // Will be set from parent
    
    // System monitoring data from backend
    property real cpuUsage: 0
    property real cpuTemp: 0
    property real ramUsage: 0
    property real storageUsage: 0
    property real networkUsage: 0
    property string systemInfo: ""
    property string uptime: ""
    property string loadAverage: ""
    
    // Network speed history for chart (15 data points)
    property var networkHistory: []

    HeaderBar {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        wifiConnected: monitorPage.wifiConnected
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
            onClicked: monitorPage.backRequested()
        }

        Label {
            text: "System monitor"
            font.pixelSize: 20
            font.bold: true
            color: "#333"
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Load system metrics from backend
    function loadSystemMetrics() {
        try {
            let metrics = backend.getSystemMetrics()
            if (metrics) {
                // Safely convert values to numbers
                cpuUsage = Number(metrics.cpu) || 0
                
                // Handle temperature which might be "N/A" or a number
                let temp = metrics.temperature
                if (typeof temp === "string" && temp === "N/A") {
                    cpuTemp = 0
                } else {
                    cpuTemp = Number(temp) || 0
                }
                
                ramUsage = Number(metrics.memory) || 0
                storageUsage = Number(metrics.storage) || 0
                networkUsage = Number(metrics.network) || 0
                systemInfo = metrics.systemInfo || ""
                uptime = metrics.uptime || ""
                loadAverage = metrics.loadAverage || ""
                
                // Update network history
                if (networkHistory.length >= 15) {
                    networkHistory.shift()
                }
                networkHistory.push(networkUsage)
                
                console.log("System metrics updated successfully")
            }
        } catch (error) {
            console.log("Error loading system metrics:", error)
        }
    }
    
    // Timer to refresh metrics
    Timer {
        interval: 2000 // 2 seconds
        running: true
        repeat: true
        onTriggered: loadSystemMetrics()
    }
    
    // Load metrics when page becomes visible
    onVisibleChanged: {
        if (visible) {
            loadSystemMetrics()
        }
    }
    
    // Load initial metrics
    Component.onCompleted: {
        loadSystemMetrics()
    }

    ColumnLayout {
        anchors.top: titleRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        spacing: 16

            // Top row: CPU Usage and CPU Temperature
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // CPU Usage Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#E0E0E0"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 4
                                color: "#FF6B35"
                                
                                Label {
                                    anchors.centerIn: parent
                                    text: "⚡"
                                    color: "white"
                                    font.pixelSize: 12
                                }
                            }
                            
                            Label {
                                text: "CPU"
                                font.pixelSize: 16
                                font.bold: true
                                color: "#333"
                                Layout.fillWidth: true
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            // CPU Circular Progress
                            Rectangle {
                                id: cpuGaugeBackground
                                anchors.centerIn: parent
                                width: 70
                                height: 70
                                radius: 35
                                color: "transparent"
                                border.width: 6
                                border.color: "#F5F5F5"
                            }
                            
                            Canvas {
                                id: cpuGaugeCanvas
                                anchors.centerIn: parent
                                width: 70
                                height: 70
                                
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    
                                    var centerX = width / 2
                                    var centerY = height / 2
                                    var radius = 29
                                    var startAngle = -Math.PI / 2
                                    var endAngle = startAngle + (cpuUsage / 100) * 2 * Math.PI
                                    
                                    // Draw progress arc
                                    ctx.beginPath()
                                    ctx.arc(centerX, centerY, radius, startAngle, endAngle)
                                    ctx.lineWidth = 6
                                    ctx.strokeStyle = "#FF4444"
                                    ctx.lineCap = "round"
                                    ctx.stroke()
                                }
                                
                                Connections {
                                    target: monitorPage
                                    function onCpuUsageChanged() { cpuGaugeCanvas.requestPaint() }
                                }
                            }
                            
                            Label {
                                anchors.centerIn: parent
                                text: Math.round(cpuUsage) + "%"
                                font.pixelSize: 18
                                font.bold: true
                                color: "#333"
                            }
                        }
                    }
                }

                // CPU Temperature Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#E0E0E0"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 4
                                color: "#4FC3F7"
                                
                                Label {
                                    anchors.centerIn: parent
                                    text: "🌡"
                                    color: "white"
                                    font.pixelSize: 12
                                }
                            }
                            
                            Label {
                                text: "TEMP"
                                font.pixelSize: 16
                                font.bold: true
                                color: "#333"
                                Layout.fillWidth: true
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            // Temperature Circular Progress
                            Rectangle {
                                anchors.centerIn: parent
                                width: 70
                                height: 70
                                radius: 35
                                color: "transparent"
                                border.width: 6
                                border.color: "#F5F5F5"
                            }
                            
                            Canvas {
                                id: tempGaugeCanvas
                                anchors.centerIn: parent
                                width: 70
                                height: 70
                                
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    
                                    var centerX = width / 2
                                    var centerY = height / 2
                                    var radius = 29
                                    var startAngle = -Math.PI / 2
                                    var tempPercent = Math.min(cpuTemp / 100, 1.0) // Max 100°C
                                    var endAngle = startAngle + tempPercent * 2 * Math.PI
                                    
                                    // Draw progress arc
                                    ctx.beginPath()
                                    ctx.arc(centerX, centerY, radius, startAngle, endAngle)
                                    ctx.lineWidth = 6
                                    ctx.strokeStyle = "#FFD54F"
                                    ctx.lineCap = "round"
                                    ctx.stroke()
                                }
                                
                                Connections {
                                    target: monitorPage
                                    function onCpuTempChanged() { tempGaugeCanvas.requestPaint() }
                                }
                            }
                            
                            Label {
                                anchors.centerIn: parent
                                text: cpuTemp > 0 ? Math.round(cpuTemp) + "°C" : "N/A"
                                font.pixelSize: 16
                                font.bold: true
                                color: "#333"
                            }
                        }
                    }
                }
            }

            // Middle row: RAM and Storage
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // RAM Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#E0E0E0"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 4
                                color: "#66BB6A"
                                
                                Label {
                                    anchors.centerIn: parent
                                    text: "🧠"
                                    color: "white"
                                    font.pixelSize: 12
                                }
                            }
                            
                            Label {
                                text: "RAM"
                                font.pixelSize: 16
                                font.bold: true
                                color: "#333"
                                Layout.fillWidth: true
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            // RAM Circular Progress
                            Rectangle {
                                anchors.centerIn: parent
                                width: 70
                                height: 70
                                radius: 35
                                color: "transparent"
                                border.width: 6
                                border.color: "#F5F5F5"
                            }
                            
                            Canvas {
                                id: ramGaugeCanvas
                                anchors.centerIn: parent
                                width: 70
                                height: 70
                                
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    
                                    var centerX = width / 2
                                    var centerY = height / 2
                                    var radius = 29
                                    var startAngle = -Math.PI / 2
                                    var ramPercent = ramUsage / 100
                                    var endAngle = startAngle + ramPercent * 2 * Math.PI
                                    
                                    // Draw progress arc
                                    ctx.beginPath()
                                    ctx.arc(centerX, centerY, radius, startAngle, endAngle)
                                    ctx.lineWidth = 6
                                    ctx.strokeStyle = "#4CAF50"
                                    ctx.lineCap = "round"
                                    ctx.stroke()
                                }
                                
                                Connections {
                                    target: monitorPage
                                    function onRamUsageChanged() { ramGaugeCanvas.requestPaint() }
                                }
                            }
                            
                            Label {
                                anchors.centerIn: parent
                                text: Math.round(ramUsage) + "%"
                                font.pixelSize: 12
                                font.bold: true
                                color: "#333"
                            }
                        }
                    }
                }

                // Storage Card  
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: 16
                    color: "#FFFFFF"
                    border.color: "#E0E0E0"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 4
                                color: "#29B6F6"
                                
                                Label {
                                    anchors.centerIn: parent
                                    text: "💾"
                                    color: "white"
                                    font.pixelSize: 12
                                }
                            }
                            
                            Label {
                                text: "Storage"
                                font.pixelSize: 16
                                font.bold: true
                                color: "#333"
                                Layout.fillWidth: true
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            // Storage Circular Progress
                            Rectangle {
                                anchors.centerIn: parent
                                width: 70
                                height: 70
                                radius: 35
                                color: "transparent"
                                border.width: 6
                                border.color: "#F5F5F5"
                            }
                            
                            Canvas {
                                id: storageGaugeCanvas
                                anchors.centerIn: parent
                                width: 70
                                height: 70
                                
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    
                                    var centerX = width / 2
                                    var centerY = height / 2
                                    var radius = 29
                                    var startAngle = -Math.PI / 2
                                    var storagePercent = storageUsage / 100
                                    var endAngle = startAngle + storagePercent * 2 * Math.PI
                                    
                                    // Draw progress arc
                                    ctx.beginPath()
                                    ctx.arc(centerX, centerY, radius, startAngle, endAngle)
                                    ctx.lineWidth = 6
                                    ctx.strokeStyle = "#03A9F4"
                                    ctx.lineCap = "round"
                                    ctx.stroke()
                                }
                                
                                Connections {
                                    target: monitorPage
                                    function onStorageUsageChanged() { storageGaugeCanvas.requestPaint() }
                                }
                            }
                            
                            Label {
                                anchors.centerIn: parent
                                text: Math.round(storageUsage) + "%"
                                font.pixelSize: 12
                                font.bold: true
                                color: "#333"
                            }
                        }
                    }
                }
            }

            // Bottom: Network Speed Chart
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                radius: 16
                color: "#FFFFFF"
                border.color: "#E0E0E0"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 4
                            color: "#AB47BC"
                            
                            Label {
                                anchors.centerIn: parent
                                text: "📶"
                                color: "white"
                                font.pixelSize: 12
                            }
                        }
                        
                        Label {
                            text: "Network Speed"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#333"
                            Layout.fillWidth: true
                        }
                        
                        Label {
                            text: "Usage: " + Math.round(networkUsage) + "%"
                            font.pixelSize: 14
                            color: "#AB47BC"
                            font.bold: true
                        }
                    }

                    // Network Speed Chart
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        Canvas {
                            id: networkChart
                            anchors.fill: parent
                            
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                
                                if (networkHistory.length === 0) return
                                
                                var margin = 10
                                var chartWidth = width - 2 * margin
                                var chartHeight = height - 2 * margin
                                var maxSpeed = Math.max(...networkHistory)
                                var minSpeed = Math.min(...networkHistory)
                                var speedRange = maxSpeed - minSpeed
                                
                                if (speedRange === 0) speedRange = 1
                                
                                // Draw grid lines
                                ctx.strokeStyle = "#F0F0F0"
                                ctx.lineWidth = 1
                                
                                // Horizontal grid lines
                                for (var i = 0; i <= 5; i++) {
                                    var y = margin + (chartHeight * i / 5)
                                    ctx.beginPath()
                                    ctx.moveTo(margin, y)
                                    ctx.lineTo(width - margin, y)
                                    ctx.stroke()
                                }
                                
                                // Vertical grid lines
                                for (var j = 0; j < networkHistory.length; j++) {
                                    var x = margin + (chartWidth * j / (networkHistory.length - 1))
                                    ctx.beginPath()
                                    ctx.moveTo(x, margin)
                                    ctx.lineTo(x, height - margin)
                                    ctx.stroke()
                                }
                                
                                // Draw area fill
                                ctx.beginPath()
                                for (var k = 0; k < networkHistory.length; k++) {
                                    var xPos = margin + (chartWidth * k / (networkHistory.length - 1))
                                    var normalizedValue = (networkHistory[k] - minSpeed) / speedRange
                                    var yPos = height - margin - (chartHeight * normalizedValue)
                                    
                                    if (k === 0) {
                                        ctx.moveTo(xPos, height - margin)
                                        ctx.lineTo(xPos, yPos)
                                    } else {
                                        ctx.lineTo(xPos, yPos)
                                    }
                                }
                                ctx.lineTo(width - margin, height - margin)
                                ctx.closePath()
                                
                                var gradient = ctx.createLinearGradient(0, margin, 0, height - margin)
                                gradient.addColorStop(0, "rgba(171, 71, 188, 0.3)")
                                gradient.addColorStop(1, "rgba(171, 71, 188, 0.1)")
                                ctx.fillStyle = gradient
                                ctx.fill()
                                
                                // Draw line
                                ctx.beginPath()
                                for (var l = 0; l < networkHistory.length; l++) {
                                    var xLine = margin + (chartWidth * l / (networkHistory.length - 1))
                                    var normalizedLine = (networkHistory[l] - minSpeed) / speedRange
                                    var yLine = height - margin - (chartHeight * normalizedLine)
                                    
                                    if (l === 0) {
                                        ctx.moveTo(xLine, yLine)
                                    } else {
                                        ctx.lineTo(xLine, yLine)
                                    }
                                }
                                ctx.strokeStyle = "#AB47BC"
                                ctx.lineWidth = 2
                                ctx.stroke()
                            }
                            
                            Connections {
                                target: monitorPage
                                function onNetworkHistoryChanged() { networkChart.requestPaint() }
                            }
                        }
                    }
                }
            }

        Item { Layout.fillHeight: true } // Fill remaining space
    }
}
