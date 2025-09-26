#include "cameragrabber.h"
#include "frameprovider.h"
#include <QDebug>
#include <QImage>
#include <QFile>

CameraGrabber::CameraGrabber(FrameProvider* provider, QObject* parent)
    : QObject(parent)
    , m_provider(provider)
    , m_timer(new QTimer(this))
    , m_capture(nullptr)
{
    connect(m_timer, &QTimer::timeout, this, &CameraGrabber::grabFrame);
}

CameraGrabber::~CameraGrabber() {
    stop();
    if (m_capture) {
        delete m_capture;
        m_capture = nullptr;
    }
}

QString CameraGrabber::getGStreamerPipeline() {
    // Check if running on Raspberry Pi
    bool isRaspberryPi = false;
    QFile cpuInfo("/proc/cpuinfo");
    if (cpuInfo.open(QIODevice::ReadOnly)) {
        QByteArray data = cpuInfo.readAll();
        isRaspberryPi = data.contains("BCM") || data.contains("Raspberry Pi");
        cpuInfo.close();
    }
    
    if (isRaspberryPi) {
        // Raspberry Pi camera pipeline using libcamerasrc
        return QString(
            "libcamerasrc ! "
            "video/x-raw,format=NV12,width=640,height=480,framerate=30/1 ! "
            "queue leaky=downstream max-size-buffers=2 ! "
            "videoconvert ! video/x-raw,format=BGR ! "
            "appsink drop=true max-buffers=1 sync=false"
        );
    } else {
        // Generic USB camera pipeline
        return QString(
            "v4l2src device=/dev/video0 ! "
            "video/x-raw,width=640,height=480,framerate=30/1 ! "
            "videoconvert ! video/x-raw,format=BGR ! "
            "appsink drop=true max-buffers=1 sync=false"
        );
    }
}

bool CameraGrabber::initializeCamera() {
    if (m_capture) {
        delete m_capture;
        m_capture = nullptr;
    }
    
    // Try GStreamer pipeline first
    QString pipeline = getGStreamerPipeline();
    qDebug() << "Trying GStreamer pipeline:" << pipeline;
    
    m_capture = new cv::VideoCapture(pipeline.toStdString(), cv::CAP_GSTREAMER);
    
    if (!m_capture->isOpened()) {
        qDebug() << "GStreamer pipeline failed, trying default camera";
        delete m_capture;
        
        // Fallback to default camera
        m_capture = new cv::VideoCapture(0);
        
        if (!m_capture->isOpened()) {
            // Try other video devices
            for (int i = 1; i <= 4; i++) {
                delete m_capture;
                m_capture = new cv::VideoCapture(i);
                if (m_capture->isOpened()) {
                    qDebug() << "Opened camera at index" << i;
                    break;
                }
            }
        }
    }
    
    if (m_capture && m_capture->isOpened()) {
        // Set camera properties for better performance
        m_capture->set(cv::CAP_PROP_FRAME_WIDTH, 640);
        m_capture->set(cv::CAP_PROP_FRAME_HEIGHT, 480);
        m_capture->set(cv::CAP_PROP_FPS, 30);
        m_capture->set(cv::CAP_PROP_BUFFERSIZE, 1); // Reduce buffer to get latest frame
        
        qDebug() << "Camera initialized successfully";
        return true;
    }
    
    qDebug() << "Failed to initialize camera";
    return false;
}

void CameraGrabber::start(int fps) {
    if (m_isRunning) {
        qDebug() << "Camera already running";
        return;
    }
    
    if (!initializeCamera()) {
        emit cameraError("Failed to initialize camera");
        return;
    }
    
    m_isRunning = true;
    int interval = qMax(10, 1000 / qMax(1, fps));
    m_timer->start(interval);
    
    emit cameraStarted();
    qDebug() << "Camera started with" << fps << "fps";
}

void CameraGrabber::stop() {
    if (!m_isRunning) {
        return;
    }
    
    m_isRunning = false;
    m_timer->stop();
    
    if (m_capture) {
        m_capture->release();
    }
    
    emit cameraStopped();
    qDebug() << "Camera stopped";
}

void CameraGrabber::grabFrame() {
    if (!m_capture || !m_capture->isOpened() || !m_isRunning) {
        return;
    }
    
    cv::Mat frame;
    if (!m_capture->read(frame)) {
        qDebug() << "Failed to read frame";
        return;
    }
    
    if (frame.empty()) {
        return;
    }
    
    // Convert BGR to RGB
    cv::Mat rgb;
    cv::cvtColor(frame, rgb, cv::COLOR_BGR2RGB);
    
    // Convert to QImage
    QImage img(rgb.data, rgb.cols, rgb.rows, rgb.step, QImage::Format_RGB888);
    
    // Update provider with new frame
    m_provider->setFrame(img.copy());
    
    // Emit signal that new frame is ready
    emit frameReady();
}

QImage CameraGrabber::captureCurrentFrame() {
    if (m_provider) {
        return m_provider->getCurrentFrame();
    }
    return QImage();
}
