#ifndef CACHEMANAGER_H
#define CACHEMANAGER_H

#include <QObject>
#include <QVariant>
#include <QVariantList>
#include <QVariantMap>
#include <QString>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFile>
#include <QDir>
#include <QStandardPaths>
#include <QDebug>

class CacheManager : public QObject
{
    Q_OBJECT

public:
    explicit CacheManager(QObject *parent = nullptr);
    ~CacheManager();

    // User cache management
    Q_INVOKABLE void cacheUsers(const QVariantList &users);
    Q_INVOKABLE QVariantList getCachedUsers();
    Q_INVOKABLE QVariantMap getCachedUserById(const QString &userId);
    Q_INVOKABLE void clearUserCache();
    Q_INVOKABLE bool hasCachedUsers();

    // Log cache management
    Q_INVOKABLE void cacheLog(const QVariantMap &log);
    Q_INVOKABLE QVariantList getCachedLogs();
    Q_INVOKABLE QVariantList getUnsyncedLogs();
    Q_INVOKABLE void markLogSynced(const QString &logId);
    Q_INVOKABLE void clearSyncedLogs();
    Q_INVOKABLE bool hasUnsyncedLogs();
    Q_INVOKABLE int getUnsyncedLogsCount();

    // Cache status
    Q_INVOKABLE bool isCacheValid();
    Q_INVOKABLE void clearAllCache();

signals:
    void cacheUpdated();
    void unsyncedLogsChanged();

private:
    QString m_cacheDir;
    QString m_usersCacheFile;
    QString m_logsCacheFile;
    
    bool saveToFile(const QString &filePath, const QVariant &data);
    QVariant loadFromFile(const QString &filePath);
    void ensureCacheDir();
};

#endif // CACHEMANAGER_H
