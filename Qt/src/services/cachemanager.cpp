#include "cachemanager.h"
#include <QDateTime>

CacheManager::CacheManager(QObject *parent)
    : QObject(parent)
{
    // Setup cache directory
    m_cacheDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/cache";
    m_usersCacheFile = m_cacheDir + "/users_cache.json";
    m_logsCacheFile = m_cacheDir + "/logs_cache.json";
    
    ensureCacheDir();
    qDebug() << "CacheManager initialized, cache dir:" << m_cacheDir;
}

CacheManager::~CacheManager()
{
}

void CacheManager::ensureCacheDir()
{
    QDir dir;
    if (!dir.exists(m_cacheDir)) {
        dir.mkpath(m_cacheDir);
        qDebug() << "Created cache directory:" << m_cacheDir;
    }
}

bool CacheManager::saveToFile(const QString &filePath, const QVariant &data)
{
    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) {
        qDebug() << "Failed to open file for writing:" << filePath;
        return false;
    }
    
    QJsonDocument doc = QJsonDocument::fromVariant(data);
    file.write(doc.toJson());
    file.close();
    return true;
}

QVariant CacheManager::loadFromFile(const QString &filePath)
{
    QFile file(filePath);
    if (!file.exists()) {
        qDebug() << "Cache file does not exist:" << filePath;
        return QVariant();
    }
    
    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << "Failed to open cache file:" << filePath;
        return QVariant();
    }
    
    QByteArray data = file.readAll();
    file.close();
    
    QJsonDocument doc = QJsonDocument::fromJson(data);
    return doc.toVariant();
}

// User cache management
void CacheManager::cacheUsers(const QVariantList &users)
{
    QVariantMap cacheData;
    cacheData["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);
    cacheData["users"] = users;
    
    if (saveToFile(m_usersCacheFile, cacheData)) {
        qDebug() << "Cached" << users.size() << "users";
        emit cacheUpdated();
    }
}

QVariantList CacheManager::getCachedUsers()
{
    QVariantMap cacheData = loadFromFile(m_usersCacheFile).toMap();
    return cacheData["users"].toList();
}

QVariantMap CacheManager::getCachedUserById(const QString &userId)
{
    QVariantList users = getCachedUsers();
    for (const QVariant &userVar : users) {
        QVariantMap user = userVar.toMap();
        if (user["id"].toString() == userId) {
            return user;
        }
    }
    return QVariantMap();
}

void CacheManager::clearUserCache()
{
    QFile::remove(m_usersCacheFile);
    qDebug() << "User cache cleared";
    emit cacheUpdated();
}

bool CacheManager::hasCachedUsers()
{
    QVariantList users = getCachedUsers();
    return !users.isEmpty();
}

// Log cache management
void CacheManager::cacheLog(const QVariantMap &log)
{
    QVariantList logs = getCachedLogs();
    
    // Add sync status
    QVariantMap logWithSync = log;
    logWithSync["synced"] = false;
    logWithSync["cached_at"] = QDateTime::currentDateTime().toString(Qt::ISODate);
    
    logs.append(logWithSync);
    
    if (saveToFile(m_logsCacheFile, logs)) {
        qDebug() << "Cached log for user:" << log["user_name"].toString();
        emit unsyncedLogsChanged();
    }
}

QVariantList CacheManager::getCachedLogs()
{
    return loadFromFile(m_logsCacheFile).toList();
}

QVariantList CacheManager::getUnsyncedLogs()
{
    QVariantList allLogs = getCachedLogs();
    QVariantList unsyncedLogs;
    
    for (const QVariant &logVar : allLogs) {
        QVariantMap log = logVar.toMap();
        if (!log["synced"].toBool()) {
            unsyncedLogs.append(log);
        }
    }
    
    return unsyncedLogs;
}

void CacheManager::markLogSynced(const QString &logId)
{
    QVariantList logs = getCachedLogs();
    
    for (int i = 0; i < logs.size(); ++i) {
        QVariantMap log = logs[i].toMap();
        if (log["id"].toString() == logId) {
            log["synced"] = true;
            log["synced_at"] = QDateTime::currentDateTime().toString(Qt::ISODate);
            logs[i] = log;
            break;
        }
    }
    
    if (saveToFile(m_logsCacheFile, logs)) {
        qDebug() << "Marked log as synced:" << logId;
        emit unsyncedLogsChanged();
    }
}

void CacheManager::clearSyncedLogs()
{
    QVariantList allLogs = getCachedLogs();
    QVariantList unsyncedLogs;
    
    for (const QVariant &logVar : allLogs) {
        QVariantMap log = logVar.toMap();
        if (!log["synced"].toBool()) {
            unsyncedLogs.append(log);
        }
    }
    
    if (saveToFile(m_logsCacheFile, unsyncedLogs)) {
        qDebug() << "Cleared synced logs, kept" << unsyncedLogs.size() << "unsynced logs";
        emit unsyncedLogsChanged();
    }
}

bool CacheManager::hasUnsyncedLogs()
{
    return !getUnsyncedLogs().isEmpty();
}

int CacheManager::getUnsyncedLogsCount()
{
    return getUnsyncedLogs().size();
}

// Cache status
bool CacheManager::isCacheValid()
{
    QFile usersFile(m_usersCacheFile);
    QFile logsFile(m_logsCacheFile);
    
    return usersFile.exists() && logsFile.exists();
}

void CacheManager::clearAllCache()
{
    clearUserCache();
    QFile::remove(m_logsCacheFile);
    qDebug() << "All cache cleared";
    emit cacheUpdated();
    emit unsyncedLogsChanged();
}
