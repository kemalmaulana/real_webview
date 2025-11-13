cmake_minimum_required(VERSION 3.15)
set(PROJECT_NAME "real_webview")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "real_webview_plugin")

add_library(${PLUGIN_NAME} SHARED
  "real_webview_plugin.cpp"
  "webview2_manager.cpp"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden
  CXX_STANDARD 17
)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin
set(real_webview_bundled_libraries
  ""
  PARENT_SCOPE
)
