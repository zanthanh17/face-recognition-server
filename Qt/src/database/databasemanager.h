#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDebug>
#include <QDir>
#include <QStandardPaths>

class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    explicit DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();

    // Database initialization
    bool initializeDatabase();
    bool createTables();

    // User management
    bool addUser(const QString &name, const QString &department, const QByteArray &faceEncoding);
    bool updateUser(int userId, const QString &name, const QString &department);
    bool deleteUser(int userId);
    QVariantList getAllUsers();
    QVariantMap getUserById(int userId);
    QVariantMap getUserByName(const QString &name);

    // History management
    bool addHistoryLog(int userId, const QString &actionType, const QString &status);
    QVariantList getHistoryLogs(int limit = 100);
    QVariantList getHistoryLogsByUser(int userId, int limit = 50);

    // Settings management
    bool saveSetting(const QString &key, const QString &value);
    QString getSetting(const QString &key, const QString &defaultValue = "");

private:
    QSqlDatabase m_database;
    QString m_databasePath;

    bool openDatabase();
    void closeDatabase();
};

#endif // DATABASEMANAGER_H
