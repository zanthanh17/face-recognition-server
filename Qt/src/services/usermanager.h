#ifndef USERMANAGER_H
#define USERMANAGER_H

#include <QObject>
#include <QVariant>
#include <QVariantList>
#include <QVariantMap>
#include <QString>
#include <QByteArray>

class DatabaseManager;

class UserManager : public QObject
{
    Q_OBJECT

public:
    explicit UserManager(QObject *parent = nullptr);
    ~UserManager();

    // User operations
    bool addUser(const QString &name, const QString &department, const QByteArray &faceEncoding);
    bool updateUser(int userId, const QString &name, const QString &department);
    bool deleteUser(int userId);
    QVariantList getAllUsers();
    QVariantMap getUserById(int userId);
    QVariantMap getUserByName(const QString &name);

    // Face encoding operations
    bool updateFaceEncoding(int userId, const QByteArray &faceEncoding);
    QByteArray getFaceEncoding(int userId);

    // Set database manager
    void setDatabaseManager(DatabaseManager *dbManager);

private:
    DatabaseManager *m_databaseManager;
};

#endif // USERMANAGER_H
