# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2025-01-14

### Added

#### Core Features
- Cross-platform WebView support (Android, iOS, Web, Windows, macOS, Linux)
- Chrome/Chromium-based rendering engine on Android
- WKWebView-based rendering on iOS and macOS
- API design mimicking flutter_inappwebview for easy migration

#### DRM Support
- Widevine DRM support (Android, Web)
- FairPlay DRM support (iOS, macOS)
- PlayReady DRM support (Windows)
- ClearKey DRM support (all platforms)
- Configurable license servers and custom headers
- Certificate URL support for FairPlay

#### Cookie Management
- Set single or multiple cookies with full control
- Get cookies by URL or name
- Delete specific cookies or all cookies
- Cookie attributes support: domain, path, expires, secure, httpOnly, sameSite
- Persistent cookie storage with flush support
- Cross-platform cookie synchronization

#### WebView Controller
- URL loading with custom headers
- HTML data loading
- Navigation controls (back, forward, reload)
- Navigation state queries (canGoBack, canGoForward)
- Current URL and title retrieval
- JavaScript execution
- Screenshot capture
- Cache and history management
- Zoom controls
- Settings management

#### WebView Settings
- JavaScript enable/disable
- DOM storage configuration
- Database support
- Custom user agent
- Zoom support configuration
- Media playback controls
- File access permissions
- Mixed content mode
- Safe browsing
- Hardware acceleration
- Transparent background support

#### Event Callbacks
- onWebViewCreated: WebView initialization callback
- onLoadStart: Page load start event
- onLoadStop: Page load complete event
- onProgressChanged: Loading progress updates
- onUrlChanged: URL change notifications
- onLoadError: Error handling
- onConsoleMessage: Console message forwarding

#### Platform-Specific Implementations
- **Android**: Native WebView with Chromium
  - Full WebSettings configuration
  - WebViewClient for navigation events
  - WebChromeClient for progress and console messages
  - Cookie management via CookieManager
  - DRM support via MediaDrm (Widevine)

- **iOS/macOS**: WKWebView implementation
  - WKWebViewConfiguration for settings
  - WKNavigationDelegate for navigation events
  - WKUIDelegate for JavaScript dialogs
  - HTTPCookieStore for cookie management
  - FairPlay DRM support
  - Screenshot capability

#### Example App
- Comprehensive example demonstrating all features
- URL bar with navigation
- Cookie management UI
- Settings viewer
- JavaScript executor
- Screenshot capture demo
- Progress indicators
- Error handling examples

#### Documentation
- Comprehensive README with usage examples
- API reference documentation
- DRM configuration guide
- Cookie management examples
- Platform-specific setup instructions
- Comparison with flutter_inappwebview

### Known Limitations
- Desktop platforms (Windows, Linux) have placeholder implementations
- Web platform uses iframe-based approach (limited DRM support)
- iOS cannot use Chrome engine (uses WKWebView instead)
- Android minimum SDK: 24 (Android 7.0)
- iOS minimum version: 11.0

### Technical Details
- Flutter SDK: ^3.10.0
- Kotlin version: 2.2.20
- Android compileSdk: 36
- Android minSdk: 24
- iOS deployment target: 11.0
