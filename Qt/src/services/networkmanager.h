#ifndef NETWORKMANAGER_H
#define NETWORKMANAGER_H

#include <QObject>
#include <QVariantList>
#include <QString>

class NetworkManager : public QObject
{
    Q_OBJECT

public:
    explicit NetworkManager(QObject *parent = nullptr);
    ~NetworkManager();

    // Network operations
    QVariantList getAvailableNetworks();
    bool connectToNetwork(const QString &ssid, const QString &password);
    bool disconnectFromNetwork();
    bool setWifiEnabled(bool enabled);
    bool isWifiEnabled() const;
    bool isConnected() const;
    QString getCurrentNetwork() const;
    bool reconnectToLastNetwork();

signals:
    void networkConnected(const QString &ssid);
    void networkDisconnected();
    void connectionFailed(const QString &error);

private:
    bool checkWifiRadioStatus() const; // Private function to check WiFi radio status

private:
    bool m_isConnected;
    QString m_currentNetwork;
    QString m_lastConnectedNetwork; // Store last connected network for auto-reconnect
    bool m_lastWifiRadioStatus; // Track last WiFi radio status to detect changes
};

#endif // NETWORKMANAGER_H
