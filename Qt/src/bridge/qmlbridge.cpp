#include "qmlbridge.h"
#include "../database/databasemanager.h"
#include "../services/usermanager.h"
#include "../services/cameramanager.h"
#include "../services/systemmonitor.h"
#include "../services/networkmanager.h"
#include "../services/facerecognitionservice.h"
#include "../services/cachemanager.h"
#include <QDateTime>
#include <QDebug>
#include <QBuffer>
#include <QFile>
#include <QCoreApplication>
#include <QSettings>
#include <QTimer>

QmlBridge::QmlBridge(QObject *parent)
    : QObject(parent)
    , m_databaseManager(nullptr)
    , m_userManager(nullptr)
    , m_cameraManager(nullptr)
    , m_systemMonitor(nullptr)
    , m_networkManager(nullptr)
    , m_faceRecognitionService(nullptr)
    , m_wifiConnected(false)
    , m_cameraAvailable(false)
{
    // Initialize services (no local database needed)
    m_cameraManager = new CameraManager(this);
    m_systemMonitor = new SystemMonitor(this);
    m_networkManager = new NetworkManager(this);
    m_faceRecognitionService = new FaceRecognitionService(this);
    m_cacheManager = new CacheManager(this);
    
    // Start system monitoring
    // startSystemMonitoring(); // Disabled to reduce log noise
    
    // Connect face recognition signals
    connect(m_faceRecognitionService, &FaceRecognitionService::faceRecognized,
            this, &QmlBridge::faceRecognized);
    connect(m_faceRecognitionService, &FaceRecognitionService::faceRecognitionFailed,
            this, &QmlBridge::faceRecognitionFailed);
    
    // Note: Recognition events are now handled in Login.qml to include captured images
    // Removed duplicate lambda connections to prevent duplicate logs
    connect(m_faceRecognitionService, &FaceRecognitionService::faceRegistrationSuccess,
            this, &QmlBridge::faceRegistrationSuccess);
    connect(m_faceRecognitionService, &FaceRecognitionService::faceRegistrationFailed,
            this, &QmlBridge::faceRegistrationFailed);
    connect(m_faceRecognitionService, &FaceRecognitionService::serverConnectionTested,
            this, &QmlBridge::serverConnectionTested);
    connect(m_faceRecognitionService, &FaceRecognitionService::attendanceHistoryUpdated,
            this, &QmlBridge::attendanceHistoryUpdated);
    connect(m_faceRecognitionService, &FaceRecognitionService::historyDataLoaded,
            this, &QmlBridge::historyDataLoaded);
    connect(m_faceRecognitionService, &FaceRecognitionService::historyDataLoadedJson,
            this, &QmlBridge::historyDataLoadedJson);
    connect(m_faceRecognitionService, &FaceRecognitionService::historyDataLoadFailed,
            this, &QmlBridge::historyDataLoadFailed);
    connect(m_faceRecognitionService, &FaceRecognitionService::usersUpdated,
            this, &QmlBridge::onUsersUpdated);
    connect(m_faceRecognitionService, &FaceRecognitionService::workHoursUpdated,
            this, &QmlBridge::workHoursUpdated);
    connect(m_faceRecognitionService, &FaceRecognitionService::workHoursSummaryUpdated,
            this, &QmlBridge::workHoursSummaryUpdated);
    
    // Connect system monitor signals
    connect(m_systemMonitor, &SystemMonitor::metricsUpdated,
            this, [this](const QVariantMap &metrics) {
                updateSystemMetrics(metrics);
            });
    
    // Connect cache manager signals
    connect(m_cacheManager, &CacheManager::cacheUpdated,
            this, &QmlBridge::cacheUpdated);
    connect(m_cacheManager, &CacheManager::unsyncedLogsChanged,
            this, &QmlBridge::unsyncedLogsChanged);
            
    qDebug() << "QmlBridge initialized - with cache support";
}

QmlBridge::~QmlBridge()
{
    stopSystemMonitoring();
    stopCamera();
}



QVariantList QmlBridge::getUsers()
{
    // Get users from server
    if (m_faceRecognitionService) {
        return m_faceRecognitionService->getUsersFromServer();
    }
    return QVariantList();
}

QVariantList QmlBridge::getUsersList() const
{
    // Return cached users list for QML property binding
    return m_users;
}

void QmlBridge::loadUsersFromBackend()
{
    // Load users from server (async)
    if (m_faceRecognitionService) {
        qDebug() << "Requesting users from server...";
        m_faceRecognitionService->getUsersFromServer();
    }
}

void QmlBridge::onUsersUpdated(const QVariantList &users)
{
    // Called when users are received from server
    m_users = users;
    emit usersChanged();
    qDebug() << "Updated users list with" << users.size() << "users from server";
}

QVariantMap QmlBridge::getUserById(int userId)
{
    // Get user from server by ID
    QVariantList users = getUsers();
    for (const QVariant &userVar : users) {
        QVariantMap user = userVar.toMap();
        if (user["id"].toInt() == userId) {
            return user;
        }
    }
    return QVariantMap();
}

QVariantMap QmlBridge::getUserByName(const QString &name)
{
    // Get user from server by name
    QVariantList users = getUsers();
    for (const QVariant &userVar : users) {
        QVariantMap user = userVar.toMap();
        if (user["name"].toString() == name) {
            return user;
        }
    }
    return QVariantMap();
}

bool QmlBridge::addUser(const QString &name, const QString &department, const QByteArray &faceEncoding)
{
    // Add user to server
    if (m_faceRecognitionService) {
        return m_faceRecognitionService->registerFaceWithServer(faceEncoding, name, department);
    }
    return false;
}



QVariantList QmlBridge::getHistoryLogs()
{
    // Get history from server
    if (m_faceRecognitionService) {
        return m_faceRecognitionService->getAttendanceHistory();
    }
    return QVariantList();
}

QVariantList QmlBridge::getRecognitionHistory()
{
    return m_recognitionHistory;
}



bool QmlBridge::saveSetting(const QString &key, const QString &value)
{
    // Save setting to local file or QSettings
    QSettings settings;
    settings.setValue(key, value);
    return true;
}

QString QmlBridge::getSetting(const QString &key, const QString &defaultValue) const
{
    // Get setting from local file or QSettings
    QSettings settings;
    return settings.value(key, defaultValue).toString();
}

bool QmlBridge::startCamera()
{
    if (m_cameraManager->startCamera()) {
        m_cameraAvailable = true;
        emit cameraAvailableChanged();
        return true;
    } else {
        emit cameraError("Failed to start camera");
        return false;
    }
}

void QmlBridge::stopCamera()
{
    m_cameraManager->stopCamera();
    m_cameraAvailable = false;
    emit cameraAvailableChanged();
}

QByteArray QmlBridge::captureImage()
{
    return m_cameraManager->captureImage();
}

bool QmlBridge::getCameraAvailable()
{
    return m_cameraAvailable;
}

QVariantMap QmlBridge::recognizeFace(const QByteArray &imageData)
{
    QVariantMap result = m_faceRecognitionService->recognizeFace(imageData);
    
    if (result.contains("success") && result["success"].toBool()) {
        QString userId = result["user_id"].toString();
        QString userName = result["user_name"].toString();
        emit faceRecognized(userId, userName);
    } else {
        emit faceRecognitionFailed();
    }
    
    return result;
}

bool QmlBridge::registerFace(const QByteArray &imageData, int userId)
{
    return m_faceRecognitionService->registerFace(imageData, userId);
}

QByteArray QmlBridge::extractFaceEncoding(const QByteArray &imageData)
{
    return m_faceRecognitionService->extractFaceEncoding(imageData);
}

// Server API operations
QVariantMap QmlBridge::recognizeFaceWithServer(const QByteArray &imageData, const QString &capturedImage)
{
    return m_faceRecognitionService->recognizeFaceWithServer(imageData, capturedImage);
}

bool QmlBridge::registerFaceWithServer(const QByteArray &imageData, const QString &name, const QString &position)
{
    return m_faceRecognitionService->registerFaceWithServer(imageData, name, position);
}

QVariantList QmlBridge::getAttendanceHistory()
{
    return m_faceRecognitionService->getAttendanceHistory();
}

void QmlBridge::loadHistoryData()
{
    // Load history data from server (async)
    if (m_faceRecognitionService) {
        qDebug() << "Requesting history data from server...";
        m_faceRecognitionService->getAttendanceHistory();
    }
}

QString QmlBridge::getHistoryDataAsJson()
{
    // Get history data as JSON string (synchronous)
    if (m_faceRecognitionService) {
        QVariantList history = m_faceRecognitionService->getAttendanceHistory();
        
        // Convert to JSON
        QJsonArray jsonArray;
        for (const QVariant &item : history) {
            jsonArray.append(QJsonValue::fromVariant(item));
        }
        QJsonDocument doc(jsonArray);
        QString jsonString = doc.toJson(QJsonDocument::Compact);
        
        qDebug() << "Returning history as JSON, length:" << jsonString.length();
        return jsonString;
    }
    return "[]";
}

void QmlBridge::addRecognitionEvent(const QString &userName, bool success)
{
    addRecognitionEventWithImage(userName, success, QString());
}

void QmlBridge::addRecognitionEventWithImage(const QString &userName, bool success, const QString &imageData)
{
    // Add recognition event to global history
    QDateTime now = QDateTime::currentDateTime();
    QString timestamp = now.toString("yyyy-MM-dd hh:mm:ss");
    
    qDebug() << "Adding recognition event - User:" << userName << "Success:" << success << "Time:" << timestamp;
    
    // Create event data
    QVariantMap event;
    event["name"] = userName;
    event["success"] = success;
    event["timestamp"] = timestamp;
    event["time"] = now.toString("hh:mm:ss");
    event["date"] = now.toString("yyyy-MM-dd");
    event["type"] = success ? "checkin" : "checkout";
    event["status"] = success ? "success" : "failed";
    
    // Add captured image if provided
    if (!imageData.isEmpty()) {
        event["captured_image"] = imageData;
        qDebug() << "Added captured image to recognition event";
    }
    
    // Add to beginning of global history
    m_recognitionHistory.prepend(event);
    
    // Keep only last 50 events
    if (m_recognitionHistory.size() > 50) {
        m_recognitionHistory = m_recognitionHistory.mid(0, 50);
    }
    
    qDebug() << "Global recognition history updated, total events:" << m_recognitionHistory.size();
    
    // Emit signals to notify QML
    emit recognitionEventAdded(userName, success, timestamp);
    emit recognitionHistoryChanged();
}

void QmlBridge::clearRecognitionHistory()
{
    qDebug() << "Clearing recognition history";
    m_recognitionHistory.clear();
    emit recognitionHistoryChanged();
}

QVariantList QmlBridge::getUsersFromServer()
{
    return m_faceRecognitionService->getUsersFromServer();
}

QVariantList QmlBridge::getWorkHours(const QString &date)
{
    return m_faceRecognitionService->getWorkHours(date);
}

QVariantList QmlBridge::getWorkHoursSummary(const QString &startDate, const QString &endDate)
{
    return m_faceRecognitionService->getWorkHoursSummary(startDate, endDate);
}

bool QmlBridge::testServerConnection(const QString &serverUrl)
{
    return m_faceRecognitionService->testServerConnection(serverUrl);
}

void QmlBridge::setServerUrl(const QString &url)
{
    m_faceRecognitionService->setServerUrl(url);
    saveSetting("server_url", url);
}

QString QmlBridge::getServerUrl() const
{
    return getSetting("server_url", m_faceRecognitionService->getServerUrl());
}

void QmlBridge::setDeviceId(const QString &deviceId)
{
    m_faceRecognitionService->setDeviceId(deviceId);
    saveSetting("device_id", deviceId);
}

QString QmlBridge::getDeviceId() const
{
    return getSetting("device_id", m_faceRecognitionService->getDeviceId());
}

QByteArray QmlBridge::readImageFile(const QString &filePath)
{
    QFile file(filePath);
    if (file.open(QIODevice::ReadOnly)) {
        return file.readAll();
    }
    return QByteArray();
}

QString QmlBridge::convertImageToBase64(const QImage &image)
{
    QByteArray imageData;
    QBuffer buffer(&imageData);
    buffer.open(QIODevice::WriteOnly);
    
    if (image.save(&buffer, "JPEG", 85)) {
        QString base64String = imageData.toBase64();
        qDebug() << "Converted image to base64, size:" << base64String.length();
        return base64String;
    } else {
        qDebug() << "Failed to convert image to base64";
        return QString();
    }
}

QString QmlBridge::cropImageToFaceFrame(const QImage &image, int frameWidth, int frameHeight)
{
    // Calculate the face frame area (center 78% of the image)
    int imageWidth = image.width();
    int imageHeight = image.height();
    
    // Face frame is 78% of the image size (as defined in Login.qml)
    int frameSize = qMin(imageWidth, imageHeight) * 0.78;
    
    // Calculate center position
    int x = (imageWidth - frameSize) / 2;
    int y = (imageHeight - frameSize) / 2;
    
    // Crop the image to the face frame area
    QImage croppedImage = image.copy(x, y, frameSize, frameSize);
    
    // Convert to base64
    QByteArray imageData;
    QBuffer buffer(&imageData);
    buffer.open(QIODevice::WriteOnly);
    
    if (croppedImage.save(&buffer, "JPEG", 85)) {
        QString base64String = imageData.toBase64();
        qDebug() << "Cropped image to face frame, size:" << base64String.length();
        return base64String;
    } else {
        qDebug() << "Failed to crop image to face frame";
        return QString();
    }
}

QString QmlBridge::getUserImage(const QString &userId)
{
    if (m_faceRecognitionService) {
        return m_faceRecognitionService->getUserImage(userId);
    }
    return QByteArray();
}

void QmlBridge::simulateRecognition()
{
    // Simulate face recognition for testing
    // In real implementation, this would capture current camera frame
    // and send to server for recognition
    
    // Simulate successful recognition
    emit m_faceRecognitionService->faceRecognized("test-user-id", "Test User");
}

void QmlBridge::captureAndRecognize()
{
    // Capture current camera frame and send to server for recognition
    if (!m_cameraManager || !m_cameraManager->isCameraAvailable()) {
        qDebug() << "Camera not available";
        emit faceRecognitionFailed();
        return;
    }

    // Make sure camera is started
    if (!m_cameraManager->isCameraRunning()) {
        qDebug() << "Starting camera...";
        if (!m_cameraManager->startCamera()) {
            qDebug() << "Failed to start camera";
            emit faceRecognitionFailed();
            return;
        }
        // Wait a bit for camera to initialize
        QTimer::singleShot(3000, [this]() {
            captureAndRecognize();
        });
        return;
    }

    // Check if image capture is ready
    if (!m_cameraManager->isImageCaptureReady()) {
        qDebug() << "Image capture not ready, waiting...";
        QTimer::singleShot(1000, [this]() {
            captureAndRecognize();
        });
        return;
    }

    qDebug() << "Starting camera capture...";
    
    // Start camera capture (this is asynchronous)
    QByteArray imageData = m_cameraManager->captureImage();
    
    if (imageData.isEmpty()) {
        qDebug() << "Camera capture started (asynchronous) - waiting for result...";
        // The capture is asynchronous, so we need to wait for the result
        // For now, we'll use a simple approach: wait a bit and try again
        QTimer::singleShot(1000, [this]() {
            // Try to get the captured image again
            QByteArray capturedData = m_cameraManager->captureImage();
            if (!capturedData.isEmpty()) {
                qDebug() << "Got captured image, size:" << capturedData.size();
                processRecognition(capturedData, QString());
            } else {
                qDebug() << "Still no captured image available";
                emit faceRecognitionFailed();
            }
        });
        return;
    }
    
    qDebug() << "Got captured image immediately, size:" << imageData.size();
            processRecognition(imageData, QString());
}

void QmlBridge::processRecognition(const QByteArray &imageData, const QString &capturedImage)
{
    qDebug() << "Processing recognition with image size:" << imageData.size();
    
    // Send to server for recognition with captured image
    QVariantMap result = m_faceRecognitionService->recognizeFaceWithServer(imageData, capturedImage);
    
    if (result["success"].toBool()) {
        qDebug() << "Recognition request sent successfully";
        // The response will be handled asynchronously via signals
    } else {
        qDebug() << "Recognition request failed:" << result["error"].toString();
        // Don't fallback to simulation - let user know recognition failed
        emit faceRecognitionFailed();
    }
}

void QmlBridge::captureAndRecognizeFromQML(const QImage &image, const QString &capturedImage)
{
    qDebug() << "Received image from QML, size:" << image.size();
    
    // Convert QImage to QByteArray (JPEG)
    QByteArray imageData;
    QBuffer buffer(&imageData);
    buffer.open(QIODevice::WriteOnly);
    image.save(&buffer, "JPEG", 80); // 80% quality
    buffer.close();
    
    qDebug() << "Converted image to JPEG, size:" << imageData.size();
    
    // Process recognition with captured image
    processRecognition(imageData, capturedImage);
}

QVariantMap QmlBridge::getSystemMetrics()
{
    return m_systemMetrics;
}

void QmlBridge::startSystemMonitoring()
{
    m_systemMonitor->startMonitoring();
    updateSystemMetrics();
}

void QmlBridge::stopSystemMonitoring()
{
    m_systemMonitor->stopMonitoring();
}

bool QmlBridge::getWifiConnected()
{
    // Get real-time WiFi status from NetworkManager
    bool connected = m_networkManager->isConnected();
    if (m_wifiConnected != connected) {
        m_wifiConnected = connected;
        emit wifiConnectedChanged();
    }
    return m_wifiConnected;
}

void QmlBridge::setWifiConnected(bool connected)
{
    if (m_wifiConnected != connected) {
        m_wifiConnected = connected;
        emit wifiConnectedChanged();
    }
}

bool QmlBridge::setWifiEnabled(bool enabled)
{
    if (m_networkManager) {
        bool success = m_networkManager->setWifiEnabled(enabled);
        if (success) {
            // Update WiFi connected status
            if (!enabled) {
                // When WiFi is disabled, we're definitely not connected
                setWifiConnected(false);
            } else {
                // When WiFi is enabled, check actual connection status
                bool connected = m_networkManager->isConnected();
                setWifiConnected(connected);
            }
        }
        return success;
    }
    return false;
}

bool QmlBridge::isWifiEnabled()
{
    if (m_networkManager) {
        return m_networkManager->isWifiEnabled();
    }
    return false;
}

bool QmlBridge::reconnectToLastNetwork()
{
    if (m_networkManager) {
        bool success = m_networkManager->reconnectToLastNetwork();
        if (success) {
            setWifiConnected(true);
        }
        return success;
    }
    return false;
}

QVariantList QmlBridge::getAvailableNetworks()
{
    return m_networkManager->getAvailableNetworks();
}

bool QmlBridge::connectToNetwork(const QString &ssid, const QString &password)
{
    bool success = m_networkManager->connectToNetwork(ssid, password);
    if (success) {
        setWifiConnected(true);
    }
    return success;
}

bool QmlBridge::disconnectFromNetwork()
{
    bool success = m_networkManager->disconnectFromNetwork();
    if (success) {
        setWifiConnected(false);
    }
    return success;
}

QString QmlBridge::getCurrentNetwork()
{
    if (m_networkManager) {
        return m_networkManager->getCurrentNetwork();
    }
    return QString();
}

void QmlBridge::refreshNetworks()
{
    // Refresh WiFi status and emit signals
    bool connected = m_networkManager->isConnected();
    if (m_wifiConnected != connected) {
        m_wifiConnected = connected;
        emit wifiConnectedChanged();
    }
    
    // Emit signal to notify QML to refresh networks
    emit wifiConnectedChanged();
}

QString QmlBridge::getCurrentDateTime()
{
    return QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");
}

void QmlBridge::refreshData()
{
    loadUsers();
    loadHistoryLogs();
    updateSystemMetrics();
}

void QmlBridge::loadUsers()
{
    m_users = m_databaseManager->getAllUsers();
    emit usersChanged();
}

void QmlBridge::loadHistoryLogs()
{
    m_historyLogs = m_databaseManager->getHistoryLogs();
    emit historyLogsChanged();
}

void QmlBridge::updateSystemMetrics()
{
    // Get latest metrics from system monitor
    m_systemMetrics = m_systemMonitor->getSystemMetrics();
    qDebug() << "QmlBridge: Updating system metrics:" << m_systemMetrics;
    emit systemMetricsChanged();
}

void QmlBridge::updateSystemMetrics(const QVariantMap &metrics)
{
    // Update metrics from signal
    m_systemMetrics = metrics;
    // qDebug() << "QmlBridge: Received system metrics from signal:" << m_systemMetrics; // Disabled to reduce log noise
    emit systemMetricsChanged();
}

// Cache operations
void QmlBridge::cacheUsers(const QVariantList &users)
{
    if (m_cacheManager) {
        m_cacheManager->cacheUsers(users);
    }
}

QVariantList QmlBridge::getCachedUsers()
{
    if (m_cacheManager) {
        return m_cacheManager->getCachedUsers();
    }
    return QVariantList();
}

void QmlBridge::cacheLog(const QVariantMap &log)
{
    if (m_cacheManager) {
        m_cacheManager->cacheLog(log);
    }
}

QVariantList QmlBridge::getUnsyncedLogs()
{
    if (m_cacheManager) {
        return m_cacheManager->getUnsyncedLogs();
    }
    return QVariantList();
}

bool QmlBridge::hasUnsyncedLogs()
{
    if (m_cacheManager) {
        return m_cacheManager->hasUnsyncedLogs();
    }
    return false;
}

int QmlBridge::getUnsyncedLogsCount()
{
    if (m_cacheManager) {
        return m_cacheManager->getUnsyncedLogsCount();
    }
    return 0;
}

void QmlBridge::syncCachedLogs()
{
    if (m_cacheManager && m_faceRecognitionService) {
        // TODO: Implement sync logic
        qDebug() << "Sync cached logs - TODO: implement";
    }
}
