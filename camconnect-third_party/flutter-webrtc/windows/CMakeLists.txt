cmake_minimum_required(VERSION 3.15)
set(PROJECT_NAME "flutter_webrtc")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "flutter_webrtc_plugin")

add_definitions(-DLIB_WEBRTC_API_DLL)
add_definitions(-DRTC_DESKTOP_DEVICE)

add_library(${PLUGIN_NAME} SHARED
  "../common/cpp/flutter_webrtc_plugin.cc"
  "../common/cpp/src/flutter_common.cc"
  "../common/cpp/src/flutter_data_channel.cc"
  "../common/cpp/src/flutter_frame_cryptor.cc"
  "../common/cpp/src/flutter_media_stream.cc"
  "../common/cpp/src/flutter_peerconnection.cc"
  "../common/cpp/src/flutter_frame_capturer.cc"
  "../common/cpp/src/flutter_video_renderer.cc"
  "../common/cpp/src/flutter_screen_capture.cc"
  "../common/cpp/src/flutter_webrtc.cc"
  "../common/cpp/src/flutter_webrtc_base.cc"
  "../common/cpp/src/driver_interface_video_proc_thread.cc"
  "../third_party/uuidxx/uuidxx.cc"
)

include_directories(
  "${CMAKE_CURRENT_SOURCE_DIR}/../common/cpp/include"
  "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/uuidxx"
  "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/svpng"
  "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libwebrtc/include"
  "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/driver_interface/include"
)

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/../common/cpp/include"
)
target_link_libraries(${PLUGIN_NAME} PRIVATE 
  flutter
  flutter_wrapper_plugin
  "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libwebrtc/lib/win64/libwebrtc.dll.lib"
)

# List of absolute paths to libraries that should be bundled with the plugin
set(flutter_webrtc_bundled_libraries
  "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libwebrtc/lib/win64/libwebrtc.dll"
  PARENT_SCOPE
)

# ===================== Link driver-interface library ===================== #

set(DRIVER_INTERFACE_DEBUG_LIB_FILE 
  "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/driver_interface/lib/win64/Debug/DriverInterface.lib"
)
set(DRIVER_INTERFACE_RELEASE_LIB_FILE 
  "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/driver_interface/lib/win64/Release/DriverInterface.lib"
)
target_link_libraries(${PLUGIN_NAME} PRIVATE
  $<$<CONFIG:Debug>:${DRIVER_INTERFACE_DEBUG_LIB_FILE}>
  $<$<CONFIG:Profile>:${DRIVER_INTERFACE_RELEASE_LIB_FILE}>
  $<$<CONFIG:Release>:${DRIVER_INTERFACE_RELEASE_LIB_FILE}>
)

# Ignore linker warning: 4099 for debug configuration mode
target_link_options(${PLUGIN_NAME} PRIVATE $<$<CONFIG:Debug>:/ignore:4099>)