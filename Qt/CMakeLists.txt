cmake_minimum_required(VERSION 3.16)

project(pbl5_facelogin VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Qt packages
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Quick)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Quick Sql Network Multimedia)

# Find OpenCV for face recognition (optional for now)
find_package(OpenCV QUIET)

# SQLite3 is included with Qt SQL module
# No need for separate SQLite3 package on Windows

# Include directories
if(OpenCV_FOUND)
    include_directories(${OpenCV_INCLUDE_DIRS})
endif()

set(PROJECT_SOURCES
        main.cpp
        qml.qrc
        src/database/databasemanager.cpp
        src/database/databasemanager.h
        src/services/usermanager.cpp
        src/services/usermanager.h
        src/services/cameramanager.cpp
        src/services/cameramanager.h
        src/services/systemmonitor.cpp
        src/services/systemmonitor.h
        src/services/networkmanager.cpp
        src/services/networkmanager.h
        src/services/facerecognitionservice.cpp
        src/services/facerecognitionservice.h
        src/services/cachemanager.cpp
        src/services/cachemanager.h
        src/bridge/qmlbridge.cpp
        src/bridge/qmlbridge.h
)

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(pbl5_facelogin
        MANUAL_FINALIZATION
        ${PROJECT_SOURCES}
    )
# Define target properties for Android with Qt 6 as:
#    set_property(TARGET pbl5_facelogin APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
#                 ${CMAKE_CURRENT_SOURCE_DIR}/android)
# For more information, see https://doc.qt.io/qt-6/qt-add-executable.html#target-creation
else()
    if(ANDROID)
        add_library(pbl5_facelogin SHARED
            ${PROJECT_SOURCES}
        )
# Define properties for Android with Qt 5 after find_package() calls as:
#    set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")
    else()
        add_executable(pbl5_facelogin
          ${PROJECT_SOURCES}
        )
    endif()
endif()

target_link_libraries(pbl5_facelogin
  PRIVATE Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Quick Qt${QT_VERSION_MAJOR}::Sql Qt${QT_VERSION_MAJOR}::Network Qt${QT_VERSION_MAJOR}::Multimedia
)

if(OpenCV_FOUND)
    target_link_libraries(pbl5_facelogin PRIVATE ${OpenCV_LIBS})
endif()

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
if(${QT_VERSION} VERSION_LESS 6.1.0)
  set(BUNDLE_ID_OPTION MACOSX_BUNDLE_GUI_IDENTIFIER com.example.pbl5_facelogin)
endif()
set_target_properties(pbl5_facelogin PROPERTIES
    ${BUNDLE_ID_OPTION}
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

include(GNUInstallDirs)
install(TARGETS pbl5_facelogin
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})

if(QT_VERSION_MAJOR EQUAL 6)
    qt_import_qml_plugins(pbl5_facelogin)
    qt_finalize_executable(pbl5_facelogin)
endif()
