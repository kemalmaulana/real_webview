import 'package:flutter_test/flutter_test.dart';
import 'package:real_webview/real_webview.dart';

void main() {
  test('Cookie model serialization', () {
    final cookie = Cookie(
      name: 'test',
      value: 'value',
      domain: '.example.com',
      path: '/',
      isSecure: true,
      isHttpOnly: false,
      sameSite: CookieSameSitePolicy.lax,
    );

    final map = cookie.toMap();
    expect(map['name'], 'test');
    expect(map['value'], 'value');
    expect(map['domain'], '.example.com');

    final cookie2 = Cookie.fromMap(map);
    expect(cookie2.name, cookie.name);
    expect(cookie2.value, cookie.value);
  });

  test('DRM configuration creation', () {
    final widevine = DRMConfiguration.widevine(
      licenseServerUrl: 'https://test.com',
    );
    expect(widevine.scheme, DRMSchemeType.widevine);

    final fairplay = DRMConfiguration.fairplay(
      licenseServerUrl: 'https://test.com',
      certificateUrl: 'https://cert.com',
    );
    expect(fairplay.scheme, DRMSchemeType.fairplay);
  });

  test('Auto DRM handler presets', () {
    final netflix = AutoDRMHandler.getPreset('netflix');
    expect(netflix, isNotNull);
    expect(netflix!.scheme, DRMSchemeType.widevine);

    final appletv = AutoDRMHandler.getPreset('appletv');
    expect(appletv, isNotNull);
    expect(appletv!.scheme, DRMSchemeType.fairplay);
  });

  test('WebView settings', () {
    final settings = WebViewSettings(
      javaScriptEnabled: true,
      domStorageEnabled: false,
    );

    expect(settings.javaScriptEnabled, true);
    expect(settings.domStorageEnabled, false);

    final map = settings.toMap();
    expect(map['javaScriptEnabled'], true);
  });
}
