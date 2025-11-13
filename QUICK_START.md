# Quick Start Guide

This guide will help you get started with Real WebView in just a few minutes.

## 1. Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  real_webview: ^0.0.1
```

Run:
```bash
flutter pub get
```

## 2. Basic Usage

### Simple WebView

```dart
import 'package:flutter/material.dart';
import 'package:real_webview/real_webview.dart';

class MyWebViewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My WebView')),
      body: RealWebView(
        initialUrl: 'https://flutter.dev',
      ),
    );
  }
}
```

### With Controller

```dart
class MyWebViewScreen extends StatefulWidget {
  @override
  _MyWebViewScreenState createState() => _MyWebViewScreenState();
}

class _MyWebViewScreenState extends State<MyWebViewScreen> {
  RealWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My WebView'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _controller?.reload(),
          ),
        ],
      ),
      body: RealWebView(
        initialUrl: 'https://flutter.dev',
        onWebViewCreated: (controller) {
          _controller = controller;
        },
      ),
    );
  }
}
```

## 3. Cookie Management

```dart
// Set a cookie
await CookieManager.instance().setCookie(
  url: 'https://example.com',
  cookie: Cookie(
    name: 'session',
    value: 'your_session_token',
    domain: '.example.com',
    isSecure: true,
  ),
);

// Get cookies
List<Cookie> cookies = await CookieManager.instance().getCookies(
  url: 'https://example.com',
);
```

## 4. DRM Configuration

### For Android (Widevine)

```dart
RealWebView(
  initialUrl: 'https://your-drm-video-url.com',
  initialSettings: WebViewSettings(
    drmConfiguration: DRMConfiguration.widevine(
      licenseServerUrl: 'https://your-license-server.com',
      headers: {'X-API-Key': 'your-api-key'},
    ),
  ),
)
```

### For iOS (FairPlay)

```dart
RealWebView(
  initialUrl: 'https://your-drm-video-url.com',
  initialSettings: WebViewSettings(
    drmConfiguration: DRMConfiguration.fairplay(
      licenseServerUrl: 'https://your-license-server.com',
      certificateUrl: 'https://your-cert-server.com/cert',
    ),
  ),
)
```

## 5. JavaScript Execution

```dart
// Execute JavaScript
final result = await _controller?.evaluateJavascript(
  source: 'document.title',
);
print('Page title: $result');

// Inject JavaScript
await _controller?.evaluateJavascript(
  source: '''
    document.body.style.backgroundColor = 'lightblue';
  ''',
);
```

## 6. Event Handling

```dart
RealWebView(
  initialUrl: 'https://flutter.dev',
  onLoadStart: (controller, url) {
    print('Started loading: $url');
  },
  onLoadStop: (controller, url) {
    print('Finished loading: $url');
  },
  onProgressChanged: (controller, progress) {
    print('Loading progress: $progress%');
  },
  onLoadError: (controller, error) {
    print('Error: ${error.description}');
  },
)
```

## 7. Common Tasks

### Load a URL
```dart
await _controller?.loadUrl(url: 'https://flutter.dev');
```

### Load HTML
```dart
await _controller?.loadData(
  data: '<html><body><h1>Hello!</h1></body></html>',
);
```

### Navigation
```dart
await _controller?.goBack();
await _controller?.goForward();
await _controller?.reload();
```

### Take Screenshot
```dart
Uint8List? screenshot = await _controller?.takeScreenshot();
if (screenshot != null) {
  // Use the screenshot
  Image.memory(screenshot);
}
```

### Clear Cache
```dart
await _controller?.clearCache();
await _controller?.clearHistory();
```

## 8. Platform-Specific Setup

### Android
No additional setup required!

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Next Steps

- Check out the [full example app](example/lib/main.dart) for more features
- Read the [README](README.md) for complete API documentation
- Explore [DRM configuration](README.md#drm-configuration) for protected content
- Learn about [advanced cookie management](README.md#cookie-management)

## Troubleshooting

### Android: WebView not displaying
- Ensure minimum SDK is 24 or higher in `android/app/build.gradle`
- Check internet permissions in `AndroidManifest.xml`

### iOS: Cannot load HTTP URLs
- Add NSAppTransportSecurity settings to Info.plist (see above)

### Cookies not persisting
- Call `await CookieManager.instance().flush()` to ensure cookies are saved

## Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/yourusername/real_webview/issues)
- Documentation: [README](README.md)

Happy coding with Real WebView!
