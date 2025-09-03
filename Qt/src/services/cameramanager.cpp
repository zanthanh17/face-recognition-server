#include "cameramanager.h"
#include "../debug_config.h"
#include <QDebug>
#include <QBuffer>
#include <QTimer>
#include <QEventLoop>
#include <QProcess>
#include <QDir>
#include <QStandardPaths>
#include <QFileInfo>
#include <QDateTime>

CameraManager::CameraManager(QObject *parent)
    : QObject(parent)
    , m_cameraAvailable(false)
    , m_cameraRunning(false)
    , m_camera(nullptr)
    , m_captureSession(nullptr)
    , m_imageCapture(nullptr)
    , m_captureInProgress(false)
{
    // Check if rpicam-apps is available
    QProcess process;
    process.start("which", QStringList() << "rpicam-still");
    process.waitForFinished();
    
    if (process.exitCode() == 0) {
        m_cameraAvailable = true;
        RPI_DEBUG_MSG("rpicam-still available - camera supported");
    } else {
        // Fallback: check for traditional camera
        QProcess process2;
        process2.start("which", QStringList() << "raspistill");
        process2.waitForFinished();
        
        if (process2.exitCode() == 0) {
            m_cameraAvailable = true;
            RPI_DEBUG_MSG("raspistill available - camera supported");
        } else {
            m_cameraAvailable = false;
            RPI_ERROR("No camera tools available (rpicam-still or raspistill)");
        }
    }
}

CameraManager::~CameraManager()
{
    stopCamera();
}

bool CameraManager::startCamera()
{
    if (!m_cameraAvailable) {
        emit cameraError("Camera not available");
        return false;
    }

    if (m_cameraRunning) {
        RPI_DEBUG_MSG("Camera already running");
        return true;
    }

    try {
        // For rpicam-apps, we don't need to start a persistent camera
        // We'll capture on-demand
        m_cameraRunning = true;
        emit cameraStarted();
        RPI_DEBUG_MSG("Camera service started (rpicam-apps mode)");
        return true;
    } catch (const std::exception &e) {
        RPI_ERROR("Failed to start camera:" << e.what());
        emit cameraError(QString("Failed to start camera: %1").arg(e.what()));
        return false;
    }
}

void CameraManager::stopCamera()
{
    if (!m_cameraRunning) {
        return;
    }

    m_cameraRunning = false;
    emit cameraStopped();
    RPI_DEBUG_MSG("Camera service stopped");
}

QByteArray CameraManager::captureImage()
{
    if (!m_cameraAvailable) {
        RPI_ERROR("Camera not available");
        return QByteArray();
    }

    if (m_captureInProgress) {
        RPI_DEBUG_MSG("Capture already in progress");
        return QByteArray();
    }

    m_captureInProgress = true;
    m_lastCapturedImage.clear();
    
    // Create temporary file for capture
    QString tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    QString tempFile = tempDir + "/face_capture_" + QString::number(QDateTime::currentMSecsSinceEpoch()) + ".jpg";
    
    // Try rpicam-still first, fallback to raspistill
    QString cameraCommand = "rpicam-still";
    QStringList arguments;
    
    QProcess process;
    process.start("which", QStringList() << "rpicam-still");
    process.waitForFinished();
    
    if (process.exitCode() != 0) {
        cameraCommand = "raspistill";
        RPI_DEBUG_MSG("Using raspistill as fallback");
    }
    
    // Set capture parameters
    arguments << "-o" << tempFile
             << "-t" << "1000"  // Timeout 1 second
             << "-w" << "640"   // Width
             << "-h" << "480"   // Height
             << "-q" << "80"    // Quality
             << "-n";           // No preview
    
    RPI_DEBUG_MSG("Capturing image with" << cameraCommand << arguments.join(" "));
    
    // Start capture process
    QProcess captureProcess;
    captureProcess.start(cameraCommand, arguments);
    
    // Wait for capture to complete
    if (captureProcess.waitForFinished(5000)) { // 5 second timeout
        if (captureProcess.exitCode() == 0) {
            // Read captured image
            QFile file(tempFile);
            if (file.open(QIODevice::ReadOnly)) {
                m_lastCapturedImage = file.readAll();
                file.close();
                RPI_DEBUG_VAR("Image captured successfully, size", m_lastCapturedImage.size());
                
                // Clean up temp file
                QFile::remove(tempFile);
                
                m_captureInProgress = false;
                return m_lastCapturedImage;
            } else {
                RPI_ERROR("Failed to read captured image file");
            }
        } else {
            RPI_ERROR("Camera capture failed with exit code:" << captureProcess.exitCode());
            RPI_ERROR("Error output:" << captureProcess.readAllStandardError());
        }
    } else {
        RPI_ERROR("Camera capture timeout");
        captureProcess.kill();
    }
    
    m_captureInProgress = false;
    return QByteArray();
}

void CameraManager::onImageCaptured(int id, const QImage &image)
{
    // This method is not used in rpicam-apps mode
    Q_UNUSED(id)
    Q_UNUSED(image)
}

void CameraManager::onImageCaptureError(int id, QImageCapture::Error error, const QString &errorString)
{
    // This method is not used in rpicam-apps mode
    Q_UNUSED(id)
    Q_UNUSED(error)
    Q_UNUSED(errorString)
}

bool CameraManager::isCameraAvailable() const
{
    return m_cameraAvailable;
}

bool CameraManager::isCameraRunning() const
{
    return m_cameraRunning;
}

bool CameraManager::isImageCaptureReady() const
{
    return m_cameraAvailable && !m_captureInProgress;
}
