#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QLoggingCategory>
#include <QDir>
#include <QStandardPaths>
#include "src/bridge/qmlbridge.h"
#include "src/qt_logging_config.h"
#include "src/services/frameprovider.h"

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    
    // Raspberry Pi specific configuration
    #ifdef Q_OS_LINUX
    // Check if running on Raspberry Pi
    QFile cpuInfo("/proc/cpuinfo");
    bool isRaspberryPi = false;
    if (cpuInfo.open(QIODevice::ReadOnly)) {
        QByteArray data = cpuInfo.readAll();
        isRaspberryPi = data.contains("BCM") || data.contains("Raspberry Pi");
        cpuInfo.close();
    }
    
    if (isRaspberryPi) {
        qDebug() << "Detected Raspberry Pi - configuring for embedded environment";
        
        // Set Qt Multimedia backend to GStreamer for RPi
        qputenv("QT_MULTIMEDIA_PREFERRED_PLUGINS", "gstreamer");
        
        // GStreamer environment variables for RPi
        qputenv("GST_DEBUG", "0");
        qputenv("GST_PLUGIN_PATH", "/usr/lib/aarch64-linux-gnu/gstreamer-1.0");
        qputenv("GST_REGISTRY_UPDATE", "no");
        
        // Disable hardware acceleration if not available
        qputenv("QT_OPENGL", "software");
        
        // Set display for headless operation
        if (qgetenv("DISPLAY").isEmpty()) {
            qputenv("DISPLAY", ":0");
        }
        
        qDebug() << "RPi environment configured:";
        qDebug() << "  QT_MULTIMEDIA_PREFERRED_PLUGINS:" << qgetenv("QT_MULTIMEDIA_PREFERRED_PLUGINS");
        qDebug() << "  GST_DEBUG:" << qgetenv("GST_DEBUG");
        qDebug() << "  DISPLAY:" << qgetenv("DISPLAY");
    }
    #endif
    
    // Disable QML debugging for production (must be set before creating QGuiApplication)
    qputenv("QT_QML_DEBUG", "0");
    
    QGuiApplication app(argc, argv);
    
    // Disable Qt's internal JPEG corruption logs to reduce noise
    // This can be overridden by setting QT_LOGGING_RULES environment variable
    disableQtJPEGCorruptionLogs();
    
    // Alternative: Set via environment variable
    // You can also set: export QT_LOGGING_RULES="qt.gui.imageio.*=false"
    qputenv("QT_LOGGING_RULES", "qt.gui.imageio.*=false");

    QQmlApplicationEngine engine;
    
    // Create and initialize QML Bridge
    QmlBridge qmlBridge;
    
    // Register frame provider with QML engine
    if (qmlBridge.getFrameProvider()) {
        engine.addImageProvider("frames", qmlBridge.getFrameProvider());
    }
    
    // Expose QML Bridge to QML
    engine.rootContext()->setContextProperty("backend", &qmlBridge);
    
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
