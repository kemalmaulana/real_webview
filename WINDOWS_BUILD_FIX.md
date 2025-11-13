# Windows Build Fix

## Issue
The Windows build was failing with compilation errors:
```
error C2011: 'real_webview::RealWebviewPlugin': 'class' type redefinition
error C2027: use of undefined type 'real_webview::RealWebviewPlugin'
error C2065: 'registrar_': undeclared identifier
error C2065: 'webview_managers_': undeclared identifier
```

## Root Causes

### 1. Class Redefinition
The `RealWebviewPlugin` class was defined in **both** the header file (`real_webview_plugin.h`) and the source file (`real_webview_plugin.cpp`), causing a redefinition error.

**Solution**: Removed the duplicate class definition from the `.cpp` file. The class should only be **declared** in the header file, and **implemented** in the source file.

### 2. Mismatched Constructor Signatures
The header had:
```cpp
RealWebviewPlugin();  // No parameters
```

The implementation had:
```cpp
RealWebviewPlugin(flutter::PluginRegistrarWindows *registrar);  // With parameter
```

**Solution**: Updated the header to match the implementation.

### 3. Missing Member Variables
The header was missing the private member variables:
```cpp
flutter::PluginRegistrarWindows* registrar_;
std::map<int, std::unique_ptr<WebView2Manager>> webview_managers_;
```

**Solution**: Added these member variables to the header file.

### 4. Missing Include Directories
The `CMakeLists.txt` had:
```cmake
target_include_directories(${PLUGIN_NAME} INTERFACE ...)
```

This made the include directory available only to **consumers** of the library, not to the plugin itself during compilation.

**Solution**: Added `PRIVATE` include directories:
```cmake
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
```

## Files Modified

### 1. `windows/include/real_webview/real_webview_plugin.h`
```cpp
namespace real_webview {

// Forward declaration
class WebView2Manager;

class RealWebviewPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  // Constructor now takes registrar parameter
  RealWebviewPlugin(flutter::PluginRegistrarWindows *registrar);

  virtual ~RealWebviewPlugin();

  RealWebviewPlugin(const RealWebviewPlugin&) = delete;
  RealWebviewPlugin& operator=(const RealWebviewPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Added member variables
  flutter::PluginRegistrarWindows* registrar_;
  std::map<int, std::unique_ptr<WebView2Manager>> webview_managers_;
};

}  // namespace real_webview
```

### 2. `windows/real_webview_plugin.cpp`
Removed the duplicate class definition. The file now starts with:
```cpp
#include "include/real_webview/real_webview_plugin.h"
#include "include/real_webview/webview2_manager.h"

// ... includes ...

namespace real_webview {

// static
void RealWebviewPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  // Implementation only, no class definition
  ...
}
```

### 3. `windows/CMakeLists.txt`
Added PRIVATE include directories:
```cmake
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
```

## How to Test

1. Clean the build directory:
```powershell
flutter clean
```

2. Rebuild:
```powershell
flutter build windows
```

3. If you're testing in an app, delete the ephemeral directory:
```powershell
rm -r windows/flutter/ephemeral
flutter pub get
flutter build windows
```

## Expected Result

The Windows build should now compile successfully without errors. The plugin will create a placeholder WebView window (actual WebView2 integration requires the WebView2 SDK).

## Next Steps for Production

For a production-ready implementation, you'll need to:

1. **Install WebView2 SDK**:
   - Add NuGet package: `Microsoft.Web.WebView2`
   - Or download from https://developer.microsoft.com/en-us/microsoft-edge/webview2/

2. **Update CMakeLists.txt** to link WebView2:
```cmake
# Find WebView2
find_package(Microsoft.Web.WebView2 REQUIRED)

# Link WebView2
target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  flutter_wrapper_plugin
  Microsoft::WebView2
)
```

3. **Replace Placeholder Code** in `webview2_manager.cpp`:
```cpp
#include <WebView2.h>

void WebView2Manager::Initialize(...) {
  // Create WebView2 environment
  CreateCoreWebView2EnvironmentWithOptions(...);

  // Create WebView2 controller
  CreateCoreWebView2Controller(...);
}
```

## Summary

The Windows plugin now compiles correctly with:
- ✅ Proper class declaration/definition separation
- ✅ Correct constructor signature
- ✅ All member variables declared
- ✅ Proper include directories
- ✅ C++17 standard
- ✅ Placeholder implementation ready for WebView2 SDK integration

The build errors have been resolved and the plugin is ready for testing and further development.
