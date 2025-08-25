#ifndef FACERECOGNITIONSERVICE_H
#define FACERECOGNITIONSERVICE_H

#include <QObject>
#include <QVariantMap>
#include <QVariantList>
#include <QByteArray>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QBuffer>
#include <QImage>

class DatabaseManager;

class FaceRecognitionService : public QObject
{
    Q_OBJECT

public:
    explicit FaceRecognitionService(QObject *parent = nullptr);
    ~FaceRecognitionService();

    // Face recognition operations
    QVariantMap recognizeFace(const QByteArray &imageData);
    bool registerFace(const QByteArray &imageData, int userId);
    QByteArray extractFaceEncoding(const QByteArray &imageData);

    // Server API operations
    QVariantMap recognizeFaceWithServer(const QByteArray &imageData, const QString &capturedImage = QString());
    bool registerFaceWithServer(const QByteArray &imageData, const QString &name, const QString &position);
    QVariantList getAttendanceHistory();
    QVariantList getUsersFromServer();
    QVariantList getWorkHours(const QString &date = QString());
    QVariantList getWorkHoursSummary(const QString &startDate = QString(), const QString &endDate = QString());
    bool testServerConnection(const QString &serverUrl = QString());
    QString getUserImage(const QString &userId);

    // Configuration
    void setServerUrl(const QString &url);
    QString getServerUrl() const;
    void setDeviceId(const QString &deviceId);
    QString getDeviceId() const;

    // Set database manager
    void setDatabaseManager(DatabaseManager *dbManager);

signals:
    void faceDetected();
    void faceRecognized(const QString &userId, const QString &userName);
    void faceRecognitionFailed();
    void faceRegistrationSuccess(int userId);
    void faceRegistrationFailed(const QString &error);
    void serverConnectionTested(bool success, const QString &message);
    void attendanceHistoryUpdated();
    void historyDataLoaded(const QVariantList &data);
    void historyDataLoadedJson(const QString &jsonData);
    void historyDataLoadFailed(const QString &error);
    void usersUpdated(const QVariantList &users);
    void workHoursUpdated(const QVariantList &workHours);
    void workHoursSummaryUpdated(const QVariantList &summary);

private slots:
    void onRecognizeReplyFinished();
    void onRegisterReplyFinished();
    void onHistoryReplyFinished();
    void onUsersReplyFinished();
    void onWorkHoursReplyFinished();
    void onWorkHoursSummaryReplyFinished();
    void onConnectionTestReplyFinished();

private:
    DatabaseManager *m_databaseManager;
    QNetworkAccessManager *m_networkManager;
    QString m_serverUrl;
    QString m_deviceId;
    
    // Face recognition helper methods
    bool detectFace(const QByteArray &imageData);
    QByteArray encodeFace(const QByteArray &imageData);
    double compareFaces(const QByteArray &encoding1, const QByteArray &encoding2);
    QVariantMap recognizeFaceLocally(const QByteArray &imageData);
    
    // Server communication helper methods
    QByteArray imageToBase64(const QImage &image);
    QJsonObject createRecognizeRequest(const QByteArray &imageData, const QString &capturedImage = QString());
    QJsonObject createRegisterRequest(const QByteArray &imageData, const QString &name, const QString &position);
    QVariantMap parseRecognizeResponse(const QByteArray &responseData);
    QVariantList parseHistoryResponse(const QByteArray &responseData);
    QVariantList parseUsersResponse(const QByteArray &responseData);
    bool isNetworkAvailable() const;
};

#endif // FACERECOGNITIONSERVICE_H
