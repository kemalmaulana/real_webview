import '../models/drm_configuration.dart';

/// Automatic DRM handler that detects and configures DRM like Chrome does
class AutoDRMHandler {
  /// Automatically detect DRM scheme from initialization data
  static DRMSchemeType detectDRMScheme(String initDataType) {
    switch (initDataType.toLowerCase()) {
      case 'cenc':
      case 'webm':
        // CENC can be Widevine or PlayReady
        return DRMSchemeType.widevine;
      case 'fairplay':
      case 'skd':
        return DRMSchemeType.fairplay;
      case 'playready':
        return DRMSchemeType.playready;
      case 'clearkey':
        return DRMSchemeType.clearkey;
      default:
        return DRMSchemeType.widevine; // Default to Widevine
    }
  }

  /// Create automatic DRM configuration without manual license server
  /// This enables Chrome-like automatic DRM handling
  static DRMConfiguration createAutoDRM({
    DRMSchemeType? preferredScheme,
    Map<String, String>? customHeaders,
  }) {
    return DRMConfiguration(
      scheme: preferredScheme ?? DRMSchemeType.widevine,
      headers: customHeaders,
      allowCrossOrigin: true,
      // No license server URL - will be auto-detected from media
      customData: {
        'autoDetect': true,
        'enableEME': true, // Enable Encrypted Media Extensions
        'enableMSE': true, // Enable Media Source Extensions
      },
    );
  }

  /// Configuration for popular streaming services
  static Map<String, DRMConfiguration> getPresetConfigurations() {
    return {
      // Netflix-compatible configuration
      'netflix': DRMConfiguration(
        scheme: DRMSchemeType.widevine,
        allowCrossOrigin: true,
        customData: {
          'autoDetect': true,
          'enableEME': true,
          'robustnessLevel': 'SW_SECURE_CRYPTO',
        },
      ),

      // Disney+ compatible configuration
      'disneyplus': DRMConfiguration(
        scheme: DRMSchemeType.widevine,
        allowCrossOrigin: true,
        customData: {
          'autoDetect': true,
          'enableEME': true,
          'robustnessLevel': 'SW_SECURE_CRYPTO',
        },
      ),

      // Amazon Prime compatible configuration
      'prime': DRMConfiguration(
        scheme: DRMSchemeType.widevine,
        allowCrossOrigin: true,
        customData: {
          'autoDetect': true,
          'enableEME': true,
          'robustnessLevel': 'SW_SECURE_CRYPTO',
        },
      ),

      // Apple TV+ (FairPlay)
      'appletv': DRMConfiguration(
        scheme: DRMSchemeType.fairplay,
        allowCrossOrigin: true,
        customData: {
          'autoDetect': true,
          'enableEME': true,
        },
      ),

      // Generic HLS with FairPlay
      'hls-fairplay': DRMConfiguration(
        scheme: DRMSchemeType.fairplay,
        allowCrossOrigin: true,
        customData: {
          'autoDetect': true,
          'enableEME': true,
        },
      ),

      // Generic DASH with Widevine
      'dash-widevine': DRMConfiguration(
        scheme: DRMSchemeType.widevine,
        allowCrossOrigin: true,
        customData: {
          'autoDetect': true,
          'enableEME': true,
          'robustnessLevel': 'SW_SECURE_CRYPTO',
        },
      ),
    };
  }

  /// Get preset configuration by name
  static DRMConfiguration? getPreset(String presetName) {
    return getPresetConfigurations()[presetName.toLowerCase()];
  }
}
