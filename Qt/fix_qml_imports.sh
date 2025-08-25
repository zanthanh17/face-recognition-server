#!/bin/bash

echo "🔧 Fixing QML import statements..."

# Function to fix imports in a file
fix_imports() {
    local file="$1"
    echo "  Fixing: $file"
    
    # Create backup
    cp "$file" "$file.bak"
    
    # Fix QtQuick imports
    sed -i 's/^import QtQuick$/import QtQuick 2.15/' "$file"
    sed -i 's/^import QtQuick.Controls$/import QtQuick.Controls 2.15/' "$file"
    sed -i 's/^import QtQuick.Layouts$/import QtQuick.Layouts 1.15/' "$file"
    sed -i 's/^import QtMultimedia$/import QtMultimedia 6.0/' "$file"
    sed -i 's/^import QtQuick.Window$/import QtQuick.Window 2.15/' "$file"
    sed -i 's/^import QtQuick.Dialogs$/import QtQuick.Dialogs 2.15/' "$file"
}

# Find all QML files and fix them
find ui/ -name "*.qml" -type f | while read -r file; do
    fix_imports "$file"
done

echo "✅ QML imports fixed!"
echo "🔄 Rebuilding application..."

# Rebuild the application
./build.sh

echo "🎉 Done! Try running the application again."


