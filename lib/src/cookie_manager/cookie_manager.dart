import 'package:flutter/services.dart';
import '../models/cookie.dart';

/// Cookie manager for managing cookies across WebView instances
class CookieManager {
  static const MethodChannel _channel =
      MethodChannel('real_webview/cookie_manager');

  static CookieManager? _instance;

  /// Get the singleton instance of CookieManager
  static CookieManager instance() {
    _instance ??= CookieManager._();
    return _instance!;
  }

  CookieManager._();

  /// Set a cookie for a specific URL
  Future<void> setCookie({
    required String url,
    required Cookie cookie,
  }) async {
    await _channel.invokeMethod('setCookie', {
      'url': url,
      'cookie': cookie.toMap(),
    });
  }

  /// Set multiple cookies for a specific URL
  Future<void> setCookies({
    required String url,
    required List<Cookie> cookies,
  }) async {
    await _channel.invokeMethod('setCookies', {
      'url': url,
      'cookies': cookies.map((c) => c.toMap()).toList(),
    });
  }

  /// Get all cookies for a specific URL
  Future<List<Cookie>> getCookies({required String url}) async {
    final List<dynamic>? result = await _channel.invokeMethod('getCookies', {
      'url': url,
    });

    if (result == null) return [];

    return result
        .map((item) => Cookie.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Get a specific cookie by name for a URL
  Future<Cookie?> getCookie({
    required String url,
    required String name,
  }) async {
    final Map<dynamic, dynamic>? result =
        await _channel.invokeMethod('getCookie', {
      'url': url,
      'name': name,
    });

    if (result == null) return null;

    return Cookie.fromMap(Map<String, dynamic>.from(result));
  }

  /// Delete a specific cookie for a URL
  Future<void> deleteCookie({
    required String url,
    required String name,
  }) async {
    await _channel.invokeMethod('deleteCookie', {
      'url': url,
      'name': name,
    });
  }

  /// Delete all cookies for a specific URL
  Future<void> deleteCookies({required String url}) async {
    await _channel.invokeMethod('deleteCookies', {
      'url': url,
    });
  }

  /// Delete all cookies from all domains
  Future<void> deleteAllCookies() async {
    await _channel.invokeMethod('deleteAllCookies');
  }

  /// Get all cookies from all domains
  Future<List<Cookie>> getAllCookies() async {
    final List<dynamic>? result =
        await _channel.invokeMethod('getAllCookies');

    if (result == null) return [];

    return result
        .map((item) => Cookie.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Flush cookies to storage
  /// This ensures cookies are persisted immediately
  Future<void> flush() async {
    await _channel.invokeMethod('flush');
  }

  /// Check if cookies are enabled
  Future<bool> hasCookies() async {
    final bool? result = await _channel.invokeMethod('hasCookies');
    return result ?? false;
  }
}
