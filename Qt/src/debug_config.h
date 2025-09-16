#ifndef DEBUG_CONFIG_H
#define DEBUG_CONFIG_H

// Debug configuration for Raspberry Pi optimization
// Set to 0 to disable all debug logs in production

#define ENABLE_DEBUG_LOGS 0
#define ENABLE_CAMERA_DEBUG 0
#define ENABLE_NETWORK_DEBUG 0
#define ENABLE_RECOGNITION_DEBUG 0
#define ENABLE_PERFORMANCE_DEBUG 0

// General debug logs
#if ENABLE_DEBUG_LOGS
    #define RPI_DEBUG(x) do { qDebug() << x; } while(0)
    #define RPI_DEBUG_MSG(msg) do { qDebug() << msg; } while(0)
    #define RPI_DEBUG_VAR(var, value) do { qDebug() << var << ":" << value; } while(0)
#else
    #define RPI_DEBUG(x) 
    #define RPI_DEBUG_MSG(msg)
    #define RPI_DEBUG_VAR(var, value)
#endif

// Camera specific debug
#if ENABLE_CAMERA_DEBUG
    #define CAMERA_DEBUG(x) do { qDebug() << "[CAMERA]" << x; } while(0)
    #define CAMERA_DEBUG_MSG(msg) do { qDebug() << "[CAMERA]" << msg; } while(0)
#else
    #define CAMERA_DEBUG(x)
    #define CAMERA_DEBUG_MSG(msg)
#endif

// Network specific debug
#if ENABLE_NETWORK_DEBUG
    #define NETWORK_DEBUG(x) do { qDebug() << "[NETWORK]" << x; } while(0)
    #define NETWORK_DEBUG_MSG(msg) do { qDebug() << "[NETWORK]" << msg; } while(0)
#else
    #define NETWORK_DEBUG(x)
    #define NETWORK_DEBUG_MSG(msg)
#endif

// Recognition specific debug
#if ENABLE_RECOGNITION_DEBUG
    #define RECOGNITION_DEBUG(x) do { qDebug() << "[RECOGNITION]" << x; } while(0)
    #define RECOGNITION_DEBUG_MSG(msg) do { qDebug() << "[RECOGNITION]" << msg; } while(0)
#else
    #define RECOGNITION_DEBUG(x)
    #define RECOGNITION_DEBUG_MSG(msg)
#endif

// Performance debug
#if ENABLE_PERFORMANCE_DEBUG
    #define PERF_DEBUG(x) do { qDebug() << "[PERF]" << x; } while(0)
    #define PERF_DEBUG_MSG(msg) do { qDebug() << "[PERF]" << msg; } while(0)
#else
    #define PERF_DEBUG(x)
    #define PERF_DEBUG_MSG(msg)
#endif

// Always keep critical error logs
#define RPI_ERROR(x) do { qDebug() << "ERROR:" << x; } while(0)
#define RPI_WARNING(x) do { qDebug() << "WARNING:" << x; } while(0)

// Disable Qt's internal JPEG corruption warnings
#define DISABLE_JPEG_CORRUPTION_LOGS 1

// Legacy macros for backward compatibility
#define RPI_PERF_DEBUG(x) do { PERF_DEBUG(x); } while(0)
#define RPI_PERF_DEBUG_MSG(msg) do { PERF_DEBUG_MSG(msg); } while(0)

#endif // DEBUG_CONFIG_H
