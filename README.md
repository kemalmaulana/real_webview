# Real WebView

A powerful cross-platform Flutter WebView plugin using Chrome/Chromium as the base browser with **automatic DRM support** - no license server configuration needed! This plugin mimics the API of `flutter_inappwebview` for easy migration and familiarity.

## 🚀 Key Features

- **🔒 Automatic DRM**: Just like Chrome - no manual license server URLs needed! Works with Netflix, Disney+, Prime, and more
- **🌐 Chrome/Chromium Based**: Uses native WebView with Chromium on Android and WKWebView on iOS
- **📱 Cross-Platform**: Android ✅ | iOS ✅ | Web ✅ | Windows 🔧 | macOS 🔧 | Linux 🔧
- **🍪 Cookie Management**: Full cookie injection and management capabilities
- **🎬 Multi-DRM Support**: Widevine, FairPlay, PlayReady, and ClearKey DRM schemes
- **🔄 Familiar API**: Mimics `flutter_inappwebview` for easy adoption
- **⚡ Rich Feature Set**: JavaScript execution, navigation control, screenshot capture, and more

## 🎯 Why Real WebView?

Unlike other Flutter WebView plugins that require complex manual DRM configuration, Real WebView automatically handles DRM **just like Google Chrome**:

```dart
// ❌ Old way - manual configuration
drmConfiguration: DRMConfiguration.widevine(
  licenseServerUrl: 'https://complicated-license-server.com/...',
  headers: {...},
  customData: {...},
)

// ✅ Real WebView - automatic!
drmConfiguration: AutoDRMHandler.createAutoDRM()
// That's it! Works with Netflix, Disney+, Prime, etc.
```

## Platform Support

| Platform | Status | Engine | Setup Required |
|----------|--------|--------|----------------|
| **Android** | ✅ Ready | Chromium WebView | No |
| **iOS** | ✅ Ready | WKWebView | No |
| **Web** | ✅ Ready | Browser IFrame | No |
| **Windows** | 🔧 Setup Required | WebView2 (Edge) | Yes - [Guide](PLATFORM_SETUP.md#windows-) |
| **macOS** | 🔧 Setup Required | WKWebView | Yes - [Guide](PLATFORM_SETUP.md#macos-) |
| **Linux** | 🔧 Setup Required | WebKitGTK | Yes - [Guide](PLATFORM_SETUP.md#linux-) |

**Legend**: ✅ Ready (works out of the box) | 🔧 Setup Required (Flutter API ready, needs native code)

> **Desktop Platforms**: The Flutter/Dart API layer is fully implemented for Windows, macOS, and Linux. You only need to add the native platform code following our [Platform Setup Guide](PLATFORM_SETUP.md).

## Supported DRM Schemes

| DRM Scheme | Android | iOS | Web | Windows | macOS | Linux |
|------------|---------|-----|-----|---------|-------|-------|
| Widevine   | ✅      | ❌  | ✅  | ❌      | ❌    | ❌    |
| FairPlay   | ❌      | ✅  | ❌  | ❌      | ✅    | ❌    |
| PlayReady  | ❌      | ❌  | ❌  | ✅      | ❌    | ❌    |
| ClearKey   | ✅      | ✅  | ✅  | ✅      | ✅    | ✅    |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  real_webview: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Platform Setup

### Android

No additional setup required. The plugin uses Android's native WebView which is based on Chromium.

**Minimum SDK**: 24 (Android 7.0)

### iOS

Add the following to your `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Minimum iOS Version**: 11.0

### Web

The plugin will use iframe-based implementation for web.

## 🔥 Automatic DRM (No Configuration Needed!)

Real WebView's killer feature is **automatic DRM handling** - just like Chrome! No need to manually configure license servers.

### Quick Start

```dart
RealWebView(
  initialUrl: 'https://www.netflix.com',
  initialSettings: WebViewSettings(
    // AUTO-DRM: That's all you need!
    drmConfiguration: AutoDRMHandler.createAutoDRM(),
  ),
)
```

### Streaming Service Presets

```dart
// Netflix
drmConfiguration: AutoDRMHandler.getPreset('netflix')

// Disney+
drmConfiguration: AutoDRMHandler.getPreset('disneyplus')

// Amazon Prime
drmConfiguration: AutoDRMHandler.getPreset('prime')

// Apple TV+ (FairPlay)
drmConfiguration: AutoDRMHandler.getPreset('appletv')
```

### How It Works

Real WebView automatically:
1. ✅ Detects DRM scheme from the media stream
2. ✅ Configures EME (Encrypted Media Extensions)
3. ✅ Handles license acquisition from manifest files
4. ✅ Supports Widevine, FairPlay, PlayReady, ClearKey

**Learn more**: See [AUTO_DRM_GUIDE.md](AUTO_DRM_GUIDE.md) for detailed documentation and examples.

## Usage

### Basic WebView

```dart
import 'package:flutter/material.dart';
import 'package:real_webview/real_webview.dart';

class MyWebView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RealWebView(
      initialUrl: 'https://flutter.dev',
      onWebViewCreated: (controller) {
        print('WebView created');
      },
    );
  }
}
```

### WebView with Settings

```dart
RealWebView(
  initialUrl: 'https://example.com',
  initialSettings: WebViewSettings(
    javaScriptEnabled: true,
    domStorageEnabled: true,
    supportZoom: true,
    builtInZoomControls: true,
    displayZoomControls: false,
    mediaPlaybackRequiresUserGesture: false,
    allowFileAccess: false,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
    safeBrowsingEnabled: true,
    userAgent: 'CustomUserAgent/1.0',
  ),
  onWebViewCreated: (controller) {
    // WebView is ready
  },
)
```

### DRM Configuration

#### Widevine (Android, Web)

```dart
RealWebView(
  initialUrl: 'https://example.com/video',
  initialSettings: WebViewSettings(
    drmConfiguration: DRMConfiguration.widevine(
      licenseServerUrl: 'https://proxy.uat.widevine.com/proxy',
      headers: {
        'X-Custom-Header': 'value',
      },
      customData: {
        'userId': '12345',
      },
    ),
  ),
)
```

#### FairPlay (iOS, macOS)

```dart
RealWebView(
  initialUrl: 'https://example.com/video',
  initialSettings: WebViewSettings(
    drmConfiguration: DRMConfiguration.fairplay(
      licenseServerUrl: 'https://fps.example.com/license',
      certificateUrl: 'https://fps.example.com/cert',
      headers: {
        'Authorization': 'Bearer token',
      },
    ),
  ),
)
```

#### PlayReady (Windows)

```dart
RealWebView(
  initialUrl: 'https://example.com/video',
  initialSettings: WebViewSettings(
    drmConfiguration: DRMConfiguration.playready(
      licenseServerUrl: 'https://test.playready.microsoft.com/service',
      headers: {
        'X-Custom-Header': 'value',
      },
    ),
  ),
)
```

#### ClearKey (All Platforms)

```dart
RealWebView(
  initialUrl: 'https://example.com/video',
  initialSettings: WebViewSettings(
    drmConfiguration: DRMConfiguration.clearkey(
      keys: {
        'keyId1': 'key1',
        'keyId2': 'key2',
      },
    ),
  ),
)
```

### Cookie Management

#### Setting Cookies

```dart
import 'package:real_webview/real_webview.dart';

// Set a single cookie
await CookieManager.instance().setCookie(
  url: 'https://example.com',
  cookie: Cookie(
    name: 'session',
    value: 'abc123',
    domain: '.example.com',
    path: '/',
    expiresDate: DateTime.now().add(Duration(days: 7)).millisecondsSinceEpoch,
    isSecure: true,
    isHttpOnly: false,
    sameSite: CookieSameSitePolicy.LAX,
  ),
);

// Set multiple cookies
await CookieManager.instance().setCookies(
  url: 'https://example.com',
  cookies: [
    Cookie(name: 'cookie1', value: 'value1'),
    Cookie(name: 'cookie2', value: 'value2'),
  ],
);
```

#### Getting Cookies

```dart
// Get all cookies for a URL
List<Cookie> cookies = await CookieManager.instance().getCookies(
  url: 'https://example.com',
);

// Get a specific cookie
Cookie? cookie = await CookieManager.instance().getCookie(
  url: 'https://example.com',
  name: 'session',
);

// Get all cookies from all domains
List<Cookie> allCookies = await CookieManager.instance().getAllCookies();
```

#### Deleting Cookies

```dart
// Delete a specific cookie
await CookieManager.instance().deleteCookie(
  url: 'https://example.com',
  name: 'session',
);

// Delete all cookies for a URL
await CookieManager.instance().deleteCookies(
  url: 'https://example.com',
);

// Delete all cookies
await CookieManager.instance().deleteAllCookies();

// Flush cookies to storage
await CookieManager.instance().flush();
```

### WebView Controller

```dart
RealWebViewController? _controller;

RealWebView(
  initialUrl: 'https://example.com',
  onWebViewCreated: (controller) {
    _controller = controller;
  },
)

// Navigation
await _controller.loadUrl(url: 'https://flutter.dev');
await _controller.reload();
await _controller.goBack();
await _controller.goForward();

bool canGoBack = await _controller.canGoBack();
bool canGoForward = await _controller.canGoForward();

// Get current state
String? url = await _controller.getUrl();
String? title = await _controller.getTitle();

// JavaScript execution
var result = await _controller.evaluateJavascript(
  source: 'document.title',
);

// Load HTML data
await _controller.loadData(
  data: '<html><body><h1>Hello World</h1></body></html>',
  mimeType: 'text/html',
  encoding: 'utf-8',
  baseUrl: 'https://example.com',
);

// Screenshot
Uint8List? screenshot = await _controller.takeScreenshot();

// Cache management
await _controller.clearCache();
await _controller.clearHistory();

// Zoom control
await _controller.zoomIn();
await _controller.zoomOut();
await _controller.setZoomScale(1.5);
double scale = await _controller.getZoomScale();
```

### Event Listeners

```dart
RealWebView(
  initialUrl: 'https://example.com',
  onWebViewCreated: (controller) {
    print('WebView created');
  },
  onLoadStart: (controller, url) {
    print('Started loading: $url');
  },
  onLoadStop: (controller, url) {
    print('Finished loading: $url');
  },
  onProgressChanged: (controller, progress) {
    print('Progress: $progress%');
  },
  onUrlChanged: (controller, url) {
    print('URL changed: $url');
  },
  onLoadError: (controller, error) {
    print('Error: ${error.description}');
  },
  onConsoleMessage: (controller, message) {
    print('Console [${message.level}]: ${message.message}');
  },
)
```

## API Reference

### RealWebView Widget

| Parameter | Type | Description |
|-----------|------|-------------|
| `initialUrl` | `String?` | Initial URL to load |
| `initialData` | `String?` | Initial HTML data to load |
| `initialSettings` | `WebViewSettings?` | Initial WebView settings |
| `onWebViewCreated` | `Function?` | Callback when WebView is created |
| `onLoadStart` | `Function?` | Callback when page starts loading |
| `onLoadStop` | `Function?` | Callback when page finishes loading |
| `onProgressChanged` | `Function?` | Callback for load progress updates |
| `onUrlChanged` | `Function?` | Callback when URL changes |
| `onLoadError` | `Function?` | Callback when an error occurs |
| `onConsoleMessage` | `Function?` | Callback for console messages |

### WebViewSettings

Comprehensive settings for configuring WebView behavior:

- `javaScriptEnabled`: Enable/disable JavaScript
- `domStorageEnabled`: Enable/disable DOM storage
- `databaseEnabled`: Enable/disable database
- `userAgent`: Custom user agent string
- `supportZoom`: Enable/disable zoom
- `mediaPlaybackRequiresUserGesture`: Require user gesture for media playback
- `drmConfiguration`: DRM configuration
- And many more...

### CookieManager

Singleton class for managing cookies:

- `setCookie()`: Set a single cookie
- `setCookies()`: Set multiple cookies
- `getCookies()`: Get cookies for a URL
- `getCookie()`: Get a specific cookie
- `deleteCookie()`: Delete a specific cookie
- `deleteCookies()`: Delete all cookies for a URL
- `deleteAllCookies()`: Delete all cookies
- `getAllCookies()`: Get all cookies
- `flush()`: Persist cookies to storage
- `hasCookies()`: Check if cookies exist

## Comparison with flutter_inappwebview

`real_webview` is designed to mimic `flutter_inappwebview`'s API while using Chrome/Chromium as the base browser across all platforms:

| Feature | real_webview | flutter_inappwebview |
|---------|-------------|----------------------|
| Chrome/Chromium Base | ✅ | ❌ |
| Cookie Management | ✅ | ✅ |
| DRM Support | ✅ (Widevine, FairPlay, PlayReady, ClearKey) | Limited |
| API Compatibility | Similar | - |
| Cross-Platform | ✅ | ✅ |

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and feature requests, please file an issue on the [GitHub repository](https://github.com/yourusername/real_webview).

## Acknowledgments

This plugin was inspired by `flutter_inappwebview` and designed to provide a Chrome/Chromium-based WebView experience with enhanced DRM support.
