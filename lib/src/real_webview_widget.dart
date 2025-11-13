import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'models/webview_settings.dart';
import 'models/download_request.dart';
import 'models/navigation_action.dart';
import 'models/permission_request.dart';
import 'real_webview_controller.dart';
import 'pull_to_refresh_controller.dart';

// Conditional import for web
import 'real_webview_web.dart' if (dart.library.io) 'real_webview_stub.dart' as web_impl;

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

  /// Callback when download starts
  final void Function(
          RealWebViewController controller, DownloadRequest request)?
      onDownloadStart;

  /// Callback for URL loading decisions
  final Future<NavigationActionPolicy> Function(
          RealWebViewController controller, NavigationAction action)?
      shouldOverrideUrlLoading;

  /// Callback when permission is requested
  final void Function(
          RealWebViewController controller, PermissionRequest request)?
      onPermissionRequest;

  /// Pull-to-refresh controller
  final PullToRefreshController? pullToRefreshController;

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
    this.onDownloadStart,
    this.shouldOverrideUrlLoading,
    this.onPermissionRequest,
    this.pullToRefreshController,
    this.gestureRecognizers,
  });

  @override
  State<RealWebView> createState() => _RealWebViewState();
}

class _RealWebViewState extends State<RealWebView> {
  RealWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    // Handle web platform separately
    if (kIsWeb) {
      return web_impl.RealWebViewWeb(
        initialUrl: widget.initialUrl,
        initialData: widget.initialData,
        initialSettings: widget.initialSettings,
        onWebViewCreated: widget.onWebViewCreated != null
            ? (controller) => widget.onWebViewCreated!(controller as RealWebViewController)
            : null,
        onUrlChanged: widget.onUrlChanged != null
            ? (controller, url) =>
                widget.onUrlChanged!(controller as RealWebViewController, url)
            : null,
        onLoadStart: widget.onLoadStart != null
            ? (controller, url) =>
                widget.onLoadStart!(controller as RealWebViewController, url)
            : null,
        onLoadStop: widget.onLoadStop != null
            ? (controller, url) =>
                widget.onLoadStop!(controller as RealWebViewController, url)
            : null,
        onProgressChanged: widget.onProgressChanged != null
            ? (controller, progress) =>
                widget.onProgressChanged!(controller as RealWebViewController, progress)
            : null,
      );
    }

    // Platform-specific view for mobile and desktop
    final Map<String, dynamic> creationParams = {
      'initialUrl': widget.initialUrl,
      'initialData': widget.initialData,
      'initialSettings': widget.initialSettings?.toMap(),
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
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

      case TargetPlatform.iOS:
        return UiKitView(
          viewType: 'real_webview',
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          gestureRecognizers: widget.gestureRecognizers,
          onPlatformViewCreated: _onPlatformViewCreated,
        );

      case TargetPlatform.macOS:
        // macOS uses AppKit views
        return AppKitView(
          viewType: 'real_webview',
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        );

      case TargetPlatform.windows:
        // Windows uses native views
        return _buildWindowsWebView(creationParams);

      case TargetPlatform.linux:
        // Linux uses native views
        return _buildLinuxWebView(creationParams);

      default:
        return _buildUnsupportedPlatform();
    }
  }

  Widget _buildWindowsWebView(Map<String, dynamic> creationParams) {
    // Windows WebView2 implementation
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
        return PlatformViewsService.initExpensiveAndroidView(
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
  }

  Widget _buildLinuxWebView(Map<String, dynamic> creationParams) {
    // Linux WebKitGTK implementation
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
        return PlatformViewsService.initExpensiveAndroidView(
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
  }

  Widget _buildUnsupportedPlatform() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'WebView not supported on this platform',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Current platform: ${defaultTargetPlatform.name}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
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

    if (widget.onDownloadStart != null) {
      controller.onDownloadStart.listen((request) {
        widget.onDownloadStart?.call(controller, request);
      });
    }

    if (widget.onPermissionRequest != null) {
      controller.onPermissionRequest.listen((request) {
        widget.onPermissionRequest?.call(controller, request);
      });
    }

    if (widget.shouldOverrideUrlLoading != null) {
      controller.setShouldOverrideUrlLoading((action) async {
        return await widget.shouldOverrideUrlLoading!(controller, action);
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
