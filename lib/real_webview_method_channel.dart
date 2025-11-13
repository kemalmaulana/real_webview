import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'real_webview_platform_interface.dart';

/// An implementation of [RealWebviewPlatform] that uses method channels.
class MethodChannelRealWebview extends RealWebviewPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('real_webview');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
