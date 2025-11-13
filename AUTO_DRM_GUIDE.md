# Automatic DRM Guide

## Overview

Real WebView supports **automatic DRM handling** just like Google Chrome - no need to manually configure license servers! This allows you to play DRM-protected content from streaming services like Netflix, Disney+, Amazon Prime, and more without any manual DRM configuration.

## How It Works

Unlike traditional approaches that require you to manually specify license server URLs, Real WebView automatically:

1. **Detects DRM schemes** from the media stream
2. **Configures EME** (Encrypted Media Extensions) APIs
3. **Handles license acquisition** automatically from the stream metadata
4. **Supports multiple DRM systems** (Widevine, FairPlay, PlayReady, ClearKey)

This is the same approach used by Chrome, Safari, and other modern browsers.

## Quick Start

### Simple Auto-DRM

```dart
RealWebView(
  initialUrl: 'https://www.netflix.com',
  initialSettings: WebViewSettings(
    javaScriptEnabled: true,
    // That's it! DRM is automatically handled
    drmConfiguration: AutoDRMHandler.createAutoDRM(),
  ),
)
```

### Using Presets for Popular Services

```dart
// Netflix
drmConfiguration: AutoDRMHandler.getPreset('netflix')

// Disney+
drmConfiguration: AutoDRMHandler.getPreset('disneyplus')

// Amazon Prime
drmConfiguration: AutoDRMHandler.getPreset('prime')

// Apple TV+ (FairPlay)
drmConfiguration: AutoDRMHandler.getPreset('appletv')

// Generic HLS with FairPlay
drmConfiguration: AutoDRMHandler.getPreset('hls-fairplay')

// Generic DASH with Widevine
drmConfiguration: AutoDRMHandler.getPreset('dash-widevine')
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:real_webview/real_webview.dart';

class StreamingPlayer extends StatefulWidget {
  @override
  _StreamingPlayerState createState() => _StreamingPlayerState();
}

class _StreamingPlayerState extends State<StreamingPlayer> {
  RealWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Streaming Player')),
      body: RealWebView(
        initialUrl: 'https://www.netflix.com',
        initialSettings: WebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          mediaPlaybackRequiresUserGesture: false,

          // AUTO-DRM: No license server configuration needed!
          drmConfiguration: AutoDRMHandler.createAutoDRM(),
        ),
        onWebViewCreated: (controller) {
          _controller = controller;
        },
        onConsoleMessage: (controller, message) {
          // Monitor DRM initialization
          if (message.message.contains('DRM') ||
              message.message.contains('RealWebView')) {
            print('[DRM] ${message.message}');
          }
        },
      ),
    );
  }
}
```

## How Automatic DRM Detection Works

### 1. EME API Integration

Real WebView injects JavaScript that:
- Intercepts `navigator.requestMediaKeySystemAccess()` calls
- Automatically configures supported codecs and capabilities
- Handles multiple DRM schemes (Widevine, FairPlay, etc.)

### 2. Media Element Monitoring

The system automatically:
- Detects when video/audio elements are added to the page
- Listens for `encrypted` events
- Generates license requests automatically
- Handles key system selection

### 3. Multi-DRM Support

Real WebView tries DRM systems in order of preference:
1. **Widevine** (`com.widevine.alpha`) - Android, Web
2. **PlayReady** (`com.microsoft.playready`) - Windows
3. **FairPlay** (`com.apple.fps.1_0`) - iOS, macOS
4. **ClearKey** (`org.w3.clearkey`) - All platforms

## Platform-Specific Behavior

### Android (Widevine)
- Uses native Android WebView with Chromium
- Widevine Level 3 (SW_SECURE_CRYPTO) by default
- Hardware DRM if device supports it
- Automatic license acquisition from DASH manifests

### iOS/macOS (FairPlay)
- Uses WKWebView with native FairPlay support
- Handles both modern EME and legacy WebKit APIs
- Automatic certificate and license requests
- HLS manifest parsing for FairPlay

### Web
- Uses standard browser EME APIs
- Widevine support in Chrome/Edge
- FairPlay support in Safari
- Automatic fallback to ClearKey if needed

## Advanced Configuration

### Custom Headers

```dart
drmConfiguration: AutoDRMHandler.createAutoDRM(
  customHeaders: {
    'X-Custom-Token': 'your-auth-token',
    'User-Agent': 'CustomApp/1.0',
  },
)
```

### Preferred DRM Scheme

```dart
drmConfiguration: AutoDRMHandler.createAutoDRM(
  preferredScheme: DRMSchemeType.WIDEVINE,
)
```

### With Cookie Authentication

```dart
// Set authentication cookies before loading
await CookieManager.instance().setCookie(
  url: 'https://streaming-service.com',
  cookie: Cookie(
    name: 'auth_token',
    value: 'your-session-token',
    domain: '.streaming-service.com',
    isSecure: true,
    sameSite: CookieSameSitePolicy.LAX,
  ),
);

// Then load with auto-DRM
RealWebView(
  initialUrl: 'https://streaming-service.com/video',
  initialSettings: WebViewSettings(
    drmConfiguration: AutoDRMHandler.createAutoDRM(),
  ),
)
```

## Supported Streaming Protocols

### DASH (Dynamic Adaptive Streaming over HTTP)
- Automatic Widevine DRM detection
- MPD manifest parsing
- Multi-bitrate adaptation

### HLS (HTTP Live Streaming)
- Automatic FairPlay DRM detection
- M3U8 playlist parsing
- Multi-bitrate adaptation

### Smooth Streaming
- PlayReady DRM support
- Manifest-based configuration

## Debugging DRM

### Console Logs

Enable console message logging to see DRM initialization:

```dart
onConsoleMessage: (controller, message) {
  print('[${message.level}] ${message.message}');
}
```

Look for messages like:
- `[RealWebView] Enabling automatic DRM support`
- `[RealWebView] DRM requested: com.widevine.alpha`
- `[RealWebView] Media keys created`

### Common Issues

**DRM not working?**
1. Check if JavaScript is enabled
2. Verify the streaming service supports your platform's DRM
3. Check console logs for error messages
4. Ensure cookies/authentication are set if needed

**Video plays but quality is low?**
- This is normal for SW_SECURE_CRYPTO (Widevine L3)
- HD/4K requires hardware DRM (L1) which depends on device

**License request failures?**
- Check network connectivity
- Verify authentication cookies
- Check if streaming service requires specific headers

## Comparison: Auto-DRM vs Manual Configuration

### ❌ Old Way (Manual Configuration)

```dart
// You had to know and configure everything manually
drmConfiguration: DRMConfiguration.widevine(
  licenseServerUrl: 'https://proxy.uat.widevine.com/proxy?provider=widevine_test',
  headers: {
    'Content-Type': 'application/octet-stream',
  },
  customData: {
    'userId': '12345',
    'merchantId': 'merchant123',
  },
)
```

**Problems:**
- Need to find license server URLs
- Different configuration for each service
- Must know which DRM system to use
- Complex setup for multi-DRM

### ✅ New Way (Automatic)

```dart
// Just enable auto-DRM - works everywhere!
drmConfiguration: AutoDRMHandler.createAutoDRM()

// Or use a preset
drmConfiguration: AutoDRMHandler.getPreset('netflix')
```

**Benefits:**
- No license server URLs needed
- Works with any streaming service
- Automatic DRM detection
- Chrome-like experience

## Real-World Examples

### Netflix

```dart
RealWebView(
  initialUrl: 'https://www.netflix.com',
  initialSettings: WebViewSettings(
    drmConfiguration: AutoDRMHandler.getPreset('netflix'),
  ),
)
```

### Disney+

```dart
RealWebView(
  initialUrl: 'https://www.disneyplus.com',
  initialSettings: WebViewSettings(
    drmConfiguration: AutoDRMHandler.getPreset('disneyplus'),
  ),
)
```

### Custom Streaming Service

```dart
// Works with any DASH/HLS stream!
RealWebView(
  initialUrl: 'https://your-cdn.com/video/manifest.mpd',
  initialSettings: WebViewSettings(
    drmConfiguration: AutoDRMHandler.createAutoDRM(),
  ),
)
```

## Technical Details

### EME (Encrypted Media Extensions)

Real WebView implements the W3C EME specification:
- MediaKeySystemAccess configuration
- MediaKeys creation and management
- MediaKeySession handling
- License request/response processing

### CDM (Content Decryption Module)

Platform-specific CDMs are used:
- **Android**: Widevine CDM (built into Android)
- **iOS/macOS**: FairPlay Streaming
- **Windows**: PlayReady
- **Fallback**: ClearKey (for testing)

### Media Source Extensions (MSE)

Automatic support for adaptive streaming:
- SourceBuffer management
- Segment appending
- Quality switching

## Best Practices

1. **Always use Auto-DRM for production**
   - More reliable than manual configuration
   - Works across different streaming services
   - Handles updates automatically

2. **Use presets for known services**
   - Optimized configurations
   - Better compatibility
   - Easier to maintain

3. **Set cookies before loading**
   - Authentication is often cookie-based
   - Set cookies before initializing WebView
   - Use secure and httpOnly flags

4. **Enable console logging in development**
   - Monitor DRM initialization
   - Debug license request issues
   - Track playback events

5. **Test on multiple devices**
   - Different DRM levels
   - Hardware vs software DRM
   - Various Android/iOS versions

## FAQ

**Q: Do I need to pay for DRM licenses?**
A: No, the DRM systems (Widevine, FairPlay) are built into the platforms. You only need rights to the content you're streaming.

**Q: Can I play Netflix/Disney+ in my app?**
A: Technically yes with auto-DRM, but you need proper licensing agreements with these services. This is for authorized use only.

**Q: What's the difference from flutter_inappwebview?**
A: Real WebView provides automatic DRM detection and configuration, making it much easier to handle protected content without manual setup.

**Q: Does this work offline?**
A: DRM typically requires online license validation. Some platforms support offline playback with persistent licenses, but that requires additional implementation.

**Q: Is this secure?**
A: Yes, DRM systems are implemented at the platform level with hardware security where available. Real WebView uses the same DRM as Chrome/Safari.

## License

The automatic DRM feature is part of Real WebView and follows the same license (MIT).

---

**Need help?** Check the [example app](example/lib/streaming_demo.dart) for a complete working demo!
