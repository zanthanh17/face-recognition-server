// main.qml
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    width: 480
    height: 800
    visible: true
    color: "#f4e8e8"
    title: qsTr("Facelog")
    // Fullscreen for embedded display
    // visibility: Window.FullScreen

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
        initialItem: homeComponent
    }

    // ---------- Home ----------
    Component {
        id: homeComponent
        Item {
            Loader {
                id: homeLoader
                anchors.fill: parent
                source: "qrc:/ui/pages/Home.qml"
            }
            Connections {
                target: homeLoader.item
                ignoreUnknownSignals: true
                function onOpenSettingsRequested() {
                    console.log("Home: Opening settings admin - deactivating camera")
                    if (homeLoader.item && homeLoader.item.deactivateCamera)
                        homeLoader.item.deactivateCamera()
                    stack.push(settingAdminComponent)
                }
                function onStartFaceRecognition() {
                    console.log("Starting face recognition - switching to Login page")
                    stack.push(loginComponent)
                }
                function onOpenNumericKeypad() {
                    console.log("Opening numeric keypad")
                    stack.push(numericKeypadComponent)
                }
                function onOpenUserListRequested() {
                    console.log("Home: Opening user list")
                    stack.push(editUserComponent)
                }
                function onOpenHistoryRequested() {
                    console.log("Home: Opening history")
                    stack.push(historyComponent)
                }
            }
        }
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
                    console.log("Login: Opening settings admin - deactivating camera")
                    if (loginLoader.item && loginLoader.item.deactivateCamera)
                        loginLoader.item.deactivateCamera()
                    stack.push(settingAdminComponent)
                }
                function onBackToHomeRequested() {
                    console.log("Login: Going back to Home - deactivating camera")
                    if (loginLoader.item && loginLoader.item.deactivateCamera)
                        loginLoader.item.deactivateCamera()
                    stack.pop()
                }
            }
            
            // Handle when Login page is about to be destroyed
            Component.onDestruction: {
                console.log("Login component being destroyed - ensuring camera is stopped")
                if (loginLoader.item && loginLoader.item.deactivateCamera) {
                    loginLoader.item.deactivateCamera()
                }
            }
        }
    }

    // ---------- NumericKeypad ----------
    Component {
        id: numericKeypadComponent
        Item {
            Loader {
                id: numericKeypadLoader
                anchors.fill: parent
                source: "qrc:/ui/pages/NumericKeypad.qml"
            }
            Connections {
                target: numericKeypadLoader.item
                ignoreUnknownSignals: true
                function onBackToHomeRequested() {
                    console.log("NumericKeypad: Going back to Home")
                    stack.pop()
                }
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
                function onNetworkSettingsClicked() { 
                    stack.push(networkSettingsComponent) 
                }
                function onChangePasswordClicked() {
                    stack.push(changePasswordComponent)
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
                    // Redirect to Login page for face capture
                    console.log("Redirecting to Login page for face capture")
                    stack.push(loginComponent)
                }
                function onOpenCaptureRequested(userId, name, dept, currentAvatar) {
                    // Redirect to Login page for face capture
                    console.log("Redirecting to Login page for face capture")
                    stack.push(loginComponent)
                }
            }
        }
    }

    // CaptureFace component removed - using Login page instead

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

    // ---------- ChangePassword (từ SettingAdmin) ----------
    Component {
        id: changePasswordComponent
        Item {
            Loader {
                id: changePasswordLoader
                anchors.fill: parent
                source: "qrc:/ui/pages/ChangePass.qml"
                onLoaded: {
                    if (item) item.wifiConnected = Qt.binding(() => root.globalWifiConnected)
                }
            }
            Connections {
                target: changePasswordLoader.item
                ignoreUnknownSignals: true
                function onBackRequested() { stack.pop() }
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
