import 'dart:async';
import 'package:flutter/services.dart';
import 'models/webview_settings.dart';
import 'models/user_script.dart';
import 'models/download_request.dart';
import 'models/navigation_action.dart';
import 'models/permission_request.dart';
import 'cookie_manager/cookie_manager.dart';

/// Controller for managing WebView instances
class RealWebViewController {
  final int viewId;
  final MethodChannel _channel;

  RealWebViewController._(this.viewId)
      : _channel = MethodChannel('real_webview_$viewId');

  static Future<RealWebViewController> create(int viewId) async {
    final controller = RealWebViewController._(viewId);
    await controller._initialize();
    return controller;
  }

  Future<void> _initialize() async {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onUrlChanged':
        _onUrlChangedController.add(call.arguments as String);
        break;
      case 'onProgressChanged':
        _onProgressChangedController.add(call.arguments as int);
        break;
      case 'onLoadStop':
        _onLoadStopController.add(call.arguments as String);
        break;
      case 'onLoadStart':
        _onLoadStartController.add(call.arguments as String);
        break;
      case 'onLoadError':
        _onLoadErrorController.add(
          WebViewError.fromMap(Map<String, dynamic>.from(call.arguments)),
        );
        break;
      case 'onConsoleMessage':
        _onConsoleMessageController.add(
          ConsoleMessage.fromMap(Map<String, dynamic>.from(call.arguments)),
        );
        break;
      case 'onDownloadStart':
        _onDownloadStartController.add(
          DownloadRequest.fromMap(Map<String, dynamic>.from(call.arguments)),
        );
        break;
      case 'onPermissionRequest':
        _onPermissionRequestController.add(
          PermissionRequest.fromMap(Map<String, dynamic>.from(call.arguments)),
        );
        break;
      case 'shouldOverrideUrlLoading':
        if (_shouldOverrideUrlLoading != null) {
          final action = NavigationAction.fromMap(
            Map<String, dynamic>.from(call.arguments),
          );
          final policy = await _shouldOverrideUrlLoading!(action);
          return policy.index;
        }
        return NavigationActionPolicy.allow.index;
    }
  }

  final _onUrlChangedController = StreamController<String>.broadcast();
  final _onProgressChangedController = StreamController<int>.broadcast();
  final _onLoadStopController = StreamController<String>.broadcast();
  final _onLoadStartController = StreamController<String>.broadcast();
  final _onLoadErrorController = StreamController<WebViewError>.broadcast();
  final _onConsoleMessageController =
      StreamController<ConsoleMessage>.broadcast();
  final _onDownloadStartController =
      StreamController<DownloadRequest>.broadcast();
  final _onPermissionRequestController =
      StreamController<PermissionRequest>.broadcast();

  // Callbacks for synchronous decisions
  Future<NavigationActionPolicy> Function(NavigationAction)?
      _shouldOverrideUrlLoading;

  /// Stream of URL changes
  Stream<String> get onUrlChanged => _onUrlChangedController.stream;

  /// Stream of page load progress (0-100)
  Stream<int> get onProgressChanged => _onProgressChangedController.stream;

  /// Stream of page load finished events
  Stream<String> get onLoadStop => _onLoadStopController.stream;

  /// Stream of page load started events
  Stream<String> get onLoadStart => _onLoadStartController.stream;

  /// Stream of page load error events
  Stream<WebViewError> get onLoadError => _onLoadErrorController.stream;

  /// Stream of console messages from web page
  Stream<ConsoleMessage> get onConsoleMessage =>
      _onConsoleMessageController.stream;

  /// Stream of download start events
  Stream<DownloadRequest> get onDownloadStart =>
      _onDownloadStartController.stream;

  /// Stream of permission request events
  Stream<PermissionRequest> get onPermissionRequest =>
      _onPermissionRequestController.stream;

  /// Load a URL in the WebView
  Future<void> loadUrl({
    required String url,
    Map<String, String>? headers,
  }) async {
    await _channel.invokeMethod('loadUrl', {
      'url': url,
      'headers': headers,
    });
  }

  /// Load HTML content
  Future<void> loadData({
    required String data,
    String mimeType = 'text/html',
    String encoding = 'utf-8',
    String? baseUrl,
  }) async {
    await _channel.invokeMethod('loadData', {
      'data': data,
      'mimeType': mimeType,
      'encoding': encoding,
      'baseUrl': baseUrl,
    });
  }

  /// Reload the current page
  Future<void> reload() async {
    await _channel.invokeMethod('reload');
  }

  /// Go back in history
  Future<void> goBack() async {
    await _channel.invokeMethod('goBack');
  }

  /// Go forward in history
  Future<void> goForward() async {
    await _channel.invokeMethod('goForward');
  }

  /// Check if can go back
  Future<bool> canGoBack() async {
    final result = await _channel.invokeMethod<bool>('canGoBack');
    return result ?? false;
  }

  /// Check if can go forward
  Future<bool> canGoForward() async {
    final result = await _channel.invokeMethod<bool>('canGoForward');
    return result ?? false;
  }

  /// Get current URL
  Future<String?> getUrl() async {
    return await _channel.invokeMethod<String>('getUrl');
  }

  /// Get page title
  Future<String?> getTitle() async {
    return await _channel.invokeMethod<String>('getTitle');
  }

  /// Execute JavaScript code
  Future<dynamic> evaluateJavascript({required String source}) async {
    return await _channel.invokeMethod('evaluateJavascript', {
      'source': source,
    });
  }

  /// Inject JavaScript code
  Future<void> injectJavascriptFileFromUrl({required String urlFile}) async {
    await _channel.invokeMethod('injectJavascriptFileFromUrl', {
      'urlFile': urlFile,
    });
  }

  /// Add JavaScript handler
  Future<void> addJavaScriptHandler({
    required String handlerName,
    required Function(List<dynamic> arguments) callback,
  }) async {
    await _channel.invokeMethod('addJavaScriptHandler', {
      'handlerName': handlerName,
    });

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onJavaScriptHandlerCallback_$handlerName') {
        callback(call.arguments as List<dynamic>);
      }
      return _handleMethodCall(call);
    });
  }

  /// Remove JavaScript handler
  Future<void> removeJavaScriptHandler({required String handlerName}) async {
    await _channel.invokeMethod('removeJavaScriptHandler', {
      'handlerName': handlerName,
    });
  }

  /// Stop loading
  Future<void> stopLoading() async {
    await _channel.invokeMethod('stopLoading');
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _channel.invokeMethod('clearCache');
  }

  /// Clear cookies for this WebView
  Future<void> clearCookies() async {
    final url = await getUrl();
    if (url != null) {
      await CookieManager.instance().deleteCookies(url: url);
    }
  }

  /// Clear history
  Future<void> clearHistory() async {
    await _channel.invokeMethod('clearHistory');
  }

  /// Take screenshot
  Future<Uint8List?> takeScreenshot() async {
    return await _channel.invokeMethod<Uint8List>('takeScreenshot');
  }

  /// Get WebView settings
  Future<WebViewSettings?> getSettings() async {
    final Map<dynamic, dynamic>? result =
        await _channel.invokeMethod('getSettings');
    if (result == null) return null;
    return WebViewSettings.fromMap(Map<String, dynamic>.from(result));
  }

  /// Set WebView settings
  Future<void> setSettings(WebViewSettings settings) async {
    await _channel.invokeMethod('setSettings', settings.toMap());
  }

  /// Zoom in
  Future<void> zoomIn() async {
    await _channel.invokeMethod('zoomIn');
  }

  /// Zoom out
  Future<void> zoomOut() async {
    await _channel.invokeMethod('zoomOut');
  }

  /// Set zoom scale
  Future<void> setZoomScale(double scale) async {
    await _channel.invokeMethod('setZoomScale', {'scale': scale});
  }

  /// Get zoom scale
  Future<double> getZoomScale() async {
    final result = await _channel.invokeMethod<double>('getZoomScale');
    return result ?? 1.0;
  }

  /// Add user script for injection
  Future<void> addUserScript(UserScript userScript) async {
    await _channel.invokeMethod('addUserScript', userScript.toMap());
  }

  /// Remove user script by group name
  Future<void> removeUserScriptsByGroupName(String groupName) async {
    await _channel.invokeMethod('removeUserScriptsByGroupName', {
      'groupName': groupName,
    });
  }

  /// Remove all user scripts
  Future<void> removeAllUserScripts() async {
    await _channel.invokeMethod('removeAllUserScripts');
  }

  /// Set callback for URL loading decisions
  void setShouldOverrideUrlLoading(
    Future<NavigationActionPolicy> Function(NavigationAction) callback,
  ) {
    _shouldOverrideUrlLoading = callback;
  }

  /// Respond to permission request
  Future<void> respondToPermissionRequest(
    String requestId,
    PermissionResponse response,
  ) async {
    await _channel.invokeMethod('respondToPermissionRequest', {
      'requestId': requestId,
      'response': response.index,
    });
  }

  /// Enable/disable pull-to-refresh
  Future<void> setPullToRefreshEnabled(bool enabled) async {
    await _channel.invokeMethod('setPullToRefreshEnabled', enabled);
  }

  /// Dispose the controller
  void dispose() {
    _onUrlChangedController.close();
    _onProgressChangedController.close();
    _onLoadStopController.close();
    _onLoadStartController.close();
    _onLoadErrorController.close();
    _onConsoleMessageController.close();
    _onDownloadStartController.close();
    _onPermissionRequestController.close();
  }
}

/// WebView error information
class WebViewError {
  final int code;
  final String description;
  final String? url;

  WebViewError({
    required this.code,
    required this.description,
    this.url,
  });

  factory WebViewError.fromMap(Map<String, dynamic> map) {
    return WebViewError(
      code: map['code'] as int,
      description: map['description'] as String,
      url: map['url'] as String?,
    );
  }

  @override
  String toString() {
    return 'WebViewError{code: $code, description: $description, url: $url}';
  }
}

/// Console message from web page
class ConsoleMessage {
  final String message;
  final ConsoleMessageLevel level;
  final String? sourceId;
  final int? lineNumber;

  ConsoleMessage({
    required this.message,
    required this.level,
    this.sourceId,
    this.lineNumber,
  });

  factory ConsoleMessage.fromMap(Map<String, dynamic> map) {
    return ConsoleMessage(
      message: map['message'] as String,
      level: ConsoleMessageLevel.values[map['level'] as int? ?? 0],
      sourceId: map['sourceId'] as String?,
      lineNumber: map['lineNumber'] as int?,
    );
  }

  @override
  String toString() {
    return 'ConsoleMessage{message: $message, level: $level, sourceId: $sourceId, lineNumber: $lineNumber}';
  }
}

/// Console message level
enum ConsoleMessageLevel {
  log,
  debug,
  info,
  warning,
  error,
}
