#!/bin/bash

# Script to disable debug logs for Raspberry Pi optimization
# This script comments out or removes qDebug() statements

echo "Disabling debug logs for RPi optimization..."

# Backup original files
echo "Creating backups..."
cp -r src src_backup_$(date +%Y%m%d_%H%M%S)

# Disable qDebug() statements in C++ files
echo "Disabling qDebug() statements..."

# Comment out qDebug() statements (keep error logs)
find src -name "*.cpp" -exec sed -i 's/qDebug() << "ERROR:/RPI_ERROR(/g' {} \;
find src -name "*.cpp" -exec sed -i 's/qDebug() << "WARNING:/RPI_WARNING(/g' {} \;

# Comment out regular qDebug() statements
find src -name "*.cpp" -exec sed -i 's/^[[:space:]]*qDebug()/\/\/ qDebug()/g' {} \;

# Disable console.log in QML files
echo "Disabling console.log statements..."
find ui -name "*.qml" -exec sed -i 's/^[[:space:]]*console\.log/\/\/ console.log/g' {} \;

echo "Debug logs disabled successfully!"
echo "To re-enable, set ENABLE_DEBUG_LOGS to 1 in src/debug_config.h"
