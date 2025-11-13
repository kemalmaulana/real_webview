import 'drm_configuration.dart';

/// WebView settings and configuration
class WebViewSettings {
  /// Enable JavaScript
  final bool javaScriptEnabled;

  /// Enable DOM storage
  final bool domStorageEnabled;

  /// Enable database storage
  final bool databaseEnabled;

  /// User agent string
  final String? userAgent;

  /// Enable zoom controls
  final bool supportZoom;

  /// Enable media playback requires user gesture
  final bool mediaPlaybackRequiresUserGesture;

  /// Enable caching
  final bool cacheEnabled;

  /// Cache mode
  final CacheMode cacheMode;

  /// Allow file access
  final bool allowFileAccess;

  /// Allow content access
  final bool allowContentAccess;

  /// Allow file access from file URLs
  final bool allowFileAccessFromFileURLs;

  /// Allow universal access from file URLs
  final bool allowUniversalAccessFromFileURLs;

  /// Enable mixed content mode
  final MixedContentMode mixedContentMode;

  /// Enable safe browsing
  final bool safeBrowsingEnabled;

  /// Text zoom
  final int textZoom;

  /// Minimum font size
  final int minimumFontSize;

  /// Enable viewport meta tag
  final bool useWideViewPort;

  /// Load with overview mode
  final bool loadWithOverviewMode;

  /// Enable built-in zoom controls
  final bool builtInZoomControls;

  /// Display zoom controls
  final bool displayZoomControls;

  /// DRM configuration
  final DRMConfiguration? drmConfiguration;

  /// Enable hardware acceleration
  final bool hardwareAcceleration;

  /// Transparent background
  final bool transparentBackground;

  WebViewSettings({
    this.javaScriptEnabled = true,
    this.domStorageEnabled = true,
    this.databaseEnabled = true,
    this.userAgent,
    this.supportZoom = true,
    this.mediaPlaybackRequiresUserGesture = false,
    this.cacheEnabled = true,
    this.cacheMode = CacheMode.loadDefault,
    this.allowFileAccess = false,
    this.allowContentAccess = true,
    this.allowFileAccessFromFileURLs = false,
    this.allowUniversalAccessFromFileURLs = false,
    this.mixedContentMode = MixedContentMode.mixedContentNeverAllow,
    this.safeBrowsingEnabled = true,
    this.textZoom = 100,
    this.minimumFontSize = 8,
    this.useWideViewPort = true,
    this.loadWithOverviewMode = true,
    this.builtInZoomControls = true,
    this.displayZoomControls = false,
    this.drmConfiguration,
    this.hardwareAcceleration = true,
    this.transparentBackground = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'javaScriptEnabled': javaScriptEnabled,
      'domStorageEnabled': domStorageEnabled,
      'databaseEnabled': databaseEnabled,
      'userAgent': userAgent,
      'supportZoom': supportZoom,
      'mediaPlaybackRequiresUserGesture': mediaPlaybackRequiresUserGesture,
      'cacheEnabled': cacheEnabled,
      'cacheMode': cacheMode.index,
      'allowFileAccess': allowFileAccess,
      'allowContentAccess': allowContentAccess,
      'allowFileAccessFromFileURLs': allowFileAccessFromFileURLs,
      'allowUniversalAccessFromFileURLs': allowUniversalAccessFromFileURLs,
      'mixedContentMode': mixedContentMode.index,
      'safeBrowsingEnabled': safeBrowsingEnabled,
      'textZoom': textZoom,
      'minimumFontSize': minimumFontSize,
      'useWideViewPort': useWideViewPort,
      'loadWithOverviewMode': loadWithOverviewMode,
      'builtInZoomControls': builtInZoomControls,
      'displayZoomControls': displayZoomControls,
      'drmConfiguration': drmConfiguration?.toMap(),
      'hardwareAcceleration': hardwareAcceleration,
      'transparentBackground': transparentBackground,
    };
  }

  factory WebViewSettings.fromMap(Map<String, dynamic> map) {
    return WebViewSettings(
      javaScriptEnabled: map['javaScriptEnabled'] as bool? ?? true,
      domStorageEnabled: map['domStorageEnabled'] as bool? ?? true,
      databaseEnabled: map['databaseEnabled'] as bool? ?? true,
      userAgent: map['userAgent'] as String?,
      supportZoom: map['supportZoom'] as bool? ?? true,
      mediaPlaybackRequiresUserGesture:
          map['mediaPlaybackRequiresUserGesture'] as bool? ?? false,
      cacheEnabled: map['cacheEnabled'] as bool? ?? true,
      cacheMode: CacheMode.values[map['cacheMode'] as int? ?? 0],
      allowFileAccess: map['allowFileAccess'] as bool? ?? false,
      allowContentAccess: map['allowContentAccess'] as bool? ?? true,
      allowFileAccessFromFileURLs:
          map['allowFileAccessFromFileURLs'] as bool? ?? false,
      allowUniversalAccessFromFileURLs:
          map['allowUniversalAccessFromFileURLs'] as bool? ?? false,
      mixedContentMode: MixedContentMode.values[map['mixedContentMode'] as int? ?? 2],
      safeBrowsingEnabled: map['safeBrowsingEnabled'] as bool? ?? true,
      textZoom: map['textZoom'] as int? ?? 100,
      minimumFontSize: map['minimumFontSize'] as int? ?? 8,
      useWideViewPort: map['useWideViewPort'] as bool? ?? true,
      loadWithOverviewMode: map['loadWithOverviewMode'] as bool? ?? true,
      builtInZoomControls: map['builtInZoomControls'] as bool? ?? true,
      displayZoomControls: map['displayZoomControls'] as bool? ?? false,
      drmConfiguration: map['drmConfiguration'] != null
          ? DRMConfiguration.fromMap(map['drmConfiguration'] as Map<String, dynamic>)
          : null,
      hardwareAcceleration: map['hardwareAcceleration'] as bool? ?? true,
      transparentBackground: map['transparentBackground'] as bool? ?? false,
    );
  }

  WebViewSettings copyWith({
    bool? javaScriptEnabled,
    bool? domStorageEnabled,
    bool? databaseEnabled,
    String? userAgent,
    bool? supportZoom,
    bool? mediaPlaybackRequiresUserGesture,
    bool? cacheEnabled,
    CacheMode? cacheMode,
    bool? allowFileAccess,
    bool? allowContentAccess,
    bool? allowFileAccessFromFileURLs,
    bool? allowUniversalAccessFromFileURLs,
    MixedContentMode? mixedContentMode,
    bool? safeBrowsingEnabled,
    int? textZoom,
    int? minimumFontSize,
    bool? useWideViewPort,
    bool? loadWithOverviewMode,
    bool? builtInZoomControls,
    bool? displayZoomControls,
    DRMConfiguration? drmConfiguration,
    bool? hardwareAcceleration,
    bool? transparentBackground,
  }) {
    return WebViewSettings(
      javaScriptEnabled: javaScriptEnabled ?? this.javaScriptEnabled,
      domStorageEnabled: domStorageEnabled ?? this.domStorageEnabled,
      databaseEnabled: databaseEnabled ?? this.databaseEnabled,
      userAgent: userAgent ?? this.userAgent,
      supportZoom: supportZoom ?? this.supportZoom,
      mediaPlaybackRequiresUserGesture:
          mediaPlaybackRequiresUserGesture ?? this.mediaPlaybackRequiresUserGesture,
      cacheEnabled: cacheEnabled ?? this.cacheEnabled,
      cacheMode: cacheMode ?? this.cacheMode,
      allowFileAccess: allowFileAccess ?? this.allowFileAccess,
      allowContentAccess: allowContentAccess ?? this.allowContentAccess,
      allowFileAccessFromFileURLs:
          allowFileAccessFromFileURLs ?? this.allowFileAccessFromFileURLs,
      allowUniversalAccessFromFileURLs:
          allowUniversalAccessFromFileURLs ?? this.allowUniversalAccessFromFileURLs,
      mixedContentMode: mixedContentMode ?? this.mixedContentMode,
      safeBrowsingEnabled: safeBrowsingEnabled ?? this.safeBrowsingEnabled,
      textZoom: textZoom ?? this.textZoom,
      minimumFontSize: minimumFontSize ?? this.minimumFontSize,
      useWideViewPort: useWideViewPort ?? this.useWideViewPort,
      loadWithOverviewMode: loadWithOverviewMode ?? this.loadWithOverviewMode,
      builtInZoomControls: builtInZoomControls ?? this.builtInZoomControls,
      displayZoomControls: displayZoomControls ?? this.displayZoomControls,
      drmConfiguration: drmConfiguration ?? this.drmConfiguration,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
      transparentBackground: transparentBackground ?? this.transparentBackground,
    );
  }
}

/// Cache mode for WebView
enum CacheMode {
  loadDefault,
  loadCacheElseNetwork,
  loadNoCache,
  loadCacheOnly,
}

/// Mixed content mode
enum MixedContentMode {
  mixedContentAlwaysAllow,
  mixedContentCompatibilityMode,
  mixedContentNeverAllow,
}
