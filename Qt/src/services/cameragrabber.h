#ifndef CAMERAGRABBER_H
#define CAMERAGRABBER_H

#include <QObject>
#include <QTimer>
#include <QImage>
#include <QThread>
#include <opencv2/opencv.hpp>
#include <atomic>

class FrameProvider;

class CameraGrabber : public QObject {
    Q_OBJECT
public:
    explicit CameraGrabber(FrameProvider* provider, QObject* parent = nullptr);
    ~CameraGrabber();
    
    Q_INVOKABLE void start(int fps = 30);
    Q_INVOKABLE void stop();
    Q_INVOKABLE bool isRunning() const { return m_isRunning; }
    
    // Get current frame for face recognition
    Q_INVOKABLE QImage captureCurrentFrame();
    
signals:
    void frameReady();
    void cameraError(const QString& error);
    void cameraStarted();
    void cameraStopped();
    
private slots:
    void grabFrame();
    
private:
    FrameProvider* m_provider;
    QTimer* m_timer;
    cv::VideoCapture* m_capture;
    std::atomic<bool> m_isRunning{false};
    
    // Initialize camera with GStreamer pipeline
    bool initializeCamera();
    QString getGStreamerPipeline();
};

#endif // CAMERAGRABBER_H
