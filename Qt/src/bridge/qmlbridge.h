#ifndef QMLBRIDGE_H
#define QMLBRIDGE_H

#include <QObject>
#include <QVariant>
#include <QVariantList>
#include <QVariantMap>
#include <QString>
#include <QByteArray>
#include <QImage>

// Forward declarations
class DatabaseManager;
class UserManager;
class CameraManager;
class SystemMonitor;
class NetworkManager;
class FaceRecognitionService;
class CacheManager;

class QmlBridge : public QObject
{
    Q_OBJECT

    // Properties exposed to QML
    Q_PROPERTY(QVariantList users READ getUsersList NOTIFY usersChanged)
    Q_PROPERTY(QVariantList historyLogs READ getHistoryLogs NOTIFY historyLogsChanged)
    Q_PROPERTY(QVariantList recognitionHistory READ getRecognitionHistory NOTIFY recognitionHistoryChanged)
    Q_PROPERTY(bool wifiConnected READ getWifiConnected WRITE setWifiConnected NOTIFY wifiConnectedChanged)
    Q_PROPERTY(QVariantMap systemMetrics READ getSystemMetrics NOTIFY systemMetricsChanged)
    Q_PROPERTY(bool cameraAvailable READ getCameraAvailable NOTIFY cameraAvailableChanged)

public:
    explicit QmlBridge(QObject *parent = nullptr);
    ~QmlBridge();

    // Server database operations
    Q_INVOKABLE QVariantList getUsers();
    Q_INVOKABLE QVariantList getUsersList() const;
    Q_INVOKABLE QVariantMap getUserById(int userId);
    Q_INVOKABLE QVariantMap getUserByName(const QString &name);
    Q_INVOKABLE bool addUser(const QString &name, const QString &department, const QByteArray &faceEncoding);
    Q_INVOKABLE QVariantList getHistoryLogs();
    Q_INVOKABLE QVariantList getRecognitionHistory();
    Q_INVOKABLE void loadUsersFromBackend();

    // Settings operations
    Q_INVOKABLE bool saveSetting(const QString &key, const QString &value);
    Q_INVOKABLE QString getSetting(const QString &key, const QString &defaultValue = "") const;

    // Camera operations
    Q_INVOKABLE bool startCamera();
    Q_INVOKABLE void stopCamera();
    Q_INVOKABLE QByteArray captureImage();
    Q_INVOKABLE bool getCameraAvailable();

    // Face recognition operations
    Q_INVOKABLE QVariantMap recognizeFace(const QByteArray &imageData);
    Q_INVOKABLE bool registerFace(const QByteArray &imageData, int userId);
    Q_INVOKABLE QByteArray extractFaceEncoding(const QByteArray &imageData);
    
    // Server API operations
    Q_INVOKABLE QVariantMap recognizeFaceWithServer(const QByteArray &imageData, const QString &capturedImage = QString());
    Q_INVOKABLE bool registerFaceWithServer(const QByteArray &imageData, const QString &name, const QString &position);
    Q_INVOKABLE QVariantList getAttendanceHistory();
    Q_INVOKABLE void loadHistoryData();
    Q_INVOKABLE QString getHistoryDataAsJson();
    Q_INVOKABLE void addRecognitionEvent(const QString &userName, bool success);
    Q_INVOKABLE void addRecognitionEventWithImage(const QString &userName, bool success, const QString &imageData);
    Q_INVOKABLE void clearRecognitionHistory();
    Q_INVOKABLE QVariantList getUsersFromServer();
    Q_INVOKABLE QVariantList getWorkHours(const QString &date = QString());
    Q_INVOKABLE QVariantList getWorkHoursSummary(const QString &startDate = QString(), const QString &endDate = QString());
    Q_INVOKABLE bool testServerConnection(const QString &serverUrl = QString());
    Q_INVOKABLE void setServerUrl(const QString &url);
    Q_INVOKABLE QString getServerUrl() const;
    Q_INVOKABLE void setDeviceId(const QString &deviceId);
    Q_INVOKABLE QString getDeviceId() const;
    Q_INVOKABLE QByteArray readImageFile(const QString &filePath);
    Q_INVOKABLE QString convertImageToBase64(const QImage &image);
    Q_INVOKABLE QString cropImageToFaceFrame(const QImage &image, int frameWidth, int frameHeight);
    Q_INVOKABLE QString getUserImage(const QString &userId);
    Q_INVOKABLE void simulateRecognition();
    Q_INVOKABLE void captureAndRecognize();
    Q_INVOKABLE void captureAndRecognizeFromQML(const QImage &image, const QString &capturedImage = QString());

    // System monitoring
    Q_INVOKABLE QVariantMap getSystemMetrics();
    Q_INVOKABLE void startSystemMonitoring();
    Q_INVOKABLE void stopSystemMonitoring();

    // Network operations
    Q_INVOKABLE bool getWifiConnected();
    Q_INVOKABLE void setWifiConnected(bool connected);
    Q_INVOKABLE bool setWifiEnabled(bool enabled);
    Q_INVOKABLE bool isWifiEnabled();
    Q_INVOKABLE bool reconnectToLastNetwork();
    Q_INVOKABLE QVariantList getAvailableNetworks();
    Q_INVOKABLE bool connectToNetwork(const QString &ssid, const QString &password);
    Q_INVOKABLE bool disconnectFromNetwork();
    Q_INVOKABLE QString getCurrentNetwork();
    Q_INVOKABLE void refreshNetworks();

    // Utility functions
    Q_INVOKABLE QString getCurrentDateTime();
    Q_INVOKABLE void refreshData();
    
    // Cache operations
    Q_INVOKABLE void cacheUsers(const QVariantList &users);
    Q_INVOKABLE QVariantList getCachedUsers();
    Q_INVOKABLE void cacheLog(const QVariantMap &log);
    Q_INVOKABLE QVariantList getUnsyncedLogs();
    Q_INVOKABLE bool hasUnsyncedLogs();
    Q_INVOKABLE int getUnsyncedLogsCount();
    Q_INVOKABLE void syncCachedLogs();

signals:
    void usersChanged();
    void historyLogsChanged();
    void wifiConnectedChanged();
    void systemMetricsChanged();
    void cameraAvailableChanged();
    void faceRecognized(const QString &userId, const QString &userName);
    void faceRecognitionFailed();
    void faceRegistrationSuccess(int userId);
    void faceRegistrationFailed(const QString &error);
    void cameraError(const QString &error);
    void databaseError(const QString &error);
    void serverConnectionTested(bool success, const QString &message);
    void attendanceHistoryUpdated();
    void historyDataLoaded(const QVariantList &data);
    void historyDataLoadedJson(const QString &jsonData);
    void historyDataLoadFailed(const QString &error);
    void recognitionEventAdded(const QString &userName, bool success, const QString &timestamp);
    void recognitionHistoryChanged();
    void workHoursUpdated(const QVariantList &workHours);
    void workHoursSummaryUpdated(const QVariantList &summary);
    void cacheUpdated();
    void unsyncedLogsChanged();

private:
    DatabaseManager *m_databaseManager;
    UserManager *m_userManager;
    CameraManager *m_cameraManager;
    SystemMonitor *m_systemMonitor;
    NetworkManager *m_networkManager;
    FaceRecognitionService *m_faceRecognitionService;
    CacheManager *m_cacheManager;

    QVariantList m_users;
    QVariantList m_historyLogs;
    QVariantList m_recognitionHistory;
    QVariantMap m_systemMetrics;
    bool m_wifiConnected;
    bool m_cameraAvailable;

    void loadUsers();
    void loadHistoryLogs();
    void updateSystemMetrics();
    void updateSystemMetrics(const QVariantMap &metrics);
    void processRecognition(const QByteArray &imageData, const QString &capturedImage = QString());
    void onUsersUpdated(const QVariantList &users);
};

#endif // QMLBRIDGE_H
