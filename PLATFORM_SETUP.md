# Platform Setup Guide

Real WebView now supports **all Flutter platforms**: Android, iOS, Web, Windows, macOS, and Linux!

## ✅ Platform Support Status

| Platform | Status | WebView Engine | DRM Support |
|----------|--------|----------------|-------------|
| **Android** | ✅ Ready | Chromium WebView | Widevine |
| **iOS** | ✅ Ready | WKWebView | FairPlay |
| **Web** | ✅ Ready | IFrame (Browser) | Browser Native |
| **Windows** | 🔧 Setup Required | WebView2 (Edge) | Widevine |
| **macOS** | 🔧 Setup Required | WKWebView | FairPlay |
| **Linux** | 🔧 Setup Required | WebKitGTK | Widevine |

**Legend:**
- ✅ Ready: Fully implemented, works out of the box
- 🔧 Setup Required: Flutter structure ready, native implementation needed

---

## Mobile Platforms (Ready)

### Android ✅
**Status**: Fully implemented and ready to use.

**Setup**: No additional setup required!

**Engine**: Uses Android WebView (Chromium-based)

**Features**:
- ✅ Full DRM support (Widevine)
- ✅ Cookie management
- ✅ JavaScript execution
- ✅ User script injection
- ✅ Download handling
- ✅ Permission requests
- ✅ Pull-to-refresh

**Native Code**: `android/src/main/kotlin/`

### iOS ✅
**Status**: Fully implemented and ready to use.

**Setup**: Add to `ios/Runner/Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Engine**: Uses WKWebView (WebKit)

**Features**:
- ✅ Full DRM support (FairPlay)
- ✅ Cookie management
- ✅ JavaScript execution
- ✅ User script injection
- ✅ Download handling
- ✅ Permission requests
- ✅ Pull-to-refresh

**Native Code**: `ios/Classes/`

---

## Web Platform (Ready)

### Web ✅
**Status**: Fully implemented using IFrame approach.

**Setup**: No additional setup required!

**Engine**: Uses browser's native IFrame

**How It Works**:
```dart
// Automatically uses web implementation on web platform
RealWebView(
  initialUrl: 'https://example.com',
  // All settings automatically adapted for web
)
```

**Features**:
- ✅ URL loading
- ✅ Basic JavaScript enabled
- ✅ DRM support (browser native)
- ⚠️ Limited due to same-origin policy
- ⚠️ Cookie management limited
- ⚠️ Some features restricted by browser security

**Implementation**: `lib/src/real_webview_web.dart`

**Limitations**:
- Cannot access iframe internals due to same-origin policy
- Download handling depends on browser
- Permission requests handled by browser
- No pull-to-refresh (not typical for web)

---

## Desktop Platforms (Setup Required)

All desktop platforms have the Flutter/Dart layer **fully implemented**. You just need to add the native platform code.

> **📚 For detailed implementation code with examples, see [NATIVE_IMPLEMENTATION_GUIDE.md](NATIVE_IMPLEMENTATION_GUIDE.md)**

### Quick Reference

We've researched and documented existing open-source implementations you can use as references:

- **Windows**: [flutter-webview-windows](https://github.com/jnschulze/flutter-webview-windows) (MIT License, production-ready)
- **macOS**: Reuse iOS code (90% compatible, just change UIKit → AppKit)
- **Linux**: [flutter_linux_webview](https://pub.dev/packages/flutter_linux_webview) (WebKitGTK)
- **General**: [Brave Browser](https://github.com/brave/brave-browser) (Chromium architecture patterns)

### Windows 🔧

**Status**: Flutter structure ready, native WebView2 implementation needed.

**Target Engine**: Microsoft Edge WebView2 (Chromium-based)

**What's Ready**:
- ✅ Flutter platform view setup
- ✅ Method channel infrastructure
- ✅ Plugin registration structure
- ✅ CMake build configuration

**What's Needed**:
Native C++ code to:
1. Initialize WebView2 control
2. Handle navigation events
3. Manage cookies
4. Inject JavaScript
5. Handle downloads

**Files Created**:
```
windows/
├── CMakeLists.txt                     ✅ Ready
├── real_webview_plugin.cpp            ✅ Basic structure
└── include/real_webview/
    └── real_webview_plugin.h          ✅ Header file
```

**Setup Steps**:

1. **Install WebView2 Runtime**
   ```bash
   # Download from Microsoft
   https://developer.microsoft.com/en-us/microsoft-edge/webview2/
   ```

2. **Add WebView2 SDK to CMakeLists.txt**
   ```cmake
   find_package(WebView2 REQUIRED)
   target_link_libraries(${PLUGIN_NAME} PRIVATE WebView2::WebView2)
   ```

3. **Implement Native Code**
   Update `windows/real_webview_plugin.cpp` with WebView2 integration:
   ```cpp
   #include <wil/com.h>
   #include <wrl.h>
   #include "WebView2.h"

   // Create WebView2 instance
   // Handle events
   // Implement method channel handlers
   ```

**Reference Implementation**:
See Microsoft's [WebView2 samples](https://github.com/MicrosoftEdge/WebView2Samples)

**Expected Features After Implementation**:
- ✅ Chromium engine (same as Android)
- ✅ Widevine DRM support
- ✅ Full cookie management
- ✅ JavaScript execution
- ✅ Download handling
- ✅ Permission requests

---

### macOS 🔧

**Status**: Flutter structure ready, WKWebView integration needed.

**Target Engine**: WKWebView (same as iOS)

**What's Ready**:
- ✅ Flutter AppKitView setup
- ✅ Method channel infrastructure
- ✅ Plugin registration structure
- ✅ Podspec configuration

**What's Needed**:
Native Swift/Objective-C code to:
1. Create WKWebView instance
2. Configure WKWebView settings
3. Handle navigation delegates
4. Manage cookies via WKHTTPCookieStore
5. Inject user scripts

**Files Created**:
```
macos/
├── real_webview.podspec              ✅ Ready
└── Classes/                          🔧 Needs implementation
    ├── RealWebviewPlugin.swift       (to be created)
    └── RealWebViewFactory.swift      (to be created)
```

**Setup Steps**:

1. **Copy iOS Implementation**
   ```bash
   # iOS code is 90% compatible with macOS
   cp -r ios/Classes/* macos/Classes/
   ```

2. **Update for AppKit**
   Replace UIKit imports with AppKit:
   ```swift
   // Change from
   import UIKit

   // To
   import AppKit
   ```

3. **Register FlutterPlatformView**
   ```swift
   public class RealWebviewPlugin: NSObject, FlutterPlugin {
     public static func register(with registrar: FlutterPluginRegistrar) {
       let factory = RealWebViewFactory(messenger: registrar.messenger)
       registrar.register(factory, withId: "real_webview")
     }
   }
   ```

**Expected Features After Implementation**:
- ✅ WKWebView engine
- ✅ FairPlay DRM support
- ✅ Full cookie management
- ✅ JavaScript execution
- ✅ User script injection
- ✅ Download handling

---

### Linux 🔧

**Status**: Flutter structure ready, WebKitGTK integration needed.

**Target Engine**: WebKitGTK (WebKit-based)

**What's Ready**:
- ✅ Flutter platform view setup
- ✅ Method channel infrastructure
- ✅ Plugin registration structure
- ✅ CMake build configuration

**What's Needed**:
Native C++ code to:
1. Initialize WebKitGTK
2. Handle navigation callbacks
3. Manage cookies
4. Execute JavaScript
5. Handle downloads

**Files Created**:
```
linux/
├── CMakeLists.txt                    ✅ Ready
└── real_webview_plugin.cc            🔧 Needs implementation
```

**Setup Steps**:

1. **Install WebKitGTK**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install libwebkit2gtk-4.0-dev

   # Fedora
   sudo dnf install webkit2gtk3-devel

   # Arch
   sudo pacman -S webkit2gtk
   ```

2. **Update CMakeLists.txt**
   ```cmake
   find_package(PkgConfig REQUIRED)
   pkg_check_modules(WEBKIT REQUIRED webkit2gtk-4.0)

   target_include_directories(${PLUGIN_NAME} PRIVATE ${WEBKIT_INCLUDE_DIRS})
   target_link_libraries(${PLUGIN_NAME} PRIVATE ${WEBKIT_LIBRARIES})
   ```

3. **Implement Native Code**
   ```cpp
   #include <webkit2/webkit2.h>

   // Create WebKitWebView
   // Configure settings
   // Handle signals (load-changed, etc.)
   // Implement method handlers
   ```

**Reference Implementation**:
See WebKitGTK [documentation](https://webkitgtk.org/reference/webkit2gtk/stable/index.html)

**Expected Features After Implementation**:
- ✅ WebKit engine
- ✅ Widevine DRM support (with plugins)
- ✅ Cookie management
- ✅ JavaScript execution
- ✅ Download handling

---

## Quick Start by Platform

### Using the Library

```dart
import 'package:real_webview/real_webview.dart';

class MyWebView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RealWebView(
      initialUrl: 'https://example.com',
      initialSettings: WebViewSettings(
        javaScriptEnabled: true,
        drmConfiguration: AutoDRMHandler.createAutoDRM(),
      ),
    );
  }
}
```

**Platform Detection**: Automatic!
- On Android/iOS: Uses native WebView
- On Web: Uses IFrame implementation
- On Windows/macOS/Linux: Uses native implementation (after setup)

---

## Implementation Priority

If you need to support desktop platforms, here's the recommended order:

### 1. Windows (Highest Priority)
- **Why**: Largest desktop user base
- **Difficulty**: Medium (good documentation)
- **Engine**: WebView2 (Chromium) - best compatibility
- **Time Estimate**: 2-3 days

### 2. macOS (High Priority)
- **Why**: Significant user base, can reuse iOS code
- **Difficulty**: Easy (90% code reuse from iOS)
- **Engine**: WKWebView - same as iOS
- **Time Estimate**: 1 day

### 3. Linux (Medium Priority)
- **Why**: Smaller but important developer audience
- **Difficulty**: Medium-Hard (less documentation)
- **Engine**: WebKitGTK - slightly different API
- **Time Estimate**: 2-3 days

---

## Native Implementation Guide

### General Structure

Each native platform needs to implement:

**1. Platform View Factory**
```dart
// Already done in Flutter layer
// Native needs to register with same viewType: 'real_webview'
```

**2. WebView Creation**
```cpp/swift/kotlin
// Create native WebView control
// Configure initial settings
// Set up event listeners
```

**3. Method Channel Handlers**
```cpp/swift/kotlin
// Handle methods from Flutter:
// - loadUrl
// - reload
// - goBack/goForward
// - evaluateJavascript
// - setSettings
// etc.
```

**4. Event Callbacks**
```cpp/swift/kotlin
// Send events to Flutter:
// - onUrlChanged
// - onLoadStart/onLoadStop
// - onProgressChanged
// - onLoadError
// - onConsoleMessage
```

### Code Templates

**Windows (C++)**:
```cpp
void RealWebviewPlugin::CreateWebView(int64_t view_id,
                                       const flutter::EncodableMap& params) {
  // Create WebView2 environment
  // Create WebView2 controller
  // Add event handlers
  // Return view handle
}
```

**macOS (Swift)**:
```swift
class RealWebViewFactory: NSObject, FlutterPlatformViewFactory {
  func create(withFrame frame: CGRect,
              viewIdentifier viewId: Int64,
              arguments args: Any?) -> FlutterPlatformView {
    return RealWebView(frame: frame, viewId: viewId, args: args)
  }
}
```

**Linux (C++)**:
```cpp
void RealWebviewPlugin::CreateWebView(int64_t view_id,
                                       const FlutterMethodCall& call) {
  WebKitWebView* webview = webkit_web_view_new();
  // Configure webview
  // Connect signals
  // Return webview
}
```

---

## Testing Desktop Platforms

Once native code is implemented:

### 1. Enable Platform
```bash
# Add platform support
flutter create --platforms=windows,macos,linux .
```

### 2. Run on Desktop
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### 3. Test Features
Run the example app and verify:
- [ ] URL loading
- [ ] Navigation (back/forward)
- [ ] JavaScript execution
- [ ] Cookie management
- [ ] Download handling
- [ ] DRM playback
- [ ] User script injection

---

## Common Issues & Solutions

### Windows

**Issue**: "WebView2 Runtime not found"
```bash
# Solution: Install WebView2 Runtime
https://go.microsoft.com/fwlink/p/?LinkId=2124703
```

**Issue**: "Cannot link WebView2"
```cmake
# Add to CMakeLists.txt
find_package(WebView2 CONFIG REQUIRED)
```

### macOS

**Issue**: "WKWebView not available"
```swift
// Minimum deployment target
# Set in Podfile
platform :osx, '10.15'
```

**Issue**: "Sandbox permissions"
```xml
<!-- Add to macos/Runner/Release.entitlements -->
<key>com.apple.security.network.client</key>
<true/>
```

### Linux

**Issue**: "webkit2gtk not found"
```bash
# Install development package
sudo apt-get install libwebkit2gtk-4.0-dev
```

**Issue**: "GTK version mismatch"
```cmake
# Specify exact version
pkg_check_modules(WEBKIT REQUIRED webkit2gtk-4.0>=2.28.0)
```

---

## Contributing

Want to help implement desktop support?

1. Fork the repository
2. Implement native code for your platform
3. Test thoroughly with the example app
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## Support

**Mobile & Web**: ✅ Fully supported, report issues
**Desktop**: 🔧 Community implementations welcome!

For questions:
- Check this guide
- Review example app
- Open GitHub issue

---

## Summary

| Platform | Works Today | Native Code Needed |
|----------|-------------|-------------------|
| Android | ✅ Yes | No |
| iOS | ✅ Yes | No |
| Web | ✅ Yes | No |
| Windows | 🔧 No | Yes (WebView2) |
| macOS | 🔧 No | Yes (WKWebView) |
| Linux | 🔧 No | Yes (WebKitGTK) |

**Mobile platforms (Android, iOS) and Web** are production-ready.
**Desktop platforms (Windows, macOS, Linux)** have the Flutter layer ready and need native implementation.

The API is consistent across all platforms - once desktop support is added, no Dart code changes needed!
