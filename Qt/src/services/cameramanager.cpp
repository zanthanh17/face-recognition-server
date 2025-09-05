#include "cameramanager.h"
#include <QDebug>
#include <QBuffer>
#include <QTimer>
#include <QEventLoop>
#include <QCamera>
#include <QMediaCaptureSession>
#include <QImageCapture>
#include <QMediaDevices>

CameraManager::CameraManager(QObject *parent)
    : QObject(parent)
    , m_cameraAvailable(false)
    , m_cameraRunning(false)
    , m_camera(nullptr)
    , m_captureSession(nullptr)
    , m_imageCapture(nullptr)
    , m_captureInProgress(false)
{
    // Check if camera is available
    QList<QCameraDevice> cameras = QMediaDevices::videoInputs();
    m_cameraAvailable = !cameras.isEmpty();
    
    if (m_cameraAvailable) {
        qDebug() << "Camera available:" << cameras.first().description();
    } else {
        qDebug() << "No camera available";
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
        qDebug() << "Camera already running";
        return true;
    }

    try {
        // Create camera and capture session
        QList<QCameraDevice> cameras = QMediaDevices::videoInputs();
        if (cameras.isEmpty()) {
            emit cameraError("No camera found");
            return false;
        }

        m_camera = new QCamera(cameras.first(), this);
        m_captureSession = new QMediaCaptureSession(this);
        m_imageCapture = new QImageCapture(this);

        m_captureSession->setCamera(m_camera);
        m_captureSession->setImageCapture(m_imageCapture);

        // Connect signals
        connect(m_imageCapture, &QImageCapture::imageCaptured,
                this, &CameraManager::onImageCaptured);
        connect(m_imageCapture, &QImageCapture::errorOccurred,
                this, &CameraManager::onImageCaptureError);
        
        // Connect camera status signals
        connect(m_camera, &QCamera::activeChanged, [this](bool active) {
            qDebug() << "Camera active changed:" << active;
        });
        
        // Connect image capture ready signal
        connect(m_imageCapture, &QImageCapture::readyForCaptureChanged, [this](bool ready) {
            qDebug() << "Image capture ready for capture:" << ready;
        });

        m_camera->start();
        m_cameraRunning = true;
        emit cameraStarted();
        qDebug() << "Camera started successfully";
        return true;
    } catch (const std::exception &e) {
        qDebug() << "Failed to start camera:" << e.what();
        emit cameraError(QString("Failed to start camera: %1").arg(e.what()));
        return false;
    }
}

void CameraManager::stopCamera()
{
    if (!m_cameraRunning) {
        return;
    }

    if (m_camera) {
        m_camera->stop();
        delete m_camera;
        m_camera = nullptr;
    }
    
    if (m_captureSession) {
        delete m_captureSession;
        m_captureSession = nullptr;
    }
    
    if (m_imageCapture) {
        delete m_imageCapture;
        m_imageCapture = nullptr;
    }

    m_cameraRunning = false;
    emit cameraStopped();
    qDebug() << "Camera stopped";
}

QByteArray CameraManager::captureImage()
{
    if (!m_cameraRunning || !m_imageCapture) {
        qDebug() << "Camera not running or image capture not available";
        return QByteArray();
    }

    if (m_captureInProgress) {
        qDebug() << "Capture already in progress";
        return QByteArray();
    }

    // Check if camera is ready
    if (m_camera && !m_camera->isActive()) {
        qDebug() << "Camera not active";
        return QByteArray();
    }

    // Check if image capture is ready
    if (!m_imageCapture->isReadyForCapture()) {
        qDebug() << "Image capture not ready for capture";
        return QByteArray();
    }

    // If we have a previously captured image, return it
    if (!m_lastCapturedImage.isEmpty()) {
        qDebug() << "Returning previously captured image, size:" << m_lastCapturedImage.size();
        return m_lastCapturedImage;
    }

    m_captureInProgress = true;
    m_lastCapturedImage.clear();
    
    // Capture image
    int id = m_imageCapture->capture();
    if (id == -1) {
        qDebug() << "Failed to start image capture";
        m_captureInProgress = false;
        return QByteArray();
    }

    qDebug() << "Image capture started with id:" << id;
    
    // Wait for capture to complete (with timeout)
    QTimer::singleShot(5000, [this]() {
        if (m_captureInProgress) {
            qDebug() << "Image capture timeout";
            m_captureInProgress = false;
        }
    });

    // For now, return empty - the actual image will be available in onImageCaptured
    return QByteArray();
}

void CameraManager::onImageCaptured(int id, const QImage &image)
{
    qDebug() << "Image captured with id:" << id << "size:" << image.size();
    
    // Convert image to JPEG bytes
    QBuffer buffer(&m_lastCapturedImage);
    buffer.open(QIODevice::WriteOnly);
    image.save(&buffer, "JPEG", 80); // 80% quality
    buffer.close();
    
    m_captureInProgress = false;
    qDebug() << "Image converted to JPEG, size:" << m_lastCapturedImage.size();
}

void CameraManager::onImageCaptureError(int id, QImageCapture::Error error, const QString &errorString)
{
    qDebug() << "Image capture error:" << errorString;
    m_captureInProgress = false;
    emit cameraError(QString("Image capture failed: %1").arg(errorString));
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
    return m_imageCapture && m_imageCapture->isReadyForCapture();
}
