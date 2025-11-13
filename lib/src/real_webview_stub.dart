import 'package:flutter/material.dart';
import 'real_webview_controller.dart';
import 'models/webview_settings.dart';

/// Stub for non-web platforms
class RealWebViewWeb extends StatelessWidget {
  final String? initialUrl;
  final String? initialData;
  final WebViewSettings? initialSettings;
  final void Function(RealWebViewController controller)? onWebViewCreated;
  final void Function(RealWebViewController controller, String url)? onUrlChanged;
  final void Function(RealWebViewController controller, String url)? onLoadStart;
  final void Function(RealWebViewController controller, String url)? onLoadStop;
  final void Function(RealWebViewController controller, int progress)? onProgressChanged;

  const RealWebViewWeb({
    super.key,
    this.initialUrl,
    this.initialData,
    this.initialSettings,
    this.onWebViewCreated,
    this.onUrlChanged,
    this.onLoadStart,
    this.onLoadStop,
    this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Web implementation only available on web platform'),
    );
  }
}
