// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:real_webview/real_webview.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RealWebView widget test', (WidgetTester tester) async {
    RealWebViewController? controller;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RealWebView(
            initialUrl: 'https://flutter.dev',
            onWebViewCreated: (c) {
              controller = c;
            },
          ),
        ),
      ),
    );

    // Wait for the widget to be built
    await tester.pumpAndSettle();

    // Verify the controller was created
    expect(controller, isNotNull);
  });

  testWidgets('Cookie manager test', (WidgetTester tester) async {
    final cookieManager = CookieManager.instance();

    // Test setting a cookie
    await cookieManager.setCookie(
      url: 'https://flutter.dev',
      cookie: Cookie(
        name: 'test_cookie',
        value: 'test_value',
      ),
    );

    // Verify singleton instance
    expect(CookieManager.instance(), same(cookieManager));
  });
}
