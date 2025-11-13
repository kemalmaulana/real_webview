import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:real_webview/real_webview.dart';

/// Complete migration example showing how to replicate legacy flutter_inappwebview
/// functionality with real_webview.
///
/// This example demonstrates:
/// - Cookie injection from JSON
/// - Automatic DRM (replaces manual platform channels)
/// - User agent switching (Desktop/Mobile mode)
/// - Download handling
/// - Permission management
/// - Orientation handling
/// - Progress indicators
/// - Navigation controls
class LegacyMigrationExample extends StatefulWidget {
  /// URL to load
  final String url;

  /// JSON string containing cookies to inject
  /// Format: [{"name": "cookie1", "value": "val1", "domain": ".example.com", ...}]
  final String? cookies;

  /// Custom user agent (optional)
  final String? userAgent;

  /// Enable DRM support
  final bool enableDRM;

  const LegacyMigrationExample({
    super.key,
    required this.url,
    this.cookies,
    this.userAgent,
    this.enableDRM = true,
  });

  @override
  State<LegacyMigrationExample> createState() => _LegacyMigrationExampleState();
}

class _LegacyMigrationExampleState extends State<LegacyMigrationExample> {
  RealWebViewController? _controller;
  bool _isLoading = true;
  int _progress = 0;
  bool _isDesktopMode = false;
  String? _currentUrl;
  bool _canGoBack = false;
  bool _canGoForward = false;

  // User agents matching legacy implementation
  static const String _userAgentMobile =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
  static const String _userAgentDesktop =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUrl ?? 'Loading...'),
        actions: [
          IconButton(
            icon: Icon(_isDesktopMode ? Icons.phone_android : Icons.computer),
            tooltip: _isDesktopMode ? 'Switch to Mobile' : 'Switch to Desktop',
            onPressed: _toggleUserAgent,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller?.reload(),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'clear_cache', child: Text('Clear Cache')),
              const PopupMenuItem(value: 'clear_cookies', child: Text('Clear Cookies')),
              const PopupMenuItem(value: 'screenshot', child: Text('Take Screenshot')),
              const PopupMenuItem(value: 'execute_js', child: Text('Execute JavaScript')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress > 0 ? _progress / 100 : null,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),

          // WebView
          Expanded(
            child: RealWebView(
              initialUrl: widget.url,
              initialSettings: WebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
                userAgent: widget.userAgent ?? _userAgentMobile,

                // AUTOMATIC DRM - No platform channels needed!
                // Replaces: await platform.invokeMethod('enableWidevine')
                // Replaces: await platform.invokeMethod('enableFairPlay')
                drmConfiguration: widget.enableDRM
                    ? AutoDRMHandler.createAutoDRM()
                    : null,

                // Additional settings from legacy code
                supportZoom: true,
                builtInZoomControls: false,
                cacheMode: CacheMode.loadDefault,
                mixedContentMode: MixedContentMode.mixedContentAlwaysAllow,
              ),
              onWebViewCreated: (controller) async {
                _controller = controller;

                // Inject cookies from JSON (just like legacy code)
                await _setupCookiesFromJSON();

                // Set up JavaScript handlers for download interception
                await _setupDownloadHandlers();

                // Set up blob download handling
                await _setupBlobDownloadHandler();
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _isLoading = true;
                  _currentUrl = url;
                });
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  _isLoading = false;
                  _currentUrl = url;
                });

                // Update navigation state
                _canGoBack = await controller.canGoBack();
                _canGoForward = await controller.canGoForward();
                setState(() {});
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress;
                  _isLoading = progress < 100;
                });
              },
              onLoadError: (controller, error) {
                _showSnackBar('Error: ${error.description}', isError: true);
              },
              onConsoleMessage: (controller, message) {
                // Log console messages for debugging
                debugPrint('[WebView Console] ${message.level}: ${message.message}');

                // Log DRM-related messages
                if (message.message.contains('DRM') ||
                    message.message.contains('encrypted')) {
                  debugPrint('[DRM] ${message.message}');
                }
              },
            ),
          ),

          // Navigation bar (matches legacy bottom navigation)
          _buildNavigationBar(isLandscape),
        ],
      ),

      // Side drawer for landscape mode (matches legacy implementation)
      drawer: isLandscape ? _buildDrawer() : null,
    );
  }

  /// Set up cookies from JSON string (exactly like legacy code)
  Future<void> _setupCookiesFromJSON() async {
    if (widget.cookies == null || widget.cookies!.isEmpty) return;

    try {
      final cookieManager = CookieManager.instance();
      final decoded = jsonDecode(widget.cookies!);

      if (decoded is! List) {
        debugPrint('Invalid cookie format: expected List');
        return;
      }

      for (final entry in decoded) {
        if (entry is! Map) continue;

        final cookie = Map<String, dynamic>.from(entry);

        await cookieManager.setCookie(
          url: widget.url,
          cookie: Cookie(
            name: cookie['name'] ?? '',
            value: cookie['value'] ?? '',
            domain: cookie['domain'],
            path: cookie['path'] ?? '/',
            isHttpOnly: cookie['httpOnly'] ?? false,
            isSecure: cookie['secure'] ?? true,
            sameSite: _parseSameSite(cookie['sameSite']),
            expiresDate: cookie['expiresDate'],
          ),
        );
      }

      debugPrint('Injected ${decoded.length} cookies from JSON');
    } catch (e) {
      debugPrint('Error parsing cookies: $e');
    }
  }

  /// Parse SameSite policy from string
  CookieSameSitePolicy _parseSameSite(dynamic value) {
    if (value == null) return CookieSameSitePolicy.noRestriction;

    final str = value.toString().toLowerCase();
    if (str == 'lax') return CookieSameSitePolicy.lax;
    if (str == 'strict') return CookieSameSitePolicy.strict;
    return CookieSameSitePolicy.noRestriction;
  }

  /// Set up download handlers via JavaScript
  Future<void> _setupDownloadHandlers() async {
    // Add JavaScript handler for download notifications
    await _controller?.addJavaScriptHandler(
      handlerName: 'downloadHandler',
      callback: (args) {
        if (args.isNotEmpty) {
          final url = args[0].toString();
          _handleDownload(url);
        }
      },
    );

    // Inject download detection script
    await _controller?.evaluateJavascript(
      source: '''
        (function() {
          // Intercept clicks on download links
          document.addEventListener('click', function(e) {
            var target = e.target;
            while (target && target.tagName !== 'A') {
              target = target.parentElement;
            }

            if (target && target.download) {
              e.preventDefault();
              window.flutter_inappwebview.callHandler('downloadHandler', target.href);
            }
          }, true);
        })();
      ''',
    );
  }

  /// Set up blob download handler (matches legacy implementation)
  Future<void> _setupBlobDownloadHandler() async {
    await _controller?.evaluateJavascript(
      source: '''
        (function() {
          // Intercept blob downloads
          var originalCreateObjectURL = URL.createObjectURL;
          URL.createObjectURL = function(blob) {
            var url = originalCreateObjectURL.call(this, blob);

            if (blob instanceof Blob) {
              var reader = new FileReader();
              reader.onloadend = function() {
                var base64 = reader.result.split(',')[1];
                window.flutter_inappwebview.callHandler('blobDownloadHandler', {
                  data: base64,
                  type: blob.type,
                  size: blob.size
                });
              };
              reader.readAsDataURL(blob);
            }

            return url;
          };
        })();
      ''',
    );

    // Add blob download handler
    await _controller?.addJavaScriptHandler(
      handlerName: 'blobDownloadHandler',
      callback: (args) {
        if (args.isNotEmpty && args[0] is Map) {
          final data = args[0] as Map;
          _handleBlobDownload(
            data['data'] as String?,
            data['type'] as String?,
            data['size'] as int?,
          );
        }
      },
    );
  }

  /// Handle file download
  void _handleDownload(String url) {
    _showSnackBar('Download started: $url');
    // In production, implement actual download with Dio or other HTTP client
    // This matches the legacy code's download handling approach
  }

  /// Handle blob download
  void _handleBlobDownload(String? base64Data, String? mimeType, int? size) {
    if (base64Data == null) return;

    _showSnackBar('Blob download: ${mimeType ?? 'unknown'} (${size ?? 0} bytes)');
    // In production, decode base64 and save file
  }

  /// Toggle between desktop and mobile user agent
  Future<void> _toggleUserAgent() async {
    setState(() {
      _isDesktopMode = !_isDesktopMode;
    });

    final newUserAgent = _isDesktopMode ? _userAgentDesktop : _userAgentMobile;

    await _controller?.setSettings(
      WebViewSettings(
        userAgent: newUserAgent,
        javaScriptEnabled: true,
        domStorageEnabled: true,
      ),
    );

    await _controller?.reload();

    _showSnackBar(
      _isDesktopMode ? 'Switched to Desktop mode' : 'Switched to Mobile mode',
    );
  }

  /// Handle menu actions
  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'clear_cache':
        await _controller?.clearCache();
        _showSnackBar('Cache cleared');
        break;

      case 'clear_cookies':
        await _controller?.clearCookies();
        _showSnackBar('Cookies cleared');
        break;

      case 'screenshot':
        final screenshot = await _controller?.takeScreenshot();
        if (screenshot != null) {
          _showSnackBar('Screenshot taken (${screenshot.length} bytes)');
          // In production, save or share the screenshot
        }
        break;

      case 'execute_js':
        _showJavaScriptDialog();
        break;
    }
  }

  /// Show JavaScript execution dialog
  void _showJavaScriptDialog() {
    final controller = TextEditingController(text: 'document.title');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Execute JavaScript'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'JavaScript Code',
            hintText: 'document.title',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final result = await _controller?.evaluateJavascript(
                  source: controller.text,
                );
                _showSnackBar('Result: $result');
              } catch (e) {
                _showSnackBar('Error: $e', isError: true);
              }
            },
            child: const Text('Execute'),
          ),
        ],
      ),
    );
  }

  /// Build navigation bar (matches legacy bottom navigation)
  Widget _buildNavigationBar(bool isLandscape) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _canGoBack ? () => _controller?.goBack() : null,
              tooltip: 'Go Back',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _canGoForward ? () => _controller?.goForward() : null,
              tooltip: 'Go Forward',
            ),
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => _controller?.loadUrl(url: widget.url),
              tooltip: 'Home',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller?.reload(),
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: Icon(_isDesktopMode ? Icons.phone_android : Icons.computer),
              onPressed: _toggleUserAgent,
              tooltip: 'Toggle Mode',
            ),
          ],
        ),
      ),
    );
  }

  /// Build side drawer for landscape mode
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Real WebView',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentUrl ?? 'No URL',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.clear_all),
            title: const Text('Clear Cache'),
            onTap: () {
              Navigator.pop(context);
              _handleMenuAction('clear_cache');
            },
          ),
          ListTile(
            leading: const Icon(Icons.cookie),
            title: const Text('Clear Cookies'),
            onTap: () {
              Navigator.pop(context);
              _handleMenuAction('clear_cookies');
            },
          ),
          ListTile(
            leading: const Icon(Icons.screenshot),
            title: const Text('Take Screenshot'),
            onTap: () {
              Navigator.pop(context);
              _handleMenuAction('screenshot');
            },
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Execute JavaScript'),
            onTap: () {
              Navigator.pop(context);
              _showJavaScriptDialog();
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              _isDesktopMode ? Icons.phone_android : Icons.computer,
            ),
            title: Text(_isDesktopMode ? 'Mobile Mode' : 'Desktop Mode'),
            onTap: () {
              Navigator.pop(context);
              _toggleUserAgent();
            },
          ),
        ],
      ),
    );
  }

  /// Show snackbar message
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

/// Example usage demonstrating migration from legacy code
class MigrationExampleUsage extends StatelessWidget {
  const MigrationExampleUsage({super.key});

  @override
  Widget build(BuildContext context) {
    // Example cookies JSON (same format as legacy code)
    const cookiesJson = '''
    [
      {
        "name": "session_token",
        "value": "abc123xyz",
        "domain": ".example.com",
        "path": "/",
        "secure": true,
        "httpOnly": true,
        "sameSite": "Lax"
      },
      {
        "name": "user_preference",
        "value": "dark_mode",
        "domain": ".example.com",
        "path": "/",
        "secure": false,
        "httpOnly": false
      }
    ]
    ''';

    return Scaffold(
      appBar: AppBar(title: const Text('Migration Examples')),
      body: ListView(
        children: [
          _buildExampleCard(
            context,
            'Netflix with Auto-DRM',
            'Replaces manual platform channel DRM calls',
            () => _openExample(
              context,
              'https://www.netflix.com',
              cookies: cookiesJson,
              enableDRM: true,
            ),
          ),
          _buildExampleCard(
            context,
            'Disney+ with Cookies',
            'Cookie injection from JSON + automatic Widevine',
            () => _openExample(
              context,
              'https://www.disneyplus.com',
              cookies: cookiesJson,
              enableDRM: true,
            ),
          ),
          _buildExampleCard(
            context,
            'YouTube (No DRM)',
            'Standard video playback without DRM',
            () => _openExample(
              context,
              'https://www.youtube.com',
              enableDRM: false,
            ),
          ),
          _buildExampleCard(
            context,
            'Custom URL with All Features',
            'Desktop mode + cookies + DRM',
            () => _showCustomURLDialog(context),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              color: Colors.green,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Migration Benefits',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '✅ No platform channels for DRM',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      '✅ Automatic Widevine/FairPlay detection',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      '✅ Same cookie JSON format',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      '✅ Simplified settings API',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      '✅ Chrome-like streaming support',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _openExample(
    BuildContext context,
    String url, {
    String? cookies,
    bool enableDRM = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LegacyMigrationExample(
          url: url,
          cookies: cookies,
          enableDRM: enableDRM,
        ),
      ),
    );
  }

  void _showCustomURLDialog(BuildContext context) {
    final urlController = TextEditingController();
    final cookiesController = TextEditingController();
    bool enableDRM = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Custom Configuration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://example.com',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cookiesController,
                  decoration: const InputDecoration(
                    labelText: 'Cookies JSON (optional)',
                    hintText: '[{"name": "...", "value": "..."}]',
                  ),
                  maxLines: 3,
                ),
                CheckboxListTile(
                  title: const Text('Enable DRM'),
                  value: enableDRM,
                  onChanged: (value) {
                    setState(() {
                      enableDRM = value ?? true;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (urlController.text.isNotEmpty) {
                  _openExample(
                    context,
                    urlController.text,
                    cookies: cookiesController.text.isNotEmpty
                        ? cookiesController.text
                        : null,
                    enableDRM: enableDRM,
                  );
                }
              },
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }
}
