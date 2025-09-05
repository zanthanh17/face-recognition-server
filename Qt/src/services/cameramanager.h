#ifndef CAMERAMANAGER_H
#define CAMERAMANAGER_H

#include <QObject>
#include <QByteArray>
#include <QString>
#include <QImage>
#include <QCamera>
#include <QMediaCaptureSession>
#include <QImageCapture>
#include <QMediaDevices>

class CameraManager : public QObject
{
    Q_OBJECT

public:
    explicit CameraManager(QObject *parent = nullptr);
    ~CameraManager();

    // Camera operations
    bool startCamera();
    void stopCamera();
    QByteArray captureImage();
    bool isCameraAvailable() const;
    bool isCameraRunning() const;
    bool isImageCaptureReady() const;

signals:
    void cameraStarted();
    void cameraStopped();
    void cameraError(const QString &error);

private slots:
    void onImageCaptured(int id, const QImage &image);
    void onImageCaptureError(int id, QImageCapture::Error error, const QString &errorString);

private:
    bool m_cameraAvailable;
    bool m_cameraRunning;
    QCamera *m_camera;
    QMediaCaptureSession *m_captureSession;
    QImageCapture *m_imageCapture;
    QByteArray m_lastCapturedImage;
    bool m_captureInProgress;
};

#endif // CAMERAMANAGER_H
