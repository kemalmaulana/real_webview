# Migration Guide: flutter_inappwebview → real_webview

This guide helps you migrate from `flutter_inappwebview` to `real_webview` while maintaining all your existing functionality.

## Key Differences

| Feature | flutter_inappwebview | real_webview |
|---------|---------------------|--------------|
| Cookie Setup | Manual JSON parsing | Built-in `CookieManager` |
| DRM | Manual platform channels | Automatic `AutoDRMHandler` |
| User Agent | Manual settings | Built-in settings |
| Downloads | Manual handling | Built-in with handlers |

## Step-by-Step Migration

### 1. Dependencies

**Before (pubspec.yaml):**
```yaml
dependencies:
  flutter_inappwebview: ^6.0.0
```

**After (pubspec.yaml):**
```yaml
dependencies:
  real_webview: ^0.0.1
  dio: ^5.0.0  # Keep if you use custom download handling
```

### 2. Cookie Management

**Before:**
```dart
final cookieManager = CookieManager.instance();
final decoded = jsonDecode(widget.cookies);

for (final entry in decoded) {
  final cookie = Map<String, dynamic>.from(entry);
  await cookieManager.setCookie(
    url: cookieUrl,
    name: name,
    value: value,
    domain: cookieDomain,
    path: path,
    isHttpOnly: isHttpOnly,
    isSecure: isSecure,
    sameSite: sameSite,
  );
}
```

**After:**
```dart
final cookieManager = CookieManager.instance();
final decoded = jsonDecode(widget.cookies);

for (final entry in decoded) {
  final cookie = Map<String, dynamic>.from(entry);

  await cookieManager.setCookie(
    url: widget.url,
    cookie: Cookie(
      name: cookie['name'],
      value: cookie['value'],
      domain: cookie['domain'],
      path: cookie['path'] ?? '/',
      isHttpOnly: cookie['httpOnly'] ?? false,
      isSecure: cookie['secure'] ?? true,
      sameSite: _parseSameSite(cookie['sameSite']),
    ),
  );
}

CookieSameSitePolicy _parseSameSite(dynamic value) {
  if (value == null) return CookieSameSitePolicy.noRestriction;
  final str = value.toString().toLowerCase();
  if (str == 'lax') return CookieSameSitePolicy.lax;
  if (str == 'strict') return CookieSameSitePolicy.strict;
  return CookieSameSitePolicy.noRestriction;
}
```

### 3. DRM Setup

**Before:**
```dart
// Platform channel calls
await platform.invokeMethod('enableWidevine');  // Android
await platform.invokeMethod('enableFairPlay');  // iOS

// Manual JavaScript injection for DRM detection
controller.addUserScript(/* complex DRM script */);
```

**After:**
```dart
// That's it! DRM is automatic
RealWebView(
  initialUrl: url,
  initialSettings: WebViewSettings(
    // Automatic DRM - no platform channels needed!
    drmConfiguration: AutoDRMHandler.createAutoDRM(),

    // Or use presets
    // drmConfiguration: AutoDRMHandler.getPreset('netflix'),
  ),
)
```

### 4. WebView Widget

**Before:**
```dart
InAppWebView(
  key: webViewKey,
  initialUrlRequest: URLRequest(url: WebUri(widget.url)),
  initialSettings: InAppWebViewSettings(
    useOnDownloadStart: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    userAgent: userAgentWeb,
    // ... many more settings
  ),
  onWebViewCreated: (controller) {
    webViewController = controller;
  },
  onLoadStart: (controller, url) {
    setState(() => isLoading = true);
  },
  onLoadStop: (controller, url) {
    setState(() => isLoading = false);
  },
)
```

**After:**
```dart
RealWebView(
  initialUrl: widget.url,
  initialSettings: WebViewSettings(
    javaScriptEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    domStorageEnabled: true,
    userAgent: userAgentWeb,
    drmConfiguration: AutoDRMHandler.createAutoDRM(),
    // All your settings in one place
  ),
  onWebViewCreated: (controller) {
    _controller = controller;
  },
  onLoadStart: (controller, url) {
    setState(() => isLoading = true);
  },
  onLoadStop: (controller, url) {
    setState(() => isLoading = false);
  },
)
```

### 5. User Agent Switching

**Before:**
```dart
webViewController?.setSettings(
  settings: InAppWebViewSettings(
    preferredContentMode: UserPreferredContentMode.DESKTOP,
    userAgent: userAgentWeb,
  ),
);
```

**After:**
```dart
await _controller?.setSettings(
  WebViewSettings(
    userAgent: userAgentWeb,
    // Settings automatically applied
  ),
);
await _controller?.reload();
```

## Complete Example

See [example_migration.dart](example/lib/example_migration.dart) for a complete working example that replicates your legacy functionality with:

- **Cookie injection from JSON** - Exact same format as your legacy code
- **Automatic DRM** - Replaces platform channel calls (enableWidevine/enableFairPlay)
- **User agent switching** - Desktop/Mobile mode toggle
- **Download handling** - JavaScript-based download interception
- **Blob downloads** - Automatic base64 conversion
- **Navigation controls** - Back/Forward/Refresh with state management
- **Orientation support** - Landscape drawer, portrait bottom bar
- **Progress indicators** - Linear progress bar during page load
- **Permission handling** - Ready for camera, microphone, location permissions

Run the example app and select "Migration from InAppWebView" to see it in action!

## Feature Compatibility Matrix

| Your Feature | Real WebView Equivalent | Status |
|--------------|------------------------|--------|
| Cookie injection from JSON | `CookieManager.setCookie()` | ✅ Full |
| Widevine DRM | `AutoDRMHandler` | ✅ Automatic |
| FairPlay DRM | `AutoDRMHandler` | ✅ Automatic |
| Custom user agents | `WebViewSettings.userAgent` | ✅ Full |
| Download handling | Built-in + custom handlers | ✅ Full |
| JavaScript handlers | `addJavaScriptHandler()` | ✅ Full |
| Blob downloads | JavaScript injection | ✅ Compatible |
| Permission requests | Built-in handling | ✅ Full |
| Desktop/Mobile mode | Settings + user agent | ✅ Full |
| Pull to refresh | Native support | ✅ Full |
| Console messages | `onConsoleMessage` | ✅ Full |
| Navigation control | `goBack()`, `goForward()` | ✅ Full |

## Key Benefits of Migration

1. **Simpler DRM**: No platform channels needed - automatic detection
2. **Better Cookie Management**: Type-safe API instead of raw maps
3. **Cleaner Code**: Less boilerplate, more features
4. **Chrome-like**: Automatic DRM just like Chrome browser
5. **Future-proof**: Active development and modern API

## Need Help?

- Check the [example app](example/lib/main.dart)
- Read the [Auto DRM Guide](AUTO_DRM_GUIDE.md)
- See the [complete example](example/lib/example_migration.dart)
