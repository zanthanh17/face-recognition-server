#include "networkmanager.h"
#include <QDebug>
#include <QVariantMap>
#include <QProcess>
#include <QFile>
#include <QStandardPaths>
#include <QRegularExpression>

NetworkManager::NetworkManager(QObject *parent)
    : QObject(parent)
    , m_isConnected(false)
{
}

NetworkManager::~NetworkManager()
{
    if (m_isConnected) {
        disconnectFromNetwork();
    }
}

QVariantList NetworkManager::getAvailableNetworks()
{
    QVariantList networks;
    
    // Use nmcli command to get available networks (Linux) with tabular format
    QProcess process;
    process.start("nmcli", QStringList() << "-t" << "-f" << "IN-USE,SSID,SIGNAL,SECURITY" << "device" << "wifi" << "list");
    process.waitForFinished();
    
    QString output = QString::fromLocal8Bit(process.readAllStandardOutput());
    QStringList lines = output.split('\n');
    
    for (const QString &line : lines) {
        QString trimmedLine = line.trimmed();
        if (trimmedLine.isEmpty()) continue;
        
        // Parse tabular format: IN-USE:SSID:SIGNAL:SECURITY
        QStringList parts = trimmedLine.split(':');
        if (parts.size() >= 4) {
            QVariantMap network;
            
            // Check if connected (has * in first column)
            bool isConnected = parts[0].contains("*");
            network["connected"] = isConnected;
            
            // SSID is 2nd column
            QString ssid = parts[1];
            
            // Skip networks with empty SSID (hidden networks)
            if (ssid.isEmpty()) {
                continue;
            }
            
            network["ssid"] = ssid;
            
            // Signal strength (3rd column)
            QString signalStr = parts[2];
            bool ok;
            int signal = signalStr.toInt(&ok);
            network["signal_strength"] = ok ? signal : 50;
            
            // Security (4th column)
            QString security = parts[3];
            network["security"] = security;
            network["secured"] = (security != "--" && security != "*");
            
            networks.append(network);
            qDebug() << "Found network:" << ssid << "Signal:" << signal << "Connected:" << isConnected;
        }
    }
    
    // If no networks found, return empty list (no mock data)
    if (networks.isEmpty()) {
        qDebug() << "No WiFi networks found";
    }
    
    qDebug() << "Found" << networks.size() << "WiFi networks";
    return networks;
}

bool NetworkManager::connectToNetwork(const QString &ssid, const QString &password)
{
    qDebug() << "Attempting to connect to network:" << ssid;
    
    // Use nmcli to connect to network (Linux)
    QProcess process;
    QStringList args;
    
    if (password.isEmpty()) {
        // Open network
        args << "device" << "wifi" << "connect" << ssid;
    } else {
        // Secured network
        args << "device" << "wifi" << "connect" << ssid << "password" << password;
    }
    
    process.start("nmcli", args);
    process.waitForFinished();
    
    if (process.exitCode() == 0) {
        m_isConnected = true;
        m_currentNetwork = ssid;
        m_lastConnectedNetwork = ssid; // Save for auto-reconnect
        emit networkConnected(ssid);
        qDebug() << "Successfully connected to:" << ssid;
        return true;
    } else {
        QString error = QString::fromLocal8Bit(process.readAllStandardError());
        qDebug() << "Failed to connect:" << error;
        emit connectionFailed("Failed to connect to network: " + error);
        return false;
    }
}

bool NetworkManager::disconnectFromNetwork()
{
    if (!m_isConnected) {
        return true;
    }

    qDebug() << "Disconnecting from network:" << m_currentNetwork;
    
    // Disconnect using nmcli (Linux)
    QProcess process;
    process.start("nmcli", QStringList() << "device" << "disconnect");
    process.waitForFinished();
    
    QString previousNetwork = m_currentNetwork;
    m_isConnected = false;
    m_currentNetwork.clear();
    emit networkDisconnected();
    
    qDebug() << "Disconnected from:" << previousNetwork;
    return true;
}

bool NetworkManager::isWifiEnabled() const
{
    // Check if WiFi radio is enabled using nmcli
    QProcess process;
    process.start("nmcli", QStringList() << "radio" << "wifi");
    process.waitForFinished();
    
    QString output = QString::fromLocal8Bit(process.readAllStandardOutput());
    qDebug() << "WiFi radio status:" << output.trimmed();
    
    // nmcli radio wifi returns "enabled" or "disabled"
    return output.trimmed().toLower() == "enabled";
}

bool NetworkManager::isConnected() const
{
    // Check real connection status by looking for connected network in wifi list
    QProcess process;
    process.start("nmcli", QStringList() << "-t" << "-f" << "IN-USE,SSID" << "device" << "wifi" << "list");
    process.waitForFinished();
    
    QString output = QString::fromLocal8Bit(process.readAllStandardOutput());
    QStringList lines = output.split('\n');
    
    for (const QString &line : lines) {
        QString trimmedLine = line.trimmed();
        if (trimmedLine.isEmpty()) continue;
        
        // Parse tabular format: IN-USE:SSID
        QStringList parts = trimmedLine.split(':');
        if (parts.size() >= 2) {
            // Check if connected (has * in first column)
            if (parts[0].contains("*")) {
                return true;
            }
        }
    }
    
    return m_isConnected; // Fallback to cached state
}

QString NetworkManager::getCurrentNetwork() const
{
    // Get current network name using nmcli (Linux) with tabular format
    QProcess process;
    process.start("nmcli", QStringList() << "-t" << "-f" << "IN-USE,SSID" << "device" << "wifi" << "list");
    process.waitForFinished();
    
    QString output = QString::fromLocal8Bit(process.readAllStandardOutput());
    QStringList lines = output.split('\n');
    
    for (const QString &line : lines) {
        QString trimmedLine = line.trimmed();
        if (trimmedLine.isEmpty()) continue;
        
        // Parse tabular format: IN-USE:SSID
        QStringList parts = trimmedLine.split(':');
        if (parts.size() >= 2) {
            // Check if connected (has * in first column)
            if (parts[0].contains("*")) {
                return parts[1]; // SSID is 2nd column
            }
        }
    }
    
    return m_currentNetwork; // Fallback to cached state
}

bool NetworkManager::reconnectToLastNetwork()
{
    if (m_lastConnectedNetwork.isEmpty()) {
        qDebug() << "No last connected network to reconnect to";
        return false;
    }
    
    qDebug() << "Attempting to reconnect to last network:" << m_lastConnectedNetwork;
    
    // Try to reconnect to the last network (without password for now)
    // In a real implementation, you might want to store the password securely
    QProcess process;
    process.start("nmcli", QStringList() << "device" << "wifi" << "connect" << m_lastConnectedNetwork);
    process.waitForFinished();
    
    if (process.exitCode() == 0) {
        m_isConnected = true;
        m_currentNetwork = m_lastConnectedNetwork;
        emit networkConnected(m_lastConnectedNetwork);
        qDebug() << "Successfully reconnected to:" << m_lastConnectedNetwork;
        return true;
    } else {
        QString error = QString::fromLocal8Bit(process.readAllStandardError());
        qDebug() << "Failed to reconnect to last network:" << error;
        return false;
    }
}

bool NetworkManager::setWifiEnabled(bool enabled)
{
    qDebug() << "Setting WiFi enabled:" << enabled;
    
    if (enabled) {
        // Enable WiFi using nmcli (Linux)
        QProcess process;
        process.start("nmcli", QStringList() << "radio" << "wifi" << "on");
        process.waitForFinished();
        
        if (process.exitCode() == 0) {
            qDebug() << "WiFi enabled successfully";
            return true;
        } else {
            QString error = QString::fromLocal8Bit(process.readAllStandardError());
            qDebug() << "Failed to enable WiFi:" << error;
            return false;
        }
    } else {
        // Disable WiFi using nmcli (Linux)
        QProcess process;
        process.start("nmcli", QStringList() << "radio" << "wifi" << "off");
        process.waitForFinished();
        
        if (process.exitCode() == 0) {
            qDebug() << "WiFi disabled successfully";
            // Clear connection state when WiFi is disabled
            m_isConnected = false;
            m_currentNetwork.clear();
            emit networkDisconnected();
            return true;
        } else {
            QString error = QString::fromLocal8Bit(process.readAllStandardError());
            qDebug() << "Failed to disable WiFi:" << error;
            return false;
        }
    }
}
