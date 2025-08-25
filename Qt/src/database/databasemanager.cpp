#include "databasemanager.h"

DatabaseManager::DatabaseManager(QObject *parent)
    : QObject(parent)
{
    // Get application data directory
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataPath);
    m_databasePath = dataPath + "/facelogin.db";
}

DatabaseManager::~DatabaseManager()
{
    closeDatabase();
}

bool DatabaseManager::initializeDatabase()
{
    if (!openDatabase()) {
        qDebug() << "Failed to open database:" << m_databasePath;
        return false;
    }

    if (!createTables()) {
        qDebug() << "Failed to create database tables";
        return false;
    }

    qDebug() << "Database initialized successfully:" << m_databasePath;
    return true;
}

bool DatabaseManager::openDatabase()
{
    m_database = QSqlDatabase::addDatabase("QSQLITE");
    m_database.setDatabaseName(m_databasePath);
    
    if (!m_database.open()) {
        qDebug() << "Error opening database:" << m_database.lastError().text();
        return false;
    }
    
    return true;
}

void DatabaseManager::closeDatabase()
{
    if (m_database.isOpen()) {
        m_database.close();
    }
}

bool DatabaseManager::createTables()
{
    QSqlQuery query;
    
    // Users table
    if (!query.exec("CREATE TABLE IF NOT EXISTS users ("
                   "id INTEGER PRIMARY KEY AUTOINCREMENT,"
                   "name TEXT NOT NULL,"
                   "department TEXT NOT NULL,"
                   "face_encoding BLOB,"
                   "created_date DATETIME DEFAULT CURRENT_TIMESTAMP,"
                   "updated_date DATETIME DEFAULT CURRENT_TIMESTAMP"
                   ")")) {
        qDebug() << "Error creating users table:" << query.lastError().text();
        return false;
    }

    // History table
    if (!query.exec("CREATE TABLE IF NOT EXISTS history ("
                   "id INTEGER PRIMARY KEY AUTOINCREMENT,"
                   "user_id INTEGER,"
                   "action_type TEXT NOT NULL,"
                   "status TEXT NOT NULL,"
                   "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,"
                   "FOREIGN KEY (user_id) REFERENCES users(id)"
                   ")")) {
        qDebug() << "Error creating history table:" << query.lastError().text();
        return false;
    }

    // Settings table
    if (!query.exec("CREATE TABLE IF NOT EXISTS settings ("
                   "key TEXT PRIMARY KEY,"
                   "value TEXT NOT NULL,"
                   "updated_date DATETIME DEFAULT CURRENT_TIMESTAMP"
                   ")")) {
        qDebug() << "Error creating settings table:" << query.lastError().text();
        return false;
    }

    return true;
}

bool DatabaseManager::addUser(const QString &name, const QString &department, const QByteArray &faceEncoding)
{
    QSqlQuery query;
    query.prepare("INSERT INTO users (name, department, face_encoding) VALUES (?, ?, ?)");
    query.addBindValue(name);
    query.addBindValue(department);
    query.addBindValue(faceEncoding);
    
    if (!query.exec()) {
        qDebug() << "Error adding user:" << query.lastError().text();
        return false;
    }
    
    return true;
}

bool DatabaseManager::updateUser(int userId, const QString &name, const QString &department)
{
    QSqlQuery query;
    query.prepare("UPDATE users SET name = ?, department = ?, updated_date = CURRENT_TIMESTAMP WHERE id = ?");
    query.addBindValue(name);
    query.addBindValue(department);
    query.addBindValue(userId);
    
    if (!query.exec()) {
        qDebug() << "Error updating user:" << query.lastError().text();
        return false;
    }
    
    return query.numRowsAffected() > 0;
}

bool DatabaseManager::deleteUser(int userId)
{
    QSqlQuery query;
    query.prepare("DELETE FROM users WHERE id = ?");
    query.addBindValue(userId);
    
    if (!query.exec()) {
        qDebug() << "Error deleting user:" << query.lastError().text();
        return false;
    }
    
    return query.numRowsAffected() > 0;
}

QVariantList DatabaseManager::getAllUsers()
{
    QVariantList users;
    QSqlQuery query("SELECT id, name, department, created_date FROM users ORDER BY name");
    
    while (query.next()) {
        QVariantMap user;
        user["id"] = query.value("id");
        user["name"] = query.value("name");
        user["department"] = query.value("department");
        user["created_date"] = query.value("created_date");
        users.append(user);
    }
    
    return users;
}

QVariantMap DatabaseManager::getUserById(int userId)
{
    QSqlQuery query;
    query.prepare("SELECT id, name, department, face_encoding, created_date FROM users WHERE id = ?");
    query.addBindValue(userId);
    
    if (query.exec() && query.next()) {
        QVariantMap user;
        user["id"] = query.value("id");
        user["name"] = query.value("name");
        user["department"] = query.value("department");
        user["face_encoding"] = query.value("face_encoding");
        user["created_date"] = query.value("created_date");
        return user;
    }
    
    return QVariantMap();
}

QVariantMap DatabaseManager::getUserByName(const QString &name)
{
    QSqlQuery query;
    query.prepare("SELECT id, name, department, face_encoding, created_date FROM users WHERE name = ?");
    query.addBindValue(name);
    
    if (query.exec() && query.next()) {
        QVariantMap user;
        user["id"] = query.value("id");
        user["name"] = query.value("name");
        user["department"] = query.value("department");
        user["face_encoding"] = query.value("face_encoding");
        user["created_date"] = query.value("created_date");
        return user;
    }
    
    return QVariantMap();
}

bool DatabaseManager::addHistoryLog(int userId, const QString &actionType, const QString &status)
{
    QSqlQuery query;
    query.prepare("INSERT INTO history (user_id, action_type, status) VALUES (?, ?, ?)");
    query.addBindValue(userId);
    query.addBindValue(actionType);
    query.addBindValue(status);
    
    if (!query.exec()) {
        qDebug() << "Error adding history log:" << query.lastError().text();
        return false;
    }
    
    return true;
}

QVariantList DatabaseManager::getHistoryLogs(int limit)
{
    QVariantList logs;
    QSqlQuery query;
    query.prepare("SELECT h.id, h.user_id, u.name, h.action_type, h.status, h.timestamp "
                 "FROM history h "
                 "LEFT JOIN users u ON h.user_id = u.id "
                 "ORDER BY h.timestamp DESC "
                 "LIMIT ?");
    query.addBindValue(limit);
    
    while (query.next()) {
        QVariantMap log;
        log["id"] = query.value("id");
        log["user_id"] = query.value("user_id");
        log["user_name"] = query.value("name");
        log["action_type"] = query.value("action_type");
        log["status"] = query.value("status");
        log["timestamp"] = query.value("timestamp");
        logs.append(log);
    }
    
    return logs;
}

QVariantList DatabaseManager::getHistoryLogsByUser(int userId, int limit)
{
    QVariantList logs;
    QSqlQuery query;
    query.prepare("SELECT h.id, h.user_id, u.name, h.action_type, h.status, h.timestamp "
                 "FROM history h "
                 "LEFT JOIN users u ON h.user_id = u.id "
                 "WHERE h.user_id = ? "
                 "ORDER BY h.timestamp DESC "
                 "LIMIT ?");
    query.addBindValue(userId);
    query.addBindValue(limit);
    
    while (query.next()) {
        QVariantMap log;
        log["id"] = query.value("id");
        log["user_id"] = query.value("user_id");
        log["user_name"] = query.value("name");
        log["action_type"] = query.value("action_type");
        log["status"] = query.value("status");
        log["timestamp"] = query.value("timestamp");
        logs.append(log);
    }
    
    return logs;
}

bool DatabaseManager::saveSetting(const QString &key, const QString &value)
{
    QSqlQuery query;
    query.prepare("INSERT OR REPLACE INTO settings (key, value, updated_date) VALUES (?, ?, CURRENT_TIMESTAMP)");
    query.addBindValue(key);
    query.addBindValue(value);
    
    if (!query.exec()) {
        qDebug() << "Error saving setting:" << query.lastError().text();
        return false;
    }
    
    return true;
}

QString DatabaseManager::getSetting(const QString &key, const QString &defaultValue)
{
    QSqlQuery query;
    query.prepare("SELECT value FROM settings WHERE key = ?");
    query.addBindValue(key);
    
    if (query.exec() && query.next()) {
        return query.value("value").toString();
    }
    
    return defaultValue;
}
