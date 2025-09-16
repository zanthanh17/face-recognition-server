#include "cameramanager.h"
#include "../debug_config.h"
#include <QDebug>
#include <QBuffer>
#include <QTimer>
#include <QEventLoop>
#include <QCamera>
#include <QMediaCaptureSession>
#include <QImageCapture>
#include <QMediaDevices>
#include <QProcess>
#include <QFile>
#include <QDir>
#include <QStandardPaths>

CameraManager::CameraManager(QObject *parent)
    : QObject(parent)
    , m_cameraAvailable(false)
    , m_cameraRunning(false)
    , m_camera(nullptr)
    , m_captureSession(nullptr)
    , m_imageCapture(nullptr)
    , m_captureInProgress(false)
{
    // Check if running on Raspberry Pi
    bool isRaspberryPi = false;
    QFile cpuInfo("/proc/cpuinfo");
    if (cpuInfo.open(QIODevice::ReadOnly)) {
        QByteArray data = cpuInfo.readAll();
        isRaspberryPi = data.contains("BCM") || data.contains("Raspberry Pi");
        cpuInfo.close();
    }
    
    if (isRaspberryPi) {
        CAMERA_DEBUG_MSG("Detected Raspberry Pi - using enhanced camera detection");
        m_cameraAvailable = checkRaspberryPiCamera();
    } else {
        // Standard camera detection for desktop
        QList<QCameraDevice> cameras = QMediaDevices::videoInputs();
        m_cameraAvailable = !cameras.isEmpty();
        
        if (m_cameraAvailable) {
            // List all available cameras
            CAMERA_DEBUG_MSG("Available cameras:");
            for (int i = 0; i < cameras.size(); ++i) {
                CAMERA_DEBUG("Camera" << i << ":" << cameras[i].description() << "ID:" << cameras[i].id());
            }
            
            // Try to find DV20 USB camera
            QCameraDevice usbCamera;
            bool foundUsbCamera = false;
            for (const QCameraDevice &camera : cameras) {
                CAMERA_DEBUG("Checking camera:" << camera.description() << "ID:" << camera.id());
                if (camera.description().contains("DV20") || 
                    camera.description().contains("USB Composite") ||
                    camera.id().contains("video0") ||
                    camera.id().contains("video1")) {
                    usbCamera = camera;
                    foundUsbCamera = true;
                    CAMERA_DEBUG("Found DV20 USB camera:" << camera.description() << "ID:" << camera.id());
                    break;
                }
            }
            
            if (foundUsbCamera) {
                m_preferredCamera = usbCamera;
                CAMERA_DEBUG("Using USB camera:" << usbCamera.description());
            } else {
                m_preferredCamera = cameras.first();
                CAMERA_DEBUG("Using first available camera:" << cameras.first().description());
            }
        }
    }
    
    if (!m_cameraAvailable) {
        RPI_WARNING("No camera available");
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
        CAMERA_DEBUG_MSG("Camera already running");
        return true;
    }

    try {
        // Create camera and capture session
        QList<QCameraDevice> cameras = QMediaDevices::videoInputs();
        if (cameras.isEmpty()) {
            emit cameraError("No camera found");
            return false;
        }

        // Use preferred camera (USB camera if available)
        m_camera = new QCamera(m_preferredCamera, this);
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
            CAMERA_DEBUG("Camera active changed:" << active);
        });
        
        // Connect image capture ready signal
        connect(m_imageCapture, &QImageCapture::readyForCaptureChanged, [this](bool ready) {
            CAMERA_DEBUG("Image capture ready for capture:" << ready);
        });
        
        // Set image capture format to reduce corruption
        m_imageCapture->setFileFormat(QImageCapture::JPEG);
        m_imageCapture->setQuality(QImageCapture::HighQuality);

        m_camera->start();
        m_cameraRunning = true;
        emit cameraStarted();
        CAMERA_DEBUG_MSG("Camera started successfully");
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
    CAMERA_DEBUG_MSG("Camera stopped");
}

QByteArray CameraManager::captureImage()
{
    if (!m_cameraRunning || !m_imageCapture) {
        // Camera not running or image capture not available
        return QByteArray();
    }

    if (m_captureInProgress) {
        // Capture already in progress
        return QByteArray();
    }

    // Check if camera is ready
    if (m_camera && !m_camera->isActive()) {
        // Camera not active
        return QByteArray();
    }

    // Check if image capture is ready
    if (!m_imageCapture->isReadyForCapture()) {
        // Image capture not ready for capture
        return QByteArray();
    }

    // If we have a previously captured image, return it
    if (!m_lastCapturedImage.isEmpty()) {
        // Returning previously captured image
        return m_lastCapturedImage;
    }

    m_captureInProgress = true;
    m_lastCapturedImage.clear();
    
    // Capture image
    int id = m_imageCapture->capture();
    if (id == -1) {
        // Failed to start image capture
        m_captureInProgress = false;
        return QByteArray();
    }

    // Image capture started
    
    // Wait for capture to complete (with timeout)
    QTimer::singleShot(5000, [this]() {
        if (m_captureInProgress) {
            // Image capture timeout
            m_captureInProgress = false;
        }
    });

    // For now, return empty - the actual image will be available in onImageCaptured
    return QByteArray();
}

void CameraManager::onImageCaptured(int id, const QImage &image)
{
    CAMERA_DEBUG("Image captured with id:" << id << "size:" << image.size());
    
    // Validate image before processing
    if (image.isNull() || image.width() == 0 || image.height() == 0) {
        RPI_WARNING("Invalid image captured, skipping");
        m_captureInProgress = false;
        return;
    }
    
    // Convert image to JPEG bytes with better quality settings
    QBuffer buffer(&m_lastCapturedImage);
    buffer.open(QIODevice::WriteOnly);
    
    // Use higher quality and proper JPEG settings to reduce corruption
    if (image.save(&buffer, "JPEG", 95)) {
        m_captureInProgress = false;
        CAMERA_DEBUG("Image converted to JPEG successfully, size:" << m_lastCapturedImage.size());
    } else {
        RPI_ERROR("Failed to convert image to JPEG");
        m_lastCapturedImage.clear();
        m_captureInProgress = false;
    }
    buffer.close();
}

void CameraManager::onImageCaptureError(int id, QImageCapture::Error error, const QString &errorString)
{
    RPI_ERROR("Image capture error:" << errorString);
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

bool CameraManager::checkRaspberryPiCamera()
{
    CAMERA_DEBUG_MSG("Checking Raspberry Pi camera availability");
    
    // Check for USB cameras first
    QList<QCameraDevice> cameras = QMediaDevices::videoInputs();
    if (!cameras.isEmpty()) {
        CAMERA_DEBUG_MSG("Found Qt Multimedia cameras:");
        for (int i = 0; i < cameras.size(); ++i) {
            CAMERA_DEBUG("Camera" << i << ":" << cameras[i].description() << "ID:" << cameras[i].id());
        }
        
        // Try to find USB camera
        for (const QCameraDevice &camera : cameras) {
            if (camera.description().contains("DV20") || 
                camera.description().contains("USB Composite") ||
                camera.id().contains("video0") ||
                camera.id().contains("video1") ||
                camera.id().contains("video2")) {
                m_preferredCamera = camera;
                CAMERA_DEBUG("Using USB camera:" << camera.description());
                return true;
            }
        }
        
        // Use first available camera
        m_preferredCamera = cameras.first();
        CAMERA_DEBUG("Using first available camera:" << cameras.first().description());
        return true;
    }
    
    // Check for camera devices using v4l2
    CAMERA_DEBUG_MSG("No Qt Multimedia cameras found, checking v4l2 devices");
    for (int i = 0; i < 10; ++i) {
        QString devicePath = QString("/dev/video%1").arg(i);
        if (QFile::exists(devicePath)) {
            CAMERA_DEBUG("Found camera device:" << devicePath);
            
            // Test if device is accessible
            QFile device(devicePath);
            if (device.open(QIODevice::ReadOnly)) {
                device.close();
                CAMERA_DEBUG("Camera device is accessible:" << devicePath);
                
                // Create a dummy camera device for this path
                // This is a workaround for RPi where Qt Multimedia might not detect cameras properly
                m_preferredCamera = QCameraDevice();
                return true;
            } else {
                CAMERA_DEBUG("Camera device not accessible:" << devicePath);
            }
        }
    }
    
    // Check for libcamera (RPi Camera Module)
    CAMERA_DEBUG_MSG("Checking for libcamera support");
    QProcess libcameraProcess;
    libcameraProcess.start("libcamera-hello", QStringList() << "--list-cameras");
    if (libcameraProcess.waitForFinished(3000)) {
        QString output = libcameraProcess.readAllStandardOutput();
        if (output.contains("Available cameras")) {
            CAMERA_DEBUG("Found libcamera support");
            // For now, we'll use Qt Multimedia fallback
            // In the future, we could implement libcamera integration
            return true;
        }
    }
    
    CAMERA_DEBUG_MSG("No cameras found on Raspberry Pi");
    return false;
}
