/// DRM (Digital Rights Management) configuration for protected content playback
class DRMConfiguration {
  /// License server URL
  final String? licenseServerUrl;

  /// DRM scheme type
  final DRMSchemeType scheme;

  /// Additional headers for license requests
  final Map<String, String>? headers;

  /// Certificate URL for FairPlay
  final String? certificateUrl;

  /// Whether to allow cross-origin resource sharing
  final bool allowCrossOrigin;

  /// Custom license request modifier
  final Map<String, dynamic>? customData;

  DRMConfiguration({
    this.licenseServerUrl,
    required this.scheme,
    this.headers,
    this.certificateUrl,
    this.allowCrossOrigin = true,
    this.customData,
  });

  Map<String, dynamic> toMap() {
    return {
      'licenseServerUrl': licenseServerUrl,
      'scheme': scheme.name,
      'headers': headers,
      'certificateUrl': certificateUrl,
      'allowCrossOrigin': allowCrossOrigin,
      'customData': customData,
    };
  }

  factory DRMConfiguration.fromMap(Map<String, dynamic> map) {
    return DRMConfiguration(
      licenseServerUrl: map['licenseServerUrl'] as String?,
      scheme: DRMSchemeType.values.firstWhere(
        (e) => e.name == map['scheme'],
        orElse: () => DRMSchemeType.widevine,
      ),
      headers: map['headers'] != null
          ? Map<String, String>.from(map['headers'] as Map)
          : null,
      certificateUrl: map['certificateUrl'] as String?,
      allowCrossOrigin: map['allowCrossOrigin'] as bool? ?? true,
      customData: map['customData'] as Map<String, dynamic>?,
    );
  }

  /// Create Widevine DRM configuration
  factory DRMConfiguration.widevine({
    required String licenseServerUrl,
    Map<String, String>? headers,
    Map<String, dynamic>? customData,
  }) {
    return DRMConfiguration(
      scheme: DRMSchemeType.widevine,
      licenseServerUrl: licenseServerUrl,
      headers: headers,
      customData: customData,
    );
  }

  /// Create FairPlay DRM configuration
  factory DRMConfiguration.fairplay({
    required String licenseServerUrl,
    required String certificateUrl,
    Map<String, String>? headers,
    Map<String, dynamic>? customData,
  }) {
    return DRMConfiguration(
      scheme: DRMSchemeType.fairplay,
      licenseServerUrl: licenseServerUrl,
      certificateUrl: certificateUrl,
      headers: headers,
      customData: customData,
    );
  }

  /// Create PlayReady DRM configuration
  factory DRMConfiguration.playready({
    required String licenseServerUrl,
    Map<String, String>? headers,
    Map<String, dynamic>? customData,
  }) {
    return DRMConfiguration(
      scheme: DRMSchemeType.playready,
      licenseServerUrl: licenseServerUrl,
      headers: headers,
      customData: customData,
    );
  }

  /// Create ClearKey DRM configuration
  factory DRMConfiguration.clearkey({
    required Map<String, dynamic> keys,
  }) {
    return DRMConfiguration(
      scheme: DRMSchemeType.clearkey,
      customData: {'keys': keys},
    );
  }

  @override
  String toString() {
    return 'DRMConfiguration{scheme: $scheme, licenseServerUrl: $licenseServerUrl}';
  }
}

/// DRM Scheme Types
enum DRMSchemeType {
  /// Google Widevine (Android, Web)
  widevine,

  /// Apple FairPlay (iOS, macOS)
  fairplay,

  /// Microsoft PlayReady (Windows, Xbox)
  playready,

  /// ClearKey (All platforms)
  clearkey,
}
