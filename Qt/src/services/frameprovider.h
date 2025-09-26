#ifndef FRAMEPROVIDER_H
#define FRAMEPROVIDER_H

#include <QQuickImageProvider>
#include <QImage>
#include <QMutex>
#include <QMutexLocker>

class FrameProvider : public QQuickImageProvider {
public:
    FrameProvider() : QQuickImageProvider(QQuickImageProvider::Image) {}

    // QML calls this to get current image
    QImage requestImage(const QString&, QSize* size, const QSize& requestedSize) override {
        QMutexLocker lk(&m_mutex);
        QImage out = m_currentFrame.isNull() ? QImage(640, 480, QImage::Format_RGB888) : m_currentFrame;
        if (size) *size = out.size();
        if (requestedSize.isValid() && requestedSize != out.size()) {
            return out.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        }
        return out.copy(); // return safe copy
    }

    // C++ pushes new frame to provider
    void setFrame(const QImage& frame) {
        QMutexLocker lk(&m_mutex);
        m_currentFrame = frame;
    }

    // Get current frame (for capture)
    QImage getCurrentFrame() {
        QMutexLocker lk(&m_mutex);
        return m_currentFrame.copy();
    }

private:
    QImage m_currentFrame;
    QMutex m_mutex;
};

#endif // FRAMEPROVIDER_H
