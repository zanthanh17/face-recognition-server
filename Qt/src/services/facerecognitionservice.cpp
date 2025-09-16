#include "facerecognitionservice.h"
#include "../debug_config.h"
#include <QDebug>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QBuffer>
#include <QImage>
#include <QUrl>
#include <QUrlQuery>
#include <QTimer>
#include <QSysInfo>
#include <QEventLoop>

FaceRecognitionService::FaceRecognitionService(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_serverUrl("http://localhost:8001")
    , m_deviceId(QSysInfo::machineHostName())
{
    // Connect network manager signals (Qt6 compatible)
    // Note: networkAccessibleChanged is deprecated in Qt6, removed in Qt6.5+
    // We'll use a simpler approach for network availability checking
}

FaceRecognitionService::~FaceRecognitionService()
{
}

// Database functionality moved to server - no longer needed

void FaceRecognitionService::setServerUrl(const QString &url)
{
    m_serverUrl = url;
    // Server URL set
}

QString FaceRecognitionService::getServerUrl() const
{
    return m_serverUrl;
}

void FaceRecognitionService::setDeviceId(const QString &deviceId)
{
    m_deviceId = deviceId;
}

QString FaceRecognitionService::getDeviceId() const
{
    return m_deviceId;
}

QVariantMap FaceRecognitionService::recognizeFace(const QByteArray &imageData)
{
    // Try server first if network is available
    if (isNetworkAvailable()) {
        return recognizeFaceWithServer(imageData);
    } else {
        // Fallback to local recognition
        // Network not available, using local recognition
        return recognizeFaceLocally(imageData);
    }
}

QVariantMap FaceRecognitionService::recognizeFaceWithServer(const QByteArray &imageData, const QString &capturedImage)
{
    QVariantMap result;

    if (imageData.isEmpty()) {
        result["success"] = false;
        result["error"] = "No image data provided";
        return result;
    }

    // Convert image to base64
    QImage image;
    if (!image.loadFromData(imageData)) {
        result["success"] = false;
        result["error"] = "Invalid image data";
        return result;
    }

    QByteArray base64Image = imageToBase64(image);
    
    // Sending recognition request
    
    // Create JSON request
    QJsonObject requestObj = createRecognizeRequest(base64Image, capturedImage);
    QJsonDocument doc(requestObj);
    QByteArray jsonData = doc.toJson();
    
    // JSON request prepared
    
    // Send HTTP request
    QNetworkRequest request(QUrl(m_serverUrl + "/recognize"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    QNetworkReply *reply = m_networkManager->post(request, jsonData);
    
    // Store reply for async handling
    reply->setProperty("requestType", "recognize");
    reply->setProperty("imageData", imageData);
    
    connect(reply, &QNetworkReply::finished, this, &FaceRecognitionService::onRecognizeReplyFinished);
    
    // Return immediate result (will be updated via signal)
    result["success"] = true;
    result["status"] = "processing";
    return result;
}

bool FaceRecognitionService::registerFaceWithServer(const QByteArray &imageData, const QString &name, const QString &position)
{
    if (imageData.isEmpty() || name.isEmpty()) {
        return false;
    }

    // Convert image to base64
    QImage image;
    if (!image.loadFromData(imageData)) {
        return false;
    }

    QByteArray base64Image = imageToBase64(image);
    
    // Create JSON request
    QJsonObject requestObj = createRegisterRequest(base64Image, name, position);
    QJsonDocument doc(requestObj);
    QByteArray jsonData = doc.toJson();
    
    // Send HTTP request
    QNetworkRequest request(QUrl(m_serverUrl + "/register"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    QNetworkReply *reply = m_networkManager->post(request, jsonData);
    
    // Store reply for async handling
    reply->setProperty("requestType", "register");
    reply->setProperty("name", name);
    reply->setProperty("position", position);
    
    connect(reply, &QNetworkReply::finished, this, &FaceRecognitionService::onRegisterReplyFinished);
    
    return true;
}

QVariantList FaceRecognitionService::getAttendanceHistory()
{
    QVariantList result;
    
    if (!isNetworkAvailable()) {
        qDebug() << "Network not available for history";
        return result;
    }

    // Send HTTP request
    QNetworkRequest request(QUrl(m_serverUrl + "/attendance"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    QJsonObject requestObj;
    requestObj["limit"] = 100;
    QJsonDocument doc(requestObj);
    QByteArray jsonData = doc.toJson();
    
    QNetworkReply *reply = m_networkManager->post(request, jsonData);
    
    // Store reply for async handling
    reply->setProperty("requestType", "history");
    
    connect(reply, &QNetworkReply::finished, this, &FaceRecognitionService::onHistoryReplyFinished);
    
    return result;
}

QVariantList FaceRecognitionService::getWorkHours(const QString &date)
{
    QVariantList result;
    
    if (!isNetworkAvailable()) {
        qDebug() << "Network not available for work hours";
        return result;
    }

    // Send HTTP request
    QNetworkRequest request(QUrl(m_serverUrl + "/attendance/work-hours"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    // Add date parameter if provided
    QUrl url = request.url();
    if (!date.isEmpty()) {
        url.setQuery("date=" + date);
    }
    request.setUrl(url);
    
    QNetworkReply *reply = m_networkManager->get(request);
    
    // Store reply for async handling
    reply->setProperty("requestType", "work_hours");
    
    connect(reply, &QNetworkReply::finished, this, &FaceRecognitionService::onWorkHoursReplyFinished);
    
    return result;
}

QVariantList FaceRecognitionService::getWorkHoursSummary(const QString &startDate, const QString &endDate)
{
    QVariantList result;
    
    if (!isNetworkAvailable()) {
        qDebug() << "Network not available for work hours summary";
        return result;
    }

    // Send HTTP request
    QNetworkRequest request(QUrl(m_serverUrl + "/attendance/work-hours/summary"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    // Add date parameters if provided
    QUrl url = request.url();
    QUrlQuery query;
    if (!startDate.isEmpty()) {
        query.addQueryItem("start_date", startDate);
    }
    if (!endDate.isEmpty()) {
        query.addQueryItem("end_date", endDate);
    }
    if (!query.isEmpty()) {
        url.setQuery(query);
    }
    request.setUrl(url);
    
    QNetworkReply *reply = m_networkManager->get(request);
    
    // Store reply for async handling
    reply->setProperty("requestType", "work_hours_summary");
    
    connect(reply, &QNetworkReply::finished, this, &FaceRecognitionService::onWorkHoursSummaryReplyFinished);
    
    return result;
}

QVariantList FaceRecognitionService::getUsersFromServer()
{
    QVariantList result;
    
    if (!isNetworkAvailable()) {
        qDebug() << "Network not available for users";
        return result;
    }

    // Send HTTP request to public endpoint (no authentication required)
    QNetworkRequest request(QUrl(m_serverUrl + "/users/public"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    QNetworkReply *reply = m_networkManager->get(request);
    
    // Store reply for async handling
    reply->setProperty("requestType", "users");
    
    connect(reply, &QNetworkReply::finished, this, &FaceRecognitionService::onUsersReplyFinished);
    
    return result;
}

bool FaceRecognitionService::testServerConnection(const QString &serverUrl)
{
    QString url = serverUrl.isEmpty() ? m_serverUrl : serverUrl;
    
    // Send HTTP request to health endpoint
    QNetworkRequest request(QUrl(url + "/health"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    QNetworkReply *reply = m_networkManager->get(request);
    
    // Store reply for async handling
    reply->setProperty("requestType", "connection_test");
    reply->setProperty("test_url", url);
    
    connect(reply, &QNetworkReply::finished, this, &FaceRecognitionService::onConnectionTestReplyFinished);
    
    return true;
}

QString FaceRecognitionService::getUserImage(const QString &userId)
{
    if (!isNetworkAvailable()) {
        qDebug() << "Network not available for getting user image";
        return QByteArray();
    }

    // Send HTTP request to get user image (synchronous for simplicity)
    QNetworkRequest request(QUrl(m_serverUrl + "/users/" + userId + "/image"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    QNetworkReply *reply = m_networkManager->get(request);
    
    // Wait for reply (synchronous)
    QEventLoop loop;
    connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    loop.exec();
    
    QString imageData;
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        
        // Parse JSON response to get base64 image data
        QJsonDocument doc = QJsonDocument::fromJson(responseData);
        if (!doc.isNull()) {
            QJsonObject obj = doc.object();
            QString base64Image = obj["image_base64"].toString();
            if (!base64Image.isEmpty()) {
                imageData = base64Image; // Return as QString for QML
            } else {
                qDebug() << "No image_base64 found in response";
            }
        } else {
            qDebug() << "Failed to parse JSON response for user image";
        }
    } else {
        qDebug() << "Failed to get user image:" << reply->errorString();
    }
    
    reply->deleteLater();
    return imageData;
}

// Private helper methods
QByteArray FaceRecognitionService::imageToBase64(const QImage &image)
{
    QBuffer buffer;
    buffer.open(QIODevice::WriteOnly);
    image.save(&buffer, "JPEG", 80); // Compress to JPEG with 80% quality
    return buffer.data().toBase64();
}

QJsonObject FaceRecognitionService::createRecognizeRequest(const QByteArray &imageData, const QString &capturedImage)
{
    QJsonObject requestObj;
    requestObj["image_base64"] = QString::fromUtf8(imageData);
    requestObj["device_id"] = m_deviceId;
    
    // Add captured image if provided
    if (!capturedImage.isEmpty()) {
        requestObj["captured_image"] = capturedImage;
    }
    
    return requestObj;
}

QJsonObject FaceRecognitionService::createRegisterRequest(const QByteArray &imageData, const QString &name, const QString &position)
{
    QJsonObject requestObj;
    requestObj["image_base64"] = QString::fromUtf8(imageData);
    requestObj["name"] = name;
    requestObj["position"] = position;
    return requestObj;
}

QVariantMap FaceRecognitionService::parseRecognizeResponse(const QByteArray &responseData)
{
    QVariantMap result;
    
    QJsonDocument doc = QJsonDocument::fromJson(responseData);
    if (doc.isNull()) {
        result["success"] = false;
        result["error"] = "Invalid JSON response";
        return result;
    }
    
    QJsonObject obj = doc.object();
    result["success"] = true;
    result["matched"] = obj["matched"].toBool();
    result["user_id"] = obj["user_id"].toString();
    result["name"] = obj["name"].toString();
    result["distance"] = obj["distance"].toDouble();
    result["threshold"] = obj["threshold"].toDouble();
    
    return result;
}

QVariantList FaceRecognitionService::parseHistoryResponse(const QByteArray &responseData)
{
    QVariantList result;
    
    QJsonDocument doc = QJsonDocument::fromJson(responseData);
    if (doc.isNull()) {
        qDebug() << "Failed to parse JSON response for history";
        return result;
    }
    
    QJsonObject obj = doc.object();
    QJsonArray items = obj["items"].toArray();
    
    qDebug() << "Parsing" << items.size() << "history items from response";
    
    for (const QJsonValue &value : items) {
        QJsonObject item = value.toObject();
        QVariantMap itemMap;
        
        // Handle null values and ensure proper data types
        itemMap["id"] = item["id"].toInt();
        itemMap["ts"] = item["ts"].toVariant();
        itemMap["device_id"] = item["device_id"].toString();
        itemMap["matched"] = item["matched"].toBool();
        
        // Handle null user_id and name
        if (item["user_id"].isNull()) {
            itemMap["user_id"] = QString("");
        } else {
            itemMap["user_id"] = item["user_id"].toString();
        }
        
        if (item["name"].isNull()) {
            itemMap["name"] = QString("Unknown");
        } else {
            itemMap["name"] = item["name"].toString();
        }
        
        // Handle null distance
        if (item["distance"].isNull()) {
            itemMap["distance"] = 0.0;
        } else {
            itemMap["distance"] = item["distance"].toDouble();
        }
        
        result.append(itemMap);
    }
    
    qDebug() << "Parsed" << result.size() << "history items";
    return result;
}

QVariantList FaceRecognitionService::parseUsersResponse(const QByteArray &responseData)
{
    QVariantList result;
    
    QJsonDocument doc = QJsonDocument::fromJson(responseData);
    if (doc.isNull()) {
        qDebug() << "Failed to parse JSON response";
        return result;
    }
    
    QJsonObject obj = doc.object();
    QJsonArray users = obj["users"].toArray();
    
    qDebug() << "Parsing" << users.size() << "users from response";
    
    for (const QJsonValue &value : users) {
        QJsonObject user = value.toObject();
        QVariantMap userMap;
        userMap["id"] = user["id"].toString(); // Server returns "id"
        userMap["name"] = user["name"].toString();
        userMap["position"] = user["position"].toString();
        userMap["active"] = user["active"].toBool();
        userMap["model"] = user["model"].toString();
        userMap["created_at"] = user["created_at"].toString();
        result.append(userMap);
    }
    
    qDebug() << "Parsed" << result.size() << "users";
    return result;
}

bool FaceRecognitionService::isNetworkAvailable() const
{
    // Qt6 compatible network availability check
    // For now, assume network is available if manager exists
    return m_networkManager != nullptr;
}

// Legacy methods removed - use server-based methods instead

// Private slot implementations
void FaceRecognitionService::onRecognizeReplyFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        QVariantMap result = parseRecognizeResponse(responseData);
        
        if (result["matched"].toBool()) {
            qDebug() << "FACE RECOGNITION SUCCESS:" << result["name"].toString();
            emit faceRecognized(
                result["user_id"].toString(), // Use actual user ID from server
                result["name"].toString()
            );
        } else {
            qDebug() << "FACE RECOGNITION FAILED";
            emit faceRecognitionFailed();
        }
    } else {
        qDebug() << "Recognition request failed:" << reply->errorString();
        emit faceRecognitionFailed();
    }
    
    reply->deleteLater();
}

void FaceRecognitionService::onRegisterReplyFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(responseData);
        
        if (!doc.isNull()) {
            QJsonObject obj = doc.object();
            QString userId = obj["user_id"].toString();
            
            emit faceRegistrationSuccess(userId.toInt());
        } else {
            emit faceRegistrationFailed("Invalid response format");
        }
    } else {
        qDebug() << "Registration request failed:" << reply->errorString();
        emit faceRegistrationFailed(reply->errorString());
    }
    
    reply->deleteLater();
}

void FaceRecognitionService::onHistoryReplyFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        qDebug() << "History response received, size:" << responseData.size();
        
        QVariantList history = parseHistoryResponse(responseData);
        qDebug() << "Parsed history data with" << history.size() << "entries";
        
        // Database functionality moved to server
        
        emit attendanceHistoryUpdated();
        
        // Debug: log the actual data being sent
        qDebug() << "Sending history data to QML, size:" << history.size();
        for (int i = 0; i < qMin(3, history.size()); i++) {
            qDebug() << "History item" << i << ":" << history[i];
        }
        
        // Convert to JSON string to avoid QML type issues
        QJsonArray jsonArray;
        for (const QVariant &item : history) {
            jsonArray.append(QJsonValue::fromVariant(item));
        }
        QJsonDocument doc(jsonArray);
        QString jsonString = doc.toJson(QJsonDocument::Compact);
        qDebug() << "JSON string length:" << jsonString.length();
        
        emit historyDataLoaded(history);
        emit historyDataLoadedJson(jsonString);
    } else {
        qDebug() << "History request failed:" << reply->errorString();
        emit historyDataLoadFailed(reply->errorString());
    }
    
    reply->deleteLater();
}

void FaceRecognitionService::onUsersReplyFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        QVariantList users = parseUsersResponse(responseData);
        
        qDebug() << "Users reply finished, emitting usersUpdated signal with" << users.size() << "users";
        emit usersUpdated(users);
        
        // Database functionality moved to server
    } else {
        qDebug() << "Users request failed:" << reply->errorString();
        emit usersUpdated(QVariantList()); // Emit empty list on error
    }
    
    reply->deleteLater();
}

void FaceRecognitionService::onConnectionTestReplyFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    QString testUrl = reply->property("test_url").toString();
    
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(responseData);
        
        if (!doc.isNull()) {
            emit serverConnectionTested(true, "Server connection successful");
        } else {
            emit serverConnectionTested(false, "Invalid server response");
        }
    } else {
        emit serverConnectionTested(false, "Connection failed: " + reply->errorString());
    }
    
    reply->deleteLater();
}

void FaceRecognitionService::onWorkHoursReplyFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(responseData);
        
        if (!doc.isNull() && doc.isObject()) {
            QJsonObject obj = doc.object();
            QVariantList workHours;
            
            if (obj.contains("users")) {
                QJsonArray usersArray = obj["users"].toArray();
                for (const QJsonValue &value : usersArray) {
                    workHours.append(value.toVariant());
                }
            }
            
            qDebug() << "Work hours reply finished, emitting workHoursUpdated signal with" << workHours.size() << "users";
            emit workHoursUpdated(workHours);
        } else {
            qDebug() << "Invalid work hours response format";
            emit workHoursUpdated(QVariantList());
        }
    } else {
        qDebug() << "Work hours request failed:" << reply->errorString();
        emit workHoursUpdated(QVariantList());
    }
    
    reply->deleteLater();
}

void FaceRecognitionService::onWorkHoursSummaryReplyFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(responseData);
        
        if (!doc.isNull() && doc.isObject()) {
            QJsonObject obj = doc.object();
            QVariantList summary;
            
            if (obj.contains("users")) {
                QJsonArray usersArray = obj["users"].toArray();
                for (const QJsonValue &value : usersArray) {
                    summary.append(value.toVariant());
                }
            }
            
            qDebug() << "Work hours summary reply finished, emitting workHoursSummaryUpdated signal with" << summary.size() << "users";
            emit workHoursSummaryUpdated(summary);
        } else {
            qDebug() << "Invalid work hours summary response format";
            emit workHoursSummaryUpdated(QVariantList());
        }
    } else {
        qDebug() << "Work hours summary request failed:" << reply->errorString();
        emit workHoursSummaryUpdated(QVariantList());
    }
    
    reply->deleteLater();
}

// Fallback local recognition method
QVariantMap FaceRecognitionService::recognizeFaceLocally(const QByteArray &imageData)
{
    QVariantMap result;
    
    if (imageData.isEmpty()) {
        result["success"] = false;
        result["error"] = "No image data provided";
        return result;
    }

    // Database functionality moved to server
    result["success"] = true;
    result["matched"] = false;
    result["error"] = "Local recognition not implemented - use server";
    
    return result;
}
