#ifndef RPI_OPTIMIZATION_H
#define RPI_OPTIMIZATION_H

// Raspberry Pi 3B+ Optimization Settings
// This file contains memory and performance optimizations for RPi 3B+ (1GB RAM)

// Camera settings
#define RPI_CAMERA_RESOLUTION "640x480"  // Reduced from default
#define RPI_CAMERA_FRAMERATE 15          // Lower frame rate
#define RPI_JPEG_QUALITY 70              // Reduced from 85

// System monitoring intervals
#define RPI_SYSTEM_MONITOR_INTERVAL 5000     // 5 seconds instead of 2
#define RPI_SYSTEM_INFO_INTERVAL 30000       // 30 seconds instead of 20
#define RPI_WIFI_CHECK_INTERVAL 10000        // 10 seconds instead of 5

// Cache limits
#define RPI_MAX_CACHED_USERS 50             // Limit user cache
#define RPI_MAX_CACHED_LOGS 100             // Limit log cache

// Image processing
#define RPI_MAX_IMAGE_SIZE 1024             // Max image dimension for processing
#define RPI_FACE_FRAME_SIZE 0.78            // Face frame percentage

// Memory management
#define RPI_ENABLE_MEMORY_OPTIMIZATION 1    // Enable memory optimizations
#define RPI_REDUCE_DEBUG_LOGS 1             // Reduce debug logging

#endif // RPI_OPTIMIZATION_H
