#include "networkmanager.h"
#include "../debug_config.h"
#include <QDebug>
#include <QVariantMap>
#include <QProcess>
#include <QFile>
#include <QStandardPaths>
#include <QRegularExpression>
#include <QThread>

NetworkManager::NetworkManager(QObject *parent)
    : QObject(parent)
    , m_isConnected(false)
    , m_lastWifiRadioStatus(false)
{
    // Initialize WiFi radio status
    m_lastWifiRadioStatus = checkWifiRadioStatus();
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
            RPI_DEBUG_VAR("Found network", ssid << "Signal:" << signal << "Connected:" << isConnected);
        }
    }
    
    // If no networks found, return empty list (no mock data)
    if (networks.isEmpty()) {
        RPI_DEBUG_MSG("No WiFi networks found");
    }
    
    RPI_DEBUG_VAR("Found WiFi networks", networks.size());
    return networks;
}

bool NetworkManager::connectToNetwork(const QString &ssid, const QString &password)
{
    RPI_DEBUG_VAR("Attempting to connect to network", ssid);
    RPI_DEBUG_VAR("Password length", password.length());
    
    // First, check if this network is already saved with a different password
    // If so, delete the saved connection first
    QProcess deleteProcess;
    deleteProcess.start("nmcli", QStringList() << "connection" << "delete" << ssid);
    deleteProcess.waitForFinished(5000);
    // Don't check exit code - it's OK if there's no existing connection to delete
    
    // Use nmcli to connect to network (Linux)
    QProcess process;
    QStringList args;
    
    if (password.isEmpty()) {
        // Open network
        args << "device" << "wifi" << "connect" << ssid;
        RPI_DEBUG("Connecting to open network");
    } else {
        // Secured network - use proper escaping for password
        args << "device" << "wifi" << "connect" << ssid << "password" << password;
        RPI_DEBUG("Connecting to secured network");
    }
    
    // Debug the full command
    QString fullCommand = "nmcli " + args.join(" ");
    RPI_DEBUG_VAR("Full nmcli command", fullCommand);
    
    process.start("nmcli", args);
    bool finished = process.waitForFinished(30000); // 30 second timeout
    
    if (!finished) {
        RPI_ERROR("nmcli command timed out");
        emit connectionFailed("Connection timeout");
        return false;
    }
    
    int exitCode = process.exitCode();
    QString stdOut = QString::fromLocal8Bit(process.readAllStandardOutput());
    QString stdErr = QString::fromLocal8Bit(process.readAllStandardError());
    
    RPI_DEBUG_VAR("nmcli exit code", exitCode);
    RPI_DEBUG_VAR("nmcli stdout", stdOut);
    RPI_DEBUG_VAR("nmcli stderr", stdErr);
    
    if (exitCode == 0) {
        // Connection command succeeded, but let's verify we're actually connected
        QThread::msleep(2000); // Wait 2 seconds for connection to establish
        
        // Check if we're actually connected to this network
        bool actuallyConnected = false;
        QProcess checkProcess;
        checkProcess.start("nmcli", QStringList() << "-t" << "-f" << "ACTIVE,SSID" << "dev" << "wifi");
        checkProcess.waitForFinished(5000);
        
        if (checkProcess.exitCode() == 0) {
            QString output = QString::fromLocal8Bit(checkProcess.readAllStandardOutput());
            QStringList lines = output.split('\n');
            
            for (const QString &line : lines) {
                if (line.startsWith("yes:") && line.contains(ssid)) {
                    actuallyConnected = true;
                    break;
                }
            }
        }
        
        if (actuallyConnected) {
            // Double check with a ping test
            QProcess pingProcess;
            pingProcess.start("ping", QStringList() << "-c" << "1" << "-W" << "3" << "8.8.8.8");
            pingProcess.waitForFinished(5000);
            
            bool internetConnected = (pingProcess.exitCode() == 0);
            RPI_DEBUG_VAR("Internet connectivity test", internetConnected);
            
            m_isConnected = true;
            m_currentNetwork = ssid;
            m_lastConnectedNetwork = ssid; // Save for auto-reconnect
            emit networkConnected(ssid);
            RPI_DEBUG_VAR("Successfully connected and verified connection to", ssid);
            return true;
        } else {
            RPI_ERROR("nmcli reported success but connection verification failed");
            emit connectionFailed("Connection verification failed");
            return false;
        }
    } else {
        // Check specific error types
        if (stdErr.contains("Secrets were required") || stdErr.contains("password")) {
            RPI_ERROR("Authentication failed - incorrect password");
            emit connectionFailed("Incorrect password");
        } else if (stdErr.contains("No network with SSID")) {
            RPI_ERROR("Network not found");
            emit connectionFailed("Network not found");
        } else {
            RPI_ERROR("Failed to connect:" << stdErr);
            emit connectionFailed("Failed to connect: " + stdErr);
        }
        return false;
    }
}

bool NetworkManager::disconnectFromNetwork()
{
    if (!m_isConnected) {
        return true;
    }

    RPI_DEBUG_VAR("Disconnecting from network", m_currentNetwork);
    
    // Disconnect using nmcli (Linux)
    QProcess process;
    process.start("nmcli", QStringList() << "device" << "disconnect");
    process.waitForFinished();
    
    QString previousNetwork = m_currentNetwork;
    m_isConnected = false;
    m_currentNetwork.clear();
    emit networkDisconnected();
    
    RPI_DEBUG_VAR("Disconnected from", previousNetwork);
    return true;
}

bool NetworkManager::isWifiEnabled() const
{
    // Check current WiFi radio status
    bool currentStatus = checkWifiRadioStatus();
    
    // Only log if status changed (non-const cast to update member)
    NetworkManager* self = const_cast<NetworkManager*>(this);
    if (self->m_lastWifiRadioStatus != currentStatus) {
        RPI_DEBUG_VAR("WiFi radio status changed to", currentStatus ? "enabled" : "disabled");
        self->m_lastWifiRadioStatus = currentStatus;
    }
    
    return currentStatus;
}

bool NetworkManager::checkWifiRadioStatus() const
{
    // Check if WiFi radio is enabled using nmcli
    QProcess process;
    process.start("nmcli", QStringList() << "radio" << "wifi");
    process.waitForFinished();
    
    QString output = QString::fromLocal8Bit(process.readAllStandardOutput());
    
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
        RPI_DEBUG_MSG("No last connected network to reconnect to");
        return false;
    }
    
    RPI_DEBUG_VAR("Attempting to reconnect to last network", m_lastConnectedNetwork);
    
    // Try to reconnect to the last network (without password for now)
    // In a real implementation, you might want to store the password securely
    QProcess process;
    process.start("nmcli", QStringList() << "device" << "wifi" << "connect" << m_lastConnectedNetwork);
    process.waitForFinished();
    
    if (process.exitCode() == 0) {
        m_isConnected = true;
        m_currentNetwork = m_lastConnectedNetwork;
        emit networkConnected(m_lastConnectedNetwork);
        RPI_DEBUG_VAR("Successfully reconnected to", m_lastConnectedNetwork);
        return true;
    } else {
        QString error = QString::fromLocal8Bit(process.readAllStandardError());
        RPI_ERROR("Failed to reconnect to last network:" << error);
        return false;
    }
}

bool NetworkManager::setWifiEnabled(bool enabled)
{
    RPI_DEBUG_VAR("Setting WiFi enabled", enabled);
    
    if (enabled) {
        // Enable WiFi using nmcli (Linux)
        QProcess process;
        process.start("nmcli", QStringList() << "radio" << "wifi" << "on");
        process.waitForFinished();
        
        if (process.exitCode() == 0) {
            RPI_DEBUG_MSG("WiFi enabled successfully");
            m_lastWifiRadioStatus = true;
            return true;
        } else {
            QString error = QString::fromLocal8Bit(process.readAllStandardError());
            RPI_ERROR("Failed to enable WiFi:" << error);
            return false;
        }
    } else {
        // Disable WiFi using nmcli (Linux)
        QProcess process;
        process.start("nmcli", QStringList() << "radio" << "wifi" << "off");
        process.waitForFinished();
        
        if (process.exitCode() == 0) {
            RPI_DEBUG_MSG("WiFi disabled successfully");
            m_lastWifiRadioStatus = false;
            // Clear connection state when WiFi is disabled
            m_isConnected = false;
            m_currentNetwork.clear();
            emit networkDisconnected();
            return true;
        } else {
            QString error = QString::fromLocal8Bit(process.readAllStandardError());
            RPI_ERROR("Failed to disable WiFi:" << error);
            return false;
        }
    }
}
