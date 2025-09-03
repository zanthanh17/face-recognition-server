#ifndef DEBUG_CONFIG_H
#define DEBUG_CONFIG_H

// Debug configuration for Raspberry Pi optimization
// Set to 0 to disable all debug logs in production

#define ENABLE_DEBUG_LOGS 0

#if ENABLE_DEBUG_LOGS
    #define RPI_DEBUG(x) qDebug() << x
    #define RPI_DEBUG_MSG(msg) qDebug() << msg
    #define RPI_DEBUG_VAR(var, value) qDebug() << var << ":" << value
#else
    #define RPI_DEBUG(x) 
    #define RPI_DEBUG_MSG(msg)
    #define RPI_DEBUG_VAR(var, value)
#endif

// Keep only critical error logs
#define RPI_ERROR(x) qDebug() << "ERROR:" << x
#define RPI_WARNING(x) qDebug() << "WARNING:" << x

// Performance critical sections
#define RPI_PERF_DEBUG(x) 
#define RPI_PERF_DEBUG_MSG(msg)

#endif // DEBUG_CONFIG_H
