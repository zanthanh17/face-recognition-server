// main.qml
import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Window {
    id: root
    width: 360
    height: 640
    visible: true
    color: "#f4e8e8"
    title: qsTr("Facelog")

    // Global WiFi state management
    property bool globalWifiConnected: false
    
    // Initialize WiFi status when app starts
    Component.onCompleted: {
        // Check initial WiFi status from backend
        globalWifiConnected = backend.getWifiConnected()
        console.log("Initial WiFi status:", globalWifiConnected)
    }
    
    // Timer to periodically check WiFi status
    Timer {
        interval: 5000 // Check every 5 seconds
        running: true
        repeat: true
        onTriggered: {
            // Only check WiFi status if WiFi radio is enabled
            if (backend.isWifiEnabled()) {
                let currentStatus = backend.getWifiConnected()
                if (currentStatus !== globalWifiConnected) {
                    globalWifiConnected = currentStatus
                    console.log("WiFi status updated:", globalWifiConnected)
                }
            } else {
                // WiFi radio is disabled, so we're definitely not connected
                if (globalWifiConnected !== false) {
                    globalWifiConnected = false
                    console.log("WiFi radio disabled, setting status to disconnected")
                }
            }
        }
    }
    


    StackView {
        id: stack
        anchors.fill: parent
        initialItem: loginComponent
    }

    // ---------- Login ----------
    Component {
        id: loginComponent
        Item {
            Loader {
                id: loginLoader
                anchors.fill: parent
                source: "qrc:/ui/pages/Login.qml"
            }
            Connections {
                target: loginLoader.item
                ignoreUnknownSignals: true
                function onOpenSettingsRequested() {
                    if (loginLoader.item && loginLoader.item.deactivateCamera)
                        loginLoader.item.deactivateCamera()
                    stack.push(settingsComponent)
                }
            }
        }
    }

    // ---------- Setting (nhập pass) ----------
    Component {
        id: settingsComponent
        Item {
            Loader {
                id: settingsLoader
                anchors.fill: parent
                source: "qrc:/ui/pages/Setting.qml"
                onLoaded: {
                    if (item) item.wifiConnected = Qt.binding(() => root.globalWifiConnected)
                }
            }
            Connections {
                target: settingsLoader.item
                ignoreUnknownSignals: true
                function onBackRequested() { stack.pop() }
                function onPasswordAuthenticated() { stack.push(settingAdminComponent) }
            }
        }
    }

    // ---------- SettingAdmin (menu admin) ----------
    Component {
        id: settingAdminComponent
        Item {
            Loader {
                id: settingAdminLoader
                anchors.fill: parent
                source: "qrc:/ui/pages/SettingAdmin.qml"
                onLoaded: {
                    if (item) item.wifiConnected = Qt.binding(() => root.globalWifiConnected)
                }
            }
            Connections {
                target: settingAdminLoader.item
                ignoreUnknownSignals: true
                function onBackRequested() { stack.pop() }
                function onEditUserInfoClicked() { 
                    stack.push(editUserComponent) 
                }
                function onNetworkSettingsClicked() { 
                    stack.push(networkSettingsComponent) 
                }
                function onHistoryClicked() {
                    stack.push(historyComponent)
                }
                function onMonitorClicked() {
                    stack.push(systemMonitorComponent)
                }
                // function onBoxSettingsClicked() { stack.push(boxComponent) }
                // function onLogsClicked() { stack.push(logsComponent) }
            }
        }
    }

    // ---------- EditUser (từ SettingAdmin) ----------
    Component {
        id: editUserComponent
        Item {
            Loader {
                id: editUserLoader
                anchors.fill: parent
                source: "qrc:/ui/pages_component/EditUser.qml"
                onLoaded: {
                    if (item) item.wifiConnected = Qt.binding(() => root.globalWifiConnected)
                }
            }
            Connections {
                target: editUserLoader.item
                ignoreUnknownSignals: true
                function onBackRequested() { stack.pop() }
                // Khi chọn user trong danh sách, chuyển sang UserInfor
                function onUserClicked(uid, name, dept, avatar) {
                    stack.push(userDetailComponent, {
                        userId: uid,
                        userName: name,
                        userDepartment: dept,
                        userAvatar: avatar
                    })
                }
            }
        }
    }

    // ---------- UserInfor (chi tiết user) ----------
    Component {
        id: userDetailComponent
        Item {
            id: userDetailRoot
            // These get set via StackView.push(..., { props })
            property string userId: ""
            property string userName: ""
            property string userDepartment: ""
            property url userAvatar: "qrc:/assets/images/user.png"

            Loader {
                id: userInforLoader
                anchors.fill: parent
                source: "qrc:/ui/pages_component/UserInfor.qml"
                onLoaded: {
                    if (!item) return
                    item.userId = userDetailRoot.userId
                    item.userName = userDetailRoot.userName
                    item.userDepartment = userDetailRoot.userDepartment
                    item.userAvatar = userDetailRoot.userAvatar
                    item.wifiConnected = Qt.binding(() => root.globalWifiConnected)
                }
            }
            onUserAvatarChanged: {
                if (userInforLoader.item) userInforLoader.item.userAvatar = userDetailRoot.userAvatar
            }
            Connections {
                target: userInforLoader.item
                ignoreUnknownSignals: true
                function onBackRequested() { stack.pop() }
                function onEditRequested(userId) {
                    // Deprecated: now using openCaptureRequested
                    stack.push(captureFaceComponent, {
                        userId: userDetailRoot.userId,
                        userName: userDetailRoot.userName,
                        userDepartment: userDetailRoot.userDepartment,
                        currentAvatar: userDetailRoot.userAvatar
                    })
                }
                function onOpenCaptureRequested(userId, name, dept, currentAvatar) {
                    stack.push(captureFaceComponent, {
                        userId: userDetailRoot.userId,
                        userName: userDetailRoot.userName,
                        userDepartment: userDetailRoot.userDepartment,
                        currentAvatar: userDetailRoot.userAvatar
                    })
                }
            }
        }
    }

    // ---------- CaptureFace (chụp mặt) ----------
    Component {
        id: captureFaceComponent
        Item {
            id: captureRoot
            // Props passed from previous page
            property string userId: ""
            property string userName: ""
            property string userDepartment: ""
            property url currentAvatar: "qrc:/assets/images/user.png"

            focus: true

            Loader {
                id: captureLoader
                anchors.fill: parent
                source: "qrc:/ui/pages_component/CaptureFace.qml"
                onLoaded: {
                    if (!item) return
                    item.userId = captureRoot.userId
                    item.userName = captureRoot.userName
                    item.userDepartment = captureRoot.userDepartment
                    item.currentAvatar = captureRoot.currentAvatar
                }
            }
            Connections {
                target: captureLoader.item
                ignoreUnknownSignals: true
                function onBackRequested() { stack.pop() }
                function onCaptureAccepted(newAvatarUrl) {
                    // Pop back to UserInfor and update avatar there
                    stack.pop()
                    if (stack.currentItem && stack.currentItem.userAvatar !== undefined) {
                        stack.currentItem.userAvatar = newAvatarUrl
                    }
                }
            }
        }
    }

    // ---------- NetworkSettings (từ SettingAdmin) ----------
    Component {
        id: networkSettingsComponent
        Item {
            Loader {
                id: networkSettingsLoader
                anchors.fill: parent
                source: "qrc:/ui/pages/NetworkSettings.qml"
            }
            Connections {
                target: networkSettingsLoader.item
                ignoreUnknownSignals: true
                function onBackRequested() { stack.pop() }
                function onWifiConfigured(success) {
                    root.globalWifiConnected = success
                    console.log("WiFi status changed:", success)
                }
            }
        }
    }

    // ---------- History (từ SettingAdmin) ----------
    Component {
        id: historyComponent
        Item {
            Loader {
                id: historyLoader
                anchors.fill: parent
                source: "qrc:/ui/pages/History.qml"
                onLoaded: {
                    if (item) item.wifiConnected = Qt.binding(() => root.globalWifiConnected)
                }
            }
            Connections {
                target: historyLoader.item
                ignoreUnknownSignals: true
                function onBackRequested() { stack.pop() }
            }
        }
    }

    // ---------- SystemMonitor (từ SettingAdmin) ----------
    Component {
        id: systemMonitorComponent
        Item {
            Loader {
                id: systemMonitorLoader
                anchors.fill: parent
                source: "qrc:/ui/pages/SystemMonitor.qml"
                onLoaded: {
                    if (item) item.wifiConnected = Qt.binding(() => root.globalWifiConnected)
                }
            }
            Connections {
                target: systemMonitorLoader.item
                ignoreUnknownSignals: true
                function onBackRequested() { stack.pop() }
            }
        }
    }
}
