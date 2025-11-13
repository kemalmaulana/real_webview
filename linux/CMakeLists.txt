cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "real_webview")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "real_webview_plugin")

# Find WebKitGTK
find_package(PkgConfig REQUIRED)
pkg_check_modules(WEBKIT REQUIRED IMPORTED_TARGET webkit2gtk-4.0)

add_library(${PLUGIN_NAME} SHARED
  "real_webview_plugin.cc"
  "webkit_manager.cc"
  "platform_view_factory.cc"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden
  CXX_STANDARD 17
)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::WEBKIT)

set(real_webview_bundled_libraries
  ""
  PARENT_SCOPE
)
