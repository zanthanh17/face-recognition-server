cmake_minimum_required(VERSION 3.16)

project(pbl5_facelogin VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Qt packages
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core Quick)
set(QT_VERSION_MAJOR 6)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Quick Sql Network Multimedia)

# Find OpenCV for face recognition (required now)
find_package(OpenCV REQUIRED)

# Find GStreamer for Raspberry Pi camera support
find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
    pkg_check_modules(GSTREAMER QUIET gstreamer-1.0)
    pkg_check_modules(GSTREAMER_VIDEO QUIET gstreamer-video-1.0)
    pkg_check_modules(GSTREAMER_APP QUIET gstreamer-app-1.0)
endif()

# Raspberry Pi optimizations
if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm.*" OR CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
    message(STATUS "Building for Raspberry Pi")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2 -DNDEBUG")
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=armv8-a -mtune=cortex-a72")
    endif()
endif()

# Include directories
if(OpenCV_FOUND)
    include_directories(${OpenCV_INCLUDE_DIRS})
endif()

# Include GStreamer directories
if(GSTREAMER_FOUND)
    include_directories(${GSTREAMER_INCLUDE_DIRS})
    include_directories(${GSTREAMER_VIDEO_INCLUDE_DIRS})
    include_directories(${GSTREAMER_APP_INCLUDE_DIRS})
    message(STATUS "GStreamer found - enabling camera support")
else()
    message(STATUS "GStreamer not found - camera support may be limited")
endif()

# Add source directory to include path
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)

set(PROJECT_SOURCES
        main.cpp
        qml.qrc
        src/services/cameramanager.cpp
        src/services/cameramanager.h
        src/services/cameragrabber.cpp
        src/services/cameragrabber.h
        src/services/frameprovider.h
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
        src/qt_logging_config.h
)

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(pbl5_facelogin
        MANUAL_FINALIZATION
        ${PROJECT_SOURCES}
    )
# Android configuration (if needed)
else()
    if(ANDROID)
        add_library(pbl5_facelogin SHARED
            ${PROJECT_SOURCES}
        )
# Android properties for Qt 5
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

# Link GStreamer libraries for Raspberry Pi camera support
if(GSTREAMER_FOUND)
    target_link_libraries(pbl5_facelogin PRIVATE ${GSTREAMER_LIBRARIES})
    target_link_libraries(pbl5_facelogin PRIVATE ${GSTREAMER_VIDEO_LIBRARIES})
    target_link_libraries(pbl5_facelogin PRIVATE ${GSTREAMER_APP_LIBRARIES})
    target_compile_options(pbl5_facelogin PRIVATE ${GSTREAMER_CFLAGS_OTHER})
    target_compile_options(pbl5_facelogin PRIVATE ${GSTREAMER_VIDEO_CFLAGS_OTHER})
    target_compile_options(pbl5_facelogin PRIVATE ${GSTREAMER_APP_CFLAGS_OTHER})
endif()

# macOS bundle configuration
if(${QT_VERSION_MAJOR} LESS 6)
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
