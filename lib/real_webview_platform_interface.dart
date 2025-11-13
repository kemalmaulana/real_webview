import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'real_webview_method_channel.dart';

abstract class RealWebviewPlatform extends PlatformInterface {
  /// Constructs a RealWebviewPlatform.
  RealWebviewPlatform() : super(token: _token);

  static final Object _token = Object();

  static RealWebviewPlatform _instance = MethodChannelRealWebview();

  /// The default instance of [RealWebviewPlatform] to use.
  ///
  /// Defaults to [MethodChannelRealWebview].
  static RealWebviewPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RealWebviewPlatform] when
  /// they register themselves.
  static set instance(RealWebviewPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
