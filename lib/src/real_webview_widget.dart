import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'models/webview_settings.dart';
import 'real_webview_controller.dart';

/// WebView widget for displaying web content using Chrome/Chromium engine
class RealWebView extends StatefulWidget {
  /// Initial URL to load
  final String? initialUrl;

  /// Initial data to load
  final String? initialData;

  /// Initial settings for the WebView
  final WebViewSettings? initialSettings;

  /// Callback when WebView is created
  final void Function(RealWebViewController controller)? onWebViewCreated;

  /// Callback when URL changes
  final void Function(RealWebViewController controller, String url)?
      onUrlChanged;

  /// Callback when page starts loading
  final void Function(RealWebViewController controller, String url)?
      onLoadStart;

  /// Callback when page finishes loading
  final void Function(RealWebViewController controller, String url)? onLoadStop;

  /// Callback when page load progress changes
  final void Function(RealWebViewController controller, int progress)?
      onProgressChanged;

  /// Callback when page load error occurs
  final void Function(
          RealWebViewController controller, WebViewError error)?
      onLoadError;

  /// Callback when console message is received
  final void Function(
          RealWebViewController controller, ConsoleMessage message)?
      onConsoleMessage;

  /// Gesture recognizers
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  const RealWebView({
    super.key,
    this.initialUrl,
    this.initialData,
    this.initialSettings,
    this.onWebViewCreated,
    this.onUrlChanged,
    this.onLoadStart,
    this.onLoadStop,
    this.onProgressChanged,
    this.onLoadError,
    this.onConsoleMessage,
    this.gestureRecognizers,
  });

  @override
  State<RealWebView> createState() => _RealWebViewState();
}

class _RealWebViewState extends State<RealWebView> {
  RealWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    // Platform-specific view
    final Map<String, dynamic> creationParams = {
      'initialUrl': widget.initialUrl,
      'initialData': widget.initialData,
      'initialSettings': widget.initialSettings?.toMap(),
    };

    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformViewLink(
        viewType: 'real_webview',
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: widget.gestureRecognizers ??
                const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (params) {
          return PlatformViewsService.initAndroidView(
            id: params.id,
            viewType: 'real_webview',
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () {
              params.onFocusChanged(true);
            },
          )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..addOnPlatformViewCreatedListener(_onPlatformViewCreated)
            ..create();
        },
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'real_webview',
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: widget.gestureRecognizers,
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      // For desktop platforms, we'll use a placeholder for now
      // In production, you'd implement platform-specific views
      return Container(
        color: Colors.white,
        child: const Center(
          child: Text('WebView not yet implemented for this platform'),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: const Center(
        child: Text('WebView not supported on this platform'),
      ),
    );
  }

  Future<void> _onPlatformViewCreated(int id) async {
    final controller = await RealWebViewController.create(id);
    _controller = controller;

    // Set up event listeners
    if (widget.onUrlChanged != null) {
      controller.onUrlChanged.listen((url) {
        widget.onUrlChanged?.call(controller, url);
      });
    }

    if (widget.onLoadStart != null) {
      controller.onLoadStart.listen((url) {
        widget.onLoadStart?.call(controller, url);
      });
    }

    if (widget.onLoadStop != null) {
      controller.onLoadStop.listen((url) {
        widget.onLoadStop?.call(controller, url);
      });
    }

    if (widget.onProgressChanged != null) {
      controller.onProgressChanged.listen((progress) {
        widget.onProgressChanged?.call(controller, progress);
      });
    }

    if (widget.onLoadError != null) {
      controller.onLoadError.listen((error) {
        widget.onLoadError?.call(controller, error);
      });
    }

    if (widget.onConsoleMessage != null) {
      controller.onConsoleMessage.listen((message) {
        widget.onConsoleMessage?.call(controller, message);
      });
    }

    // Notify that WebView is created
    widget.onWebViewCreated?.call(controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
