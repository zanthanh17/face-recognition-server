#ifndef SYSTEMMONITOR_H
#define SYSTEMMONITOR_H

#include <QObject>
#include <QVariantMap>
#include <QTimer>

class SystemMonitor : public QObject
{
    Q_OBJECT

public:
    explicit SystemMonitor(QObject *parent = nullptr);
    ~SystemMonitor();

    // System monitoring operations
    void startMonitoring();
    void stopMonitoring();
    QVariantMap getSystemMetrics();

signals:
    void metricsUpdated(const QVariantMap &metrics);

private slots:
    void updateMetrics();

private:
    QTimer *m_updateTimer;
    QVariantMap m_currentMetrics;

    // Metric calculation methods
    double getCpuUsage();
    double getTemperature();
    double getMemoryUsage();
    double getStorageUsage();
    double getNetworkUsage();
    
    // Additional system info methods
    QString getSystemInfo();
    QString getUptime();
    QString getLoadAverage();
};

#endif // SYSTEMMONITOR_H
