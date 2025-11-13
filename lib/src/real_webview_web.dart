// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'models/webview_settings.dart';

/// Web implementation of RealWebView using IFrame
class RealWebViewWeb extends StatefulWidget {
  final String? initialUrl;
  final String? initialData;
  final WebViewSettings? initialSettings;
  final void Function(dynamic controller)? onWebViewCreated;
  final void Function(dynamic controller, String url)? onUrlChanged;
  final void Function(dynamic controller, String url)? onLoadStart;
  final void Function(dynamic controller, String url)? onLoadStop;
  final void Function(dynamic controller, int progress)? onProgressChanged;

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
  State<RealWebViewWeb> createState() => _RealWebViewWebState();
}

class _RealWebViewWebState extends State<RealWebViewWeb> {
  late html.IFrameElement _iframeElement;
  final String _viewType = 'real-webview-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _createIFrame();
  }

  void _createIFrame() {
    _iframeElement = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';

    // Set initial URL or data
    if (widget.initialData != null) {
      final blob = html.Blob([widget.initialData!], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      _iframeElement.src = url;
    } else if (widget.initialUrl != null) {
      _iframeElement.src = widget.initialUrl!;
    }

    // Apply settings
    if (widget.initialSettings != null) {
      final settings = widget.initialSettings!;

      // Set sandbox permissions
      final sandboxPerms = <String>[];
      if (settings.javaScriptEnabled) sandboxPerms.add('allow-scripts');
      if (settings.allowFileAccess) sandboxPerms.add('allow-same-origin');
      sandboxPerms.addAll([
        'allow-forms',
        'allow-popups',
        'allow-pointer-lock',
        'allow-top-navigation',
      ]);
      _iframeElement.setAttribute('sandbox', sandboxPerms.join(' '));

      // Enable fullscreen for DRM content
      _iframeElement.setAttribute('allowfullscreen', 'true');
      _iframeElement.setAttribute('allow', 'autoplay; fullscreen; encrypted-media');
    }

    // Register the iframe as a platform view
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframeElement,
    );

    // Set up event listeners
    _setupEventListeners();

    // Notify that webview is created (pass null for web)
    widget.onWebViewCreated?.call(null);
  }

  void _setupEventListeners() {
    // Listen for load events
    _iframeElement.onLoad.listen((event) {
      final url = _iframeElement.src ?? '';
      widget.onLoadStop?.call(null, url);
      widget.onProgressChanged?.call(null, 100);
    });

    // Note: onLoadStart is not available on IFrameElement
    // Web platform has limited iframe access due to security
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: _viewType,
    );
  }
}
