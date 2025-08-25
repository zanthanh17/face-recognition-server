#include "systemmonitor.h"
#include <QDebug>
#include <QDateTime>
#include <QProcess>
#include <QFile>
#include <QTextStream>
#include <QDir>
#include <QStorageInfo>
#include <QRegularExpression>

SystemMonitor::SystemMonitor(QObject *parent)
    : QObject(parent)
    , m_updateTimer(nullptr)
{
    m_updateTimer = new QTimer(this);
    connect(m_updateTimer, &QTimer::timeout, this, &SystemMonitor::updateMetrics);
}

SystemMonitor::~SystemMonitor()
{
    stopMonitoring();
}

void SystemMonitor::startMonitoring()
{
    if (m_updateTimer->isActive()) {
        return;
    }

    // Update metrics every 2 seconds
    m_updateTimer->start(2000);
    updateMetrics(); // Initial update
    qDebug() << "System monitoring started";
}

void SystemMonitor::stopMonitoring()
{
    if (m_updateTimer->isActive()) {
        m_updateTimer->stop();
        qDebug() << "System monitoring stopped";
    }
}

QVariantMap SystemMonitor::getSystemMetrics()
{
    return m_currentMetrics;
}

void SystemMonitor::updateMetrics()
{
    m_currentMetrics.clear();
    
    // Get current metrics
    double cpuUsage = getCpuUsage();
    double temperature = getTemperature();
    double memoryUsage = getMemoryUsage();
    double storageUsage = getStorageUsage();
    double networkUsage = getNetworkUsage();
    
    // qDebug() << "System Metrics - CPU:" << cpuUsage << "% Memory:" << memoryUsage << "% Storage:" << storageUsage << "% Network:" << networkUsage << "%"; // Disabled to reduce log noise
    
    // Only add valid metrics (temperature can be -1 if no sensor)
    m_currentMetrics["cpu"] = cpuUsage;
    if (temperature >= 0) {
        m_currentMetrics["temperature"] = temperature;
    } else {
        m_currentMetrics["temperature"] = "N/A";
    }
    m_currentMetrics["memory"] = memoryUsage;
    m_currentMetrics["storage"] = storageUsage;
    m_currentMetrics["network"] = networkUsage;
    m_currentMetrics["timestamp"] = QDateTime::currentDateTime().toString("hh:mm:ss");
    
    // qDebug() << "Emitting metricsUpdated signal with data:" << m_currentMetrics; // Disabled to reduce log noise
    
    // Get additional system info (update less frequently)
    static int infoCounter = 0;
    if (infoCounter % 10 == 0) { // Update every 20 seconds (10 * 2 seconds)
        m_currentMetrics["systemInfo"] = getSystemInfo();
        m_currentMetrics["uptime"] = getUptime();
        m_currentMetrics["loadAverage"] = getLoadAverage();
    }
    infoCounter++;

    emit metricsUpdated(m_currentMetrics);
}

double SystemMonitor::getCpuUsage()
{
    // Read CPU usage from /proc/stat
    QFile file("/proc/stat");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug() << "Failed to open /proc/stat";
        return 0.0;
    }
    
    QTextStream in(&file);
    QString line = in.readLine(); // Read first line (total CPU)
    file.close();
    
    if (line.isEmpty()) {
        return 0.0;
    }
    
    // Parse CPU line: cpu  user nice system idle iowait irq softirq steal guest guest_nice
    QStringList parts = line.split(QRegularExpression("\\s+"));
    if (parts.size() < 5) {
        return 0.0;
    }
    
    // Get current CPU times
    qint64 user = parts[1].toLongLong();
    qint64 nice = parts[2].toLongLong();
    qint64 system = parts[3].toLongLong();
    qint64 idle = parts[4].toLongLong();
    qint64 iowait = parts.size() > 5 ? parts[5].toLongLong() : 0;
    qint64 irq = parts.size() > 6 ? parts[6].toLongLong() : 0;
    qint64 softirq = parts.size() > 7 ? parts[7].toLongLong() : 0;
    qint64 steal = parts.size() > 8 ? parts[8].toLongLong() : 0;
    
    qint64 total = user + nice + system + idle + iowait + irq + softirq + steal;
    
    // Static variables to store previous values
    static qint64 prevIdle = 0;
    static qint64 prevTotal = 0;
    
    // Calculate CPU usage based on difference from previous reading
    if (prevTotal > 0) {
        qint64 totalDiff = total - prevTotal;
        qint64 idleDiff = idle - prevIdle;
        
        if (totalDiff > 0) {
            double usage = 100.0 - (idleDiff * 100.0 / totalDiff);
            // qDebug() << "CPU Usage calculated:" << usage << "% (totalDiff:" << totalDiff << "idleDiff:" << idleDiff << ")"; // Disabled to reduce log noise
            prevIdle = idle;
            prevTotal = total;
            return qBound(0.0, usage, 100.0);
        }
    }
    
    // First reading, store values for next time
    prevIdle = idle;
    prevTotal = total;
    qDebug() << "CPU: First reading, returning 0 (will be accurate next time)";
    return 0.0;
}

double SystemMonitor::getTemperature()
{
    // Try to read temperature from various sources
    QStringList tempFiles = {
        "/sys/class/thermal/thermal_zone0/temp",
        "/sys/class/hwmon/hwmon0/temp1_input",
        "/sys/class/hwmon/hwmon1/temp1_input"
    };
    
    for (const QString &tempFile : tempFiles) {
        QFile file(tempFile);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QTextStream in(&file);
            QString value = in.readLine().trimmed();
            file.close();
            
            if (!value.isEmpty()) {
                // Temperature is usually in millidegrees Celsius
                double temp = value.toDouble() / 1000.0;
                return qBound(0.0, temp, 100.0);
            }
        }
    }
    
    // Fallback: try using sensors command
    QProcess process;
    process.start("sensors", QStringList());
    process.waitForFinished();
    
    QString output = QString::fromLocal8Bit(process.readAllStandardOutput());
    QStringList lines = output.split('\n');
    
            for (const QString &line : lines) {
            if (line.contains("temp1:") || line.contains("Core 0:")) {
                // Extract temperature value (e.g., "temp1: +45.0°C")
                QRegularExpression rx("([0-9]+\\.[0-9]+)");
                QRegularExpressionMatch match = rx.match(line);
                if (match.hasMatch()) {
                    double temp = match.captured(1).toDouble();
                    return qBound(0.0, temp, 100.0);
                }
            }
        }
    
    // If no temperature sensor found, return -1 to indicate no data
    qDebug() << "No temperature sensor found";
    return -1.0;
}

double SystemMonitor::getMemoryUsage()
{
    // Read memory usage using cat command
    QProcess process;
    process.start("cat", QStringList() << "/proc/meminfo");
    process.waitForFinished();
    
    QString output = QString::fromLocal8Bit(process.readAllStandardOutput());
    QStringList lines = output.split('\n');
    
    qint64 totalMem = 0;
    qint64 availableMem = 0;
    
    for (int i = 0; i < qMin(10, lines.size()); i++) {
        QString line = lines[i].trimmed();
        
        if (line.startsWith("MemTotal:")) {
            // Parse: "MemTotal:       16041188 kB"
            QString value = line.mid(line.indexOf(":") + 1).trimmed();
            value = value.split(" ")[0]; // Get first part before space
            totalMem = value.toLongLong();
        } else if (line.startsWith("MemAvailable:")) {
            // Parse: "MemAvailable:    7552036 kB"
            QString value = line.mid(line.indexOf(":") + 1).trimmed();
            value = value.split(" ")[0]; // Get first part before space
            availableMem = value.toLongLong();
        }
    }
    
    if (totalMem > 0) {
        // Calculate memory usage: (Total - Available) / Total * 100
        double usage = ((totalMem - availableMem) * 100.0) / totalMem;
        
        // Limit to reasonable range (0-100%)
        usage = qBound(0.0, usage, 100.0);
        
        return usage;
    }
    
    return 0.0;
}

double SystemMonitor::getStorageUsage()
{
    // Get storage usage for root filesystem
    QStorageInfo storage = QStorageInfo::root();
    
    if (storage.isValid() && storage.isReady()) {
        qint64 total = storage.bytesTotal();
        qint64 available = storage.bytesAvailable();
        
        if (total > 0) {
            double usage = ((total - available) * 100.0) / total;
            return qBound(0.0, usage, 100.0);
        }
    }
    
    // Fallback: try to get storage info for current directory
    QStorageInfo currentStorage = QStorageInfo(QDir::current());
    if (currentStorage.isValid() && currentStorage.isReady()) {
        qint64 total = currentStorage.bytesTotal();
        qint64 available = currentStorage.bytesAvailable();
        
        if (total > 0) {
            double usage = ((total - available) * 100.0) / total;
            return qBound(0.0, usage, 100.0);
        }
    }
    
    return 0.0;
}

double SystemMonitor::getNetworkUsage()
{
    // Read network statistics from /proc/net/dev
    QFile file("/proc/net/dev");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug() << "Failed to open /proc/net/dev";
        return 0.0;
    }
    
    QTextStream in(&file);
    qint64 totalBytes = 0;
    
    // Skip header lines
    in.readLine(); // Inter-|   Receive
    in.readLine(); //  face |bytes    packets
    
    while (!in.atEnd()) {
        QString line = in.readLine();
        QStringList parts = line.split(QRegularExpression("\\s+"));
        
        if (parts.size() >= 10) {
            // Skip loopback interface
            QString interface = parts[0].remove(':');
            if (interface != "lo") {
                // Add received and transmitted bytes
                totalBytes += parts[1].toLongLong(); // received
                totalBytes += parts[9].toLongLong(); // transmitted
            }
        }
    }
    file.close();
    
    // Convert to a percentage (this is a simplified approach)
    // In a real implementation, you'd track the rate of change over time
    static qint64 lastTotalBytes = 0;
    static QDateTime lastUpdate = QDateTime::currentDateTime();
    
    QDateTime now = QDateTime::currentDateTime();
    qint64 timeDiff = lastUpdate.msecsTo(now);
    
    if (timeDiff > 0 && lastTotalBytes > 0) {
        qint64 bytesDiff = totalBytes - lastTotalBytes;
        double bytesPerSecond = (bytesDiff * 1000.0) / timeDiff;
        
        // Convert to a percentage (assuming 100Mbps = 100%)
        double maxBytesPerSecond = 100 * 1024 * 1024 / 8; // 100 Mbps in bytes/s
        double usage = (bytesPerSecond * 100.0) / maxBytesPerSecond;
        
        lastTotalBytes = totalBytes;
        lastUpdate = now;
        
        return qBound(0.0, usage, 100.0);
    }
    
    lastTotalBytes = totalBytes;
    lastUpdate = now;
    return 0.0;
}

QString SystemMonitor::getSystemInfo()
{
    // Get system information
    QProcess process;
    process.start("uname", QStringList() << "-a");
    process.waitForFinished();
    QString uname = QString::fromLocal8Bit(process.readAllStandardOutput()).trimmed();
    
    // Get CPU info
    QFile cpuFile("/proc/cpuinfo");
    QString cpuModel = "Unknown CPU";
    if (cpuFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&cpuFile);
        while (!in.atEnd()) {
            QString line = in.readLine();
            if (line.startsWith("model name")) {
                QStringList parts = line.split(':');
                if (parts.size() >= 2) {
                    cpuModel = parts[1].trimmed();
                    break;
                }
            }
        }
        cpuFile.close();
    }
    
    return QString("CPU: %1\nSystem: %2").arg(cpuModel).arg(uname);
}

QString SystemMonitor::getUptime()
{
    // Read system uptime from /proc/uptime
    QFile file("/proc/uptime");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return "Unknown";
    }
    
    QTextStream in(&file);
    QString line = in.readLine();
    file.close();
    
    if (line.isEmpty()) {
        return "Unknown";
    }
    
    QStringList parts = line.split(' ');
    if (parts.size() >= 1) {
        qint64 uptimeSeconds = parts[0].toLongLong();
        qint64 days = uptimeSeconds / 86400;
        qint64 hours = (uptimeSeconds % 86400) / 3600;
        qint64 minutes = (uptimeSeconds % 3600) / 60;
        
        if (days > 0) {
            return QString("%1d %2h %3m").arg(days).arg(hours).arg(minutes);
        } else if (hours > 0) {
            return QString("%1h %2m").arg(hours).arg(minutes);
        } else {
            return QString("%1m").arg(minutes);
        }
    }
    
    return "Unknown";
}

QString SystemMonitor::getLoadAverage()
{
    // Read load average from /proc/loadavg
    QFile file("/proc/loadavg");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return "Unknown";
    }
    
    QTextStream in(&file);
    QString line = in.readLine();
    file.close();
    
    if (line.isEmpty()) {
        return "Unknown";
    }
    
    QStringList parts = line.split(' ');
    if (parts.size() >= 3) {
        return QString("%1, %2, %3").arg(parts[0]).arg(parts[1]).arg(parts[2]);
    }
    
    return "Unknown";
}
