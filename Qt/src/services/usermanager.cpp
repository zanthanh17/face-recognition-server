#include "usermanager.h"
#include "../database/databasemanager.h"
#include <QDebug>

UserManager::UserManager(QObject *parent)
    : QObject(parent)
    , m_databaseManager(nullptr)
{
    // DatabaseManager will be set by QmlBridge
}

UserManager::~UserManager()
{
}

void UserManager::setDatabaseManager(DatabaseManager *dbManager)
{
    m_databaseManager = dbManager;
}

bool UserManager::addUser(const QString &name, const QString &department, const QByteArray &faceEncoding)
{
    if (!m_databaseManager) {
        qDebug() << "DatabaseManager not initialized";
        return false;
    }
    
    return m_databaseManager->addUser(name, department, faceEncoding);
}

bool UserManager::updateUser(int userId, const QString &name, const QString &department)
{
    if (!m_databaseManager) {
        qDebug() << "DatabaseManager not initialized";
        return false;
    }
    
    return m_databaseManager->updateUser(userId, name, department);
}

bool UserManager::deleteUser(int userId)
{
    if (!m_databaseManager) {
        qDebug() << "DatabaseManager not initialized";
        return false;
    }
    
    return m_databaseManager->deleteUser(userId);
}

QVariantList UserManager::getAllUsers()
{
    if (!m_databaseManager) {
        qDebug() << "DatabaseManager not initialized";
        return QVariantList();
    }
    
    return m_databaseManager->getAllUsers();
}

QVariantMap UserManager::getUserById(int userId)
{
    if (!m_databaseManager) {
        qDebug() << "DatabaseManager not initialized";
        return QVariantMap();
    }
    
    return m_databaseManager->getUserById(userId);
}

QVariantMap UserManager::getUserByName(const QString &name)
{
    if (!m_databaseManager) {
        qDebug() << "DatabaseManager not initialized";
        return QVariantMap();
    }
    
    return m_databaseManager->getUserByName(name);
}

bool UserManager::updateFaceEncoding(int userId, const QByteArray &faceEncoding)
{
    if (!m_databaseManager) {
        qDebug() << "DatabaseManager not initialized";
        return false;
    }
    
    // This would require a new method in DatabaseManager
    // For now, we'll use the existing updateUser method
    QVariantMap user = m_databaseManager->getUserById(userId);
    if (user.isEmpty()) {
        return false;
    }
    
    return m_databaseManager->updateUser(userId, user["name"].toString(), user["department"].toString());
}

QByteArray UserManager::getFaceEncoding(int userId)
{
    if (!m_databaseManager) {
        qDebug() << "DatabaseManager not initialized";
        return QByteArray();
    }
    
    QVariantMap user = m_databaseManager->getUserById(userId);
    if (user.contains("face_encoding")) {
        return user["face_encoding"].toByteArray();
    }
    
    return QByteArray();
}
