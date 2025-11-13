# Native Implementation Guide - Using Existing References

Based on research into Brave Browser (Chromium-based) and existing Flutter WebView implementations, here's a comprehensive guide for implementing the native layer on desktop platforms.

## 🎯 Reference Implementations

### Available Open-Source References

| Platform | Reference Project | Engine | License | Status |
|----------|------------------|--------|---------|---------|
| **Windows** | [flutter-webview-windows](https://github.com/jnschulze/flutter-webview-windows) | WebView2 | MIT | Production |
| **macOS** | Flutter's iOS WebView | WKWebView | BSD | Adaptable |
| **Linux** | [flutter_linux_webview](https://pub.dev/packages/flutter_linux_webview) | WebKitGTK | MIT | Beta |
| **All** | [Brave Browser](https://github.com/brave/brave-browser) | Chromium | MPL-2.0 | Reference |

---

## Windows Implementation (WebView2)

### 1. Reference Implementation

**Primary Reference**: [flutter-webview-windows](https://github.com/jnschulze/flutter-webview-windows)
- 73% C++ - Core WebView2 integration
- 19.6% Dart - Platform channel bindings
- 6.4% CMake - Build configuration
- MIT License (Can be used as reference)

### 2. Key Files Structure

```
windows/
├── CMakeLists.txt                      # Build configuration
├── include/real_webview/
│   ├── real_webview_plugin.h          # Plugin header (✅ already created)
│   ├── webview2_manager.h             # WebView2 management (to create)
│   └── graphics_capture.h             # Screen capture helper (to create)
├── real_webview_plugin.cpp            # Plugin implementation (✅ basic structure)
├── webview2_manager.cpp               # WebView2 core logic (to create)
└── graphics_capture.cpp               # Rendering helper (to create)
```

### 3. Implementation Steps

#### Step 1: Add WebView2 SDK

**Update `CMakeLists.txt`:**
```cmake
cmake_minimum_required(VERSION 3.15)
set(PROJECT_NAME "real_webview")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "real_webview_plugin")

# Add WebView2 SDK
find_package(WebView2 REQUIRED)
find_package(WindowsAppSDK REQUIRED)

add_library(${PLUGIN_NAME} SHARED
  "real_webview_plugin.cpp"
  "webview2_manager.cpp"
  "graphics_capture.cpp"
)

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden
  CXX_STANDARD 17
)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

# Link WebView2
target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  flutter_wrapper_plugin
  WebView2::WebView2
  WindowsApp::WindowsApp
)

set(real_webview_bundled_libraries
  ""
  PARENT_SCOPE
)
```

#### Step 2: Core WebView2 Manager

**Create `webview2_manager.h`:**
```cpp
#ifndef WEBVIEW2_MANAGER_H_
#define WEBVIEW2_MANAGER_H_

#include <WebView2.h>
#include <wil/com.h>
#include <flutter/method_channel.h>
#include <memory>
#include <functional>

class WebView2Manager {
public:
    WebView2Manager(flutter::MethodChannel<flutter::EncodableValue>* channel);
    ~WebView2Manager();

    // Initialize WebView2 environment
    HRESULT Initialize(HWND parent_window);

    // Navigation
    void LoadUrl(const std::string& url);
    void Reload();
    void GoBack();
    void GoForward();

    // JavaScript
    void EvaluateJavascript(const std::string& script,
                           std::function<void(std::string)> callback);
    void AddUserScript(const std::string& script, bool at_start);

    // Settings
    void SetSettings(const flutter::EncodableMap& settings);

    // Events
    void SetupEventHandlers();

private:
    wil::com_ptr<ICoreWebView2Environment> environment_;
    wil::com_ptr<ICoreWebView2Controller> controller_;
    wil::com_ptr<ICoreWebView2> webview_;
    flutter::MethodChannel<flutter::EncodableValue>* channel_;
    HWND parent_window_;

    // Event tokens for cleanup
    EventRegistrationToken navigation_starting_token_;
    EventRegistrationToken navigation_completed_token_;
    EventRegistrationToken source_changed_token_;
};

#endif  // WEBVIEW2_MANAGER_H_
```

**Implement `webview2_manager.cpp`:**
```cpp
#include "webview2_manager.h"
#include <flutter/standard_method_codec.h>

WebView2Manager::WebView2Manager(
    flutter::MethodChannel<flutter::EncodableValue>* channel)
    : channel_(channel), parent_window_(nullptr) {}

WebView2Manager::~WebView2Manager() {
    // Cleanup event handlers
    if (webview_) {
        webview_->remove_NavigationStarting(navigation_starting_token_);
        webview_->remove_NavigationCompleted(navigation_completed_token_);
        webview_->remove_SourceChanged(source_changed_token_);
    }
}

HRESULT WebView2Manager::Initialize(HWND parent_window) {
    parent_window_ = parent_window;

    // Create WebView2 environment
    return CreateCoreWebView2EnvironmentWithOptions(
        nullptr, nullptr, nullptr,
        Callback<ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler>(
            [this](HRESULT result, ICoreWebView2Environment* env) -> HRESULT {
                if (FAILED(result)) return result;

                environment_ = env;

                // Create WebView2 controller
                return environment_->CreateCoreWebView2Controller(
                    parent_window_,
                    Callback<ICoreWebView2CreateCoreWebView2ControllerCompletedHandler>(
                        [this](HRESULT result,
                               ICoreWebView2Controller* controller) -> HRESULT {
                            if (FAILED(result)) return result;

                            controller_ = controller;
                            controller_->get_CoreWebView2(&webview_);

                            // Set up bounds
                            RECT bounds;
                            GetClientRect(parent_window_, &bounds);
                            controller_->put_Bounds(bounds);

                            // Setup event handlers
                            SetupEventHandlers();

                            return S_OK;
                        }).Get());
            }).Get());
}

void WebView2Manager::LoadUrl(const std::string& url) {
    if (webview_) {
        std::wstring wide_url(url.begin(), url.end());
        webview_->Navigate(wide_url.c_str());
    }
}

void WebView2Manager::Reload() {
    if (webview_) {
        webview_->Reload();
    }
}

void WebView2Manager::GoBack() {
    if (webview_) {
        BOOL can_go_back;
        webview_->get_CanGoBack(&can_go_back);
        if (can_go_back) {
            webview_->GoBack();
        }
    }
}

void WebView2Manager::GoForward() {
    if (webview_) {
        BOOL can_go_forward;
        webview_->get_CanGoForward(&can_go_forward);
        if (can_go_forward) {
            webview_->GoForward();
        }
    }
}

void WebView2Manager::EvaluateJavascript(
    const std::string& script,
    std::function<void(std::string)> callback) {
    if (webview_) {
        std::wstring wide_script(script.begin(), script.end());
        webview_->ExecuteScript(
            wide_script.c_str(),
            Callback<ICoreWebView2ExecuteScriptCompletedHandler>(
                [callback](HRESULT errorCode, LPCWSTR resultObjectAsJson) -> HRESULT {
                    if (callback && resultObjectAsJson) {
                        std::wstring wide_result(resultObjectAsJson);
                        std::string result(wide_result.begin(), wide_result.end());
                        callback(result);
                    }
                    return S_OK;
                }).Get());
    }
}

void WebView2Manager::AddUserScript(const std::string& script, bool at_start) {
    if (webview_) {
        std::wstring wide_script(script.begin(), script.end());
        webview_->AddScriptToExecuteOnDocumentCreated(
            wide_script.c_str(),
            Callback<ICoreWebView2AddScriptToExecuteOnDocumentCreatedCompletedHandler>(
                [](HRESULT errorCode, LPCWSTR id) -> HRESULT {
                    return S_OK;
                }).Get());
    }
}

void WebView2Manager::SetupEventHandlers() {
    if (!webview_) return;

    // Navigation starting
    webview_->add_NavigationStarting(
        Callback<ICoreWebView2NavigationStartingEventHandler>(
            [this](ICoreWebView2* sender,
                   ICoreWebView2NavigationStartingEventArgs* args) -> HRESULT {
                LPWSTR uri;
                args->get_Uri(&uri);

                std::wstring wide_uri(uri);
                std::string url(wide_uri.begin(), wide_uri.end());

                // Send to Flutter
                flutter::EncodableMap event_data;
                event_data[flutter::EncodableValue("url")] =
                    flutter::EncodableValue(url);

                channel_->InvokeMethod("onLoadStart",
                    std::make_unique<flutter::EncodableValue>(event_data));

                CoTaskMemFree(uri);
                return S_OK;
            }).Get(),
        &navigation_starting_token_);

    // Navigation completed
    webview_->add_NavigationCompleted(
        Callback<ICoreWebView2NavigationCompletedEventHandler>(
            [this](ICoreWebView2* sender,
                   ICoreWebView2NavigationCompletedEventArgs* args) -> HRESULT {
                BOOL success;
                args->get_IsSuccess(&success);

                if (success) {
                    LPWSTR uri;
                    sender->get_Source(&uri);

                    std::wstring wide_uri(uri);
                    std::string url(wide_uri.begin(), wide_uri.end());

                    // Send to Flutter
                    flutter::EncodableMap event_data;
                    event_data[flutter::EncodableValue("url")] =
                        flutter::EncodableValue(url);

                    channel_->InvokeMethod("onLoadStop",
                        std::make_unique<flutter::EncodableValue>(event_data));

                    CoTaskMemFree(uri);
                }
                return S_OK;
            }).Get(),
        &navigation_completed_token_);
}

void WebView2Manager::SetSettings(const flutter::EncodableMap& settings) {
    if (!webview_) return;

    wil::com_ptr<ICoreWebView2Settings> web_settings;
    webview_->get_Settings(&web_settings);

    // JavaScript
    auto js_it = settings.find(flutter::EncodableValue("javaScriptEnabled"));
    if (js_it != settings.end()) {
        bool enabled = std::get<bool>(js_it->second);
        web_settings->put_IsScriptEnabled(enabled ? TRUE : FALSE);
    }

    // User agent
    auto ua_it = settings.find(flutter::EncodableValue("userAgent"));
    if (ua_it != settings.end()) {
        wil::com_ptr<ICoreWebView2Settings2> settings2;
        web_settings->QueryInterface(IID_PPV_ARGS(&settings2));
        if (settings2) {
            std::string ua = std::get<std::string>(ua_it->second);
            std::wstring wide_ua(ua.begin(), ua.end());
            settings2->put_UserAgent(wide_ua.c_str());
        }
    }
}
```

#### Step 3: Update Plugin Implementation

**Update `real_webview_plugin.cpp`:**
```cpp
#include "include/real_webview/real_webview_plugin.h"
#include "webview2_manager.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <map>

namespace real_webview {

class RealWebviewPlugin : public flutter::Plugin {
public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

    RealWebviewPlugin(flutter::PluginRegistrarWindows *registrar);
    virtual ~RealWebviewPlugin();

private:
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    flutter::PluginRegistrarWindows* registrar_;
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
    std::map<int64_t, std::unique_ptr<WebView2Manager>> webviews_;
};

void RealWebviewPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "real_webview",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<RealWebviewPlugin>(registrar);

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
}

RealWebviewPlugin::RealWebviewPlugin(flutter::PluginRegistrarWindows *registrar)
    : registrar_(registrar) {}

RealWebviewPlugin::~RealWebviewPlugin() {}

void RealWebviewPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());

    if (method_call.method_name() == "create") {
        // Create new WebView instance
        if (arguments) {
            auto view_id_it = arguments->find(flutter::EncodableValue("viewId"));
            if (view_id_it != arguments->end()) {
                int64_t view_id = std::get<int64_t>(view_id_it->second);

                // Create method channel for this WebView
                std::string channel_name = "real_webview_" + std::to_string(view_id);
                auto webview_channel = std::make_unique<flutter::MethodChannel<>>(
                    registrar_->messenger(), channel_name,
                    &flutter::StandardMethodCodec::GetInstance());

                // Create WebView manager
                auto manager = std::make_unique<WebView2Manager>(webview_channel.get());

                // Get parent HWND (Flutter window)
                HWND hwnd = registrar_->GetView()->GetNativeWindow();

                HRESULT hr = manager->Initialize(hwnd);
                if (SUCCEEDED(hr)) {
                    webviews_[view_id] = std::move(manager);
                    result->Success(flutter::EncodableValue(true));
                } else {
                    result->Error("INIT_ERROR", "Failed to initialize WebView2");
                }
                return;
            }
        }
        result->Error("INVALID_ARGS", "Invalid arguments");

    } else if (method_call.method_name() == "loadUrl") {
        // Handle loadUrl, reload, etc.
        // Implementation similar to create...
        result->Success();

    } else {
        result->NotImplemented();
    }
}

}  // namespace real_webview
```

### 4. Installation & Testing

```bash
# Install WebView2 SDK
# Download from https://developer.microsoft.com/en-us/microsoft-edge/webview2/

# Build
flutter build windows

# Test
flutter run -d windows
```

---

## macOS Implementation (WKWebView)

### 1. Reference Implementation

**Primary Reference**: Reuse existing iOS implementation (`ios/Classes/`)
- 90% code compatible with macOS
- Only need to change UIKit → AppKit imports

### 2. Quick Implementation

**Step 1: Copy iOS Code**
```bash
# Copy iOS implementation
cp -r ios/Classes/* macos/Classes/

# Update imports in all files
find macos/Classes -name "*.swift" -exec sed -i '' 's/import UIKit/import AppKit/g' {} \;
```

**Step 2: Update Plugin Registration**

**Create `macos/Classes/RealWebviewPlugin.swift`:**
```swift
import FlutterMacOS
import WebKit

public class RealWebviewPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "real_webview",
            binaryMessenger: registrar.messenger
        )
        let instance = RealWebviewPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Register platform view factory
        let factory = RealWebViewFactory(messenger: registrar.messenger)
        registrar.register(factory, withId: "real_webview")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
```

**Step 3: Platform View Factory**

```swift
class RealWebViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return RealWebView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            messenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
```

---

## Linux Implementation (WebKitGTK)

### 1. Reference Implementation

**Reference**: [flutter_linux_webview](https://pub.dev/packages/flutter_linux_webview)
- Uses WebKitGTK
- CEF (Chromium Embedded Framework) as alternative

### 2. Implementation Structure

```
linux/
├── CMakeLists.txt                     # ✅ Already created
├── real_webview_plugin.cc             # Core plugin
├── webkit_manager.cc                  # WebKitGTK wrapper
└── include/real_webview/
    ├── real_webview_plugin.h
    └── webkit_manager.h
```

### 3. Implementation

**Update `CMakeLists.txt`:**
```cmake
cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "real_webview")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "real_webview_plugin")

# Find WebKitGTK
find_package(PkgConfig REQUIRED)
pkg_check_modules(WEBKIT REQUIRED webkit2gtk-4.0)

add_library(${PLUGIN_NAME} SHARED
  "real_webview_plugin.cc"
  "webkit_manager.cc"
)

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden
  CXX_STANDARD 14
)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  ${WEBKIT_INCLUDE_DIRS}
)

target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  PkgConfig::GTK
  ${WEBKIT_LIBRARIES}
)

set(real_webview_bundled_libraries "" PARENT_SCOPE)
```

**Create `webkit_manager.h`:**
```cpp
#ifndef WEBKIT_MANAGER_H_
#define WEBKIT_MANAGER_H_

#include <webkit2/webkit2.h>
#include <flutter_linux/flutter_linux.h>

class WebKitManager {
public:
    WebKitManager(FlMethodChannel* channel);
    ~WebKitManager();

    // Initialize WebKitWebView
    GtkWidget* Initialize();

    // Navigation
    void LoadUrl(const char* url);
    void Reload();
    void GoBack();
    void GoForward();

    // JavaScript
    void EvaluateJavascript(const char* script, GAsyncReadyCallback callback);

    // Settings
    void SetSettings(FlValue* settings);

private:
    WebKitWebView* webview_;
    FlMethodChannel* channel_;

    // Signal handlers
    static void OnLoadChanged(WebKitWebView* web_view,
                             WebKitLoadEvent load_event,
                             gpointer user_data);
    static void OnTitleChanged(WebKitWebView* web_view,
                              GParamSpec* pspec,
                              gpointer user_data);
};

#endif  // WEBKIT_MANAGER_H_
```

---

## Summary & Next Steps

### What We Have Now

| Platform | Flutter API | Native Code | Status |
|----------|------------|-------------|---------|
| Android | ✅ Complete | ✅ Complete | Production |
| iOS | ✅ Complete | ✅ Complete | Production |
| Web | ✅ Complete | ✅ Complete | Production |
| Windows | ✅ Complete | 📋 Guide Ready | Needs implementation |
| macOS | ✅ Complete | 📋 Guide Ready | Needs implementation |
| Linux | ✅ Complete | 📋 Guide Ready | Needs implementation |

### Implementation Time Estimates

- **Windows**: 2-3 days (WebView2 C++ code)
- **macOS**: 1 day (copy iOS, change UIKit→AppKit)
- **Linux**: 2-3 days (WebKitGTK C++ code)

### Reference Resources

**Windows:**
- [flutter-webview-windows](https://github.com/jnschulze/flutter-webview-windows) - Complete reference
- [Microsoft WebView2 Docs](https://learn.microsoft.com/en-us/microsoft-edge/webview2/)
- [WebView2 Samples](https://github.com/MicrosoftEdge/WebView2Samples)

**macOS:**
- iOS implementation (already have)
- [WKWebView Documentation](https://developer.apple.com/documentation/webkit/wkwebview)

**Linux:**
- [flutter_linux_webview](https://pub.dev/packages/flutter_linux_webview)
- [WebKitGTK Documentation](https://webkitgtk.org/reference/webkit2gtk/stable/)

**General:**
- [Brave Browser](https://github.com/brave/brave-browser) - Architecture patterns
- [webview/webview](https://github.com/webview/webview) - Cross-platform C/C++ library

---

## Contributing

Want to help implement desktop support?

1. Choose a platform (Windows recommended first)
2. Follow this guide to implement native code
3. Test with the example app
4. Submit a PR!

Each platform can be implemented independently. The Flutter/Dart API is already complete and consistent across all platforms!
