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
    property string systemInfo: ""
    property string uptime: ""
    property string loadAverage: ""
    
    // ===== Background =====
    Image {
        anchors.fill: parent
        source: "qrc:/assets/images/background.png"
        fillMode: Image.PreserveAspectCrop
        z: 0
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
            MouseArea { anchors.fill: parent; onClicked: monitorPage.backRequested() }
        }

        // Title
        Text {
            anchors.centerIn: parent
            text: "SYSTEM MONITOR"
            color: "#2C3E50"
            font.pixelSize: 28; font.bold: true
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
                systemInfo = metrics.systemInfo || ""
                uptime = metrics.uptime || ""
                loadAverage = metrics.loadAverage || ""
                
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
            backend.startSystemMonitoring()
            loadSystemMetrics()
        } else {
            backend.stopSystemMonitoring()
        }
    }
    
    // Load initial metrics
    Component.onCompleted: {
        backend.startSystemMonitoring()
        loadSystemMetrics()
    }

    ColumnLayout {
        anchors.top: headerSection.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        anchors.topMargin: 30
        spacing: 25
        z: 1

        // Top row: CPU Usage and CPU Temperature
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            // CPU Usage Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                radius: 20
                color: "#FFFFFF"
                border.color: "#E0E0E0"
                border.width: 2
                
                // Drop shadow effect
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 3
                    anchors.leftMargin: 3
                    radius: 20
                    color: "#10000000"
                    z: -1
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    RowLayout {
                        Layout.fillWidth: true
                        
                        Image {
                            source: "qrc:/assets/icons/cpu.png"
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            fillMode: Image.PreserveAspectFit
                        }
                        
                        Label {
                            text: "CPU USAGE"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#2C3E50"
                            Layout.fillWidth: true
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        // CPU Circular Progress
                        Rectangle {
                            anchors.centerIn: parent
                            width: 100
                            height: 100
                            radius: 50
                            color: "transparent"
                            border.width: 8
                            border.color: "#F5F5F5"
                        }
                        
                        Canvas {
                            id: cpuGaugeCanvas
                            anchors.centerIn: parent
                            width: 100
                            height: 100
                            
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                
                                var centerX = width / 2
                                var centerY = height / 2
                                var radius = 42
                                var startAngle = -Math.PI / 2
                                var endAngle = startAngle + (cpuUsage / 100) * 2 * Math.PI
                                
                                // Draw progress arc
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius, startAngle, endAngle)
                                ctx.lineWidth = 8
                                ctx.strokeStyle = "#E74C3C"
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
                            font.pixelSize: 22
                            font.bold: true
                            color: "#2C3E50"
                        }
                    }
                }
            }

            // CPU Temperature Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                radius: 20
                color: "#FFFFFF"
                border.color: "#E0E0E0"
                border.width: 2
                
                // Drop shadow effect
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 3
                    anchors.leftMargin: 3
                    radius: 20
                    color: "#10000000"
                    z: -1
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    RowLayout {
                        Layout.fillWidth: true
                        
                        Image {
                            source: "qrc:/assets/icons/temp.png"
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            fillMode: Image.PreserveAspectFit
                        }
                        
                        Label {
                            text: "TEMPERATURE"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#2C3E50"
                            Layout.fillWidth: true
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        // Temperature Circular Progress
                        Rectangle {
                            anchors.centerIn: parent
                            width: 100
                            height: 100
                            radius: 50
                            color: "transparent"
                            border.width: 8
                            border.color: "#F5F5F5"
                        }
                        
                        Canvas {
                            id: tempGaugeCanvas
                            anchors.centerIn: parent
                            width: 100
                            height: 100
                            
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                
                                var centerX = width / 2
                                var centerY = height / 2
                                var radius = 42
                                var startAngle = -Math.PI / 2
                                var tempPercent = Math.min(cpuTemp / 100, 1.0) // Max 100°C
                                var endAngle = startAngle + tempPercent * 2 * Math.PI
                                
                                // Draw progress arc
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius, startAngle, endAngle)
                                ctx.lineWidth = 8
                                ctx.strokeStyle = "#F39C12"
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
                            font.pixelSize: 20
                            font.bold: true
                            color: "#2C3E50"
                        }
                    }
                }
            }
        }

        // Bottom row: RAM and Storage
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            // RAM Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                radius: 20
                color: "#FFFFFF"
                border.color: "#E0E0E0"
                border.width: 2
                
                // Drop shadow effect
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 3
                    anchors.leftMargin: 3
                    radius: 20
                    color: "#10000000"
                    z: -1
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    RowLayout {
                        Layout.fillWidth: true
                        
                        Image {
                            source: "qrc:/assets/icons/ram.png"
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            fillMode: Image.PreserveAspectFit
                        }
                        
                        Label {
                            text: "RAM USAGE"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#2C3E50"
                            Layout.fillWidth: true
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        // RAM Circular Progress
                        Rectangle {
                            anchors.centerIn: parent
                            width: 100
                            height: 100
                            radius: 50
                            color: "transparent"
                            border.width: 8
                            border.color: "#F5F5F5"
                        }
                        
                        Canvas {
                            id: ramGaugeCanvas
                            anchors.centerIn: parent
                            width: 100
                            height: 100
                            
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                
                                var centerX = width / 2
                                var centerY = height / 2
                                var radius = 42
                                var startAngle = -Math.PI / 2
                                var ramPercent = ramUsage / 100
                                var endAngle = startAngle + ramPercent * 2 * Math.PI
                                
                                // Draw progress arc
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius, startAngle, endAngle)
                                ctx.lineWidth = 8
                                ctx.strokeStyle = "#27AE60"
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
                            font.pixelSize: 22
                            font.bold: true
                            color: "#2C3E50"
                        }
                    }
                }
            }

            // Storage Card  
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                radius: 20
                color: "#FFFFFF"
                border.color: "#E0E0E0"
                border.width: 2
                
                // Drop shadow effect
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 3
                    anchors.leftMargin: 3
                    radius: 20
                    color: "#10000000"
                    z: -1
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    RowLayout {
                        Layout.fillWidth: true
                        
                        Image {
                            source: "qrc:/assets/icons/storage.png"
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            fillMode: Image.PreserveAspectFit
                        }
                        
                        Label {
                            text: "STORAGE"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#2C3E50"
                            Layout.fillWidth: true
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        // Storage Circular Progress
                        Rectangle {
                            anchors.centerIn: parent
                            width: 100
                            height: 100
                            radius: 50
                            color: "transparent"
                            border.width: 8
                            border.color: "#F5F5F5"
                        }
                        
                        Canvas {
                            id: storageGaugeCanvas
                            anchors.centerIn: parent
                            width: 100
                            height: 100
                            
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                
                                var centerX = width / 2
                                var centerY = height / 2
                                var radius = 42
                                var startAngle = -Math.PI / 2
                                var storagePercent = storageUsage / 100
                                var endAngle = startAngle + storagePercent * 2 * Math.PI
                                
                                // Draw progress arc
                                ctx.beginPath()
                                ctx.arc(centerX, centerY, radius, startAngle, endAngle)
                                ctx.lineWidth = 8
                                ctx.strokeStyle = "#3498DB"
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
                            font.pixelSize: 22
                            font.bold: true
                            color: "#2C3E50"
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true } // Fill remaining space
    }
}
