#!/bin/bash

# Fix Qt Quick imports for Qt6
echo "Fixing Qt Quick imports for Qt6..."

# Find all QML files and replace imports
find . -name "*.qml" -type f -exec sed -i 's/import QtQuick 2\.15/import QtQuick/g' {} \;
find . -name "*.qml" -type f -exec sed -i 's/import QtQuick\.Window 2\.15/import QtQuick.Window/g' {} \;
find . -name "*.qml" -type f -exec sed -i 's/import QtQuick\.Controls 2\.15/import QtQuick.Controls/g' {} \;
find . -name "*.qml" -type f -exec sed -i 's/import QtQuick\.Layouts 1\.15/import QtQuick.Layouts/g' {} \;
find . -name "*.qml" -type f -exec sed -i 's/import QtQuick\.Dialogs 2\.15/import QtQuick.Dialogs/g' {} \;
find . -name "*.qml" -type f -exec sed -i 's/import QtQuick\.Multimedia 2\.15/import QtQuick.Multimedia/g' {} \;

echo "Qt Quick imports fixed for Qt6!"


