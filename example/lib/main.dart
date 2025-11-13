import 'package:flutter/material.dart';
import 'package:real_webview/real_webview.dart';
import 'streaming_demo.dart';
import 'example_migration.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real WebView Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real WebView Examples'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExampleCard(
            context,
            'Basic WebView Demo',
            'Explore all WebView features: navigation, cookies, JavaScript, screenshots',
            Icons.web,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WebViewExamplePage(),
              ),
            ),
          ),
          _buildExampleCard(
            context,
            'Streaming Demo (Auto-DRM)',
            'Netflix, Disney+, Prime Video with automatic DRM configuration',
            Icons.play_circle,
            Colors.red,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StreamingDemoPage(),
              ),
            ),
          ),
          _buildExampleCard(
            context,
            'Migration from InAppWebView',
            'Complete example showing migration from flutter_inappwebview',
            Icons.compare_arrows,
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MigrationExampleUsage(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            color: Color(0xFFE3F2FD),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Key Features',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text('✅ Chrome-based WebView on all platforms'),
                  Text('✅ Automatic DRM (Widevine, FairPlay, PlayReady)'),
                  Text('✅ Advanced cookie management'),
                  Text('✅ JavaScript execution and handlers'),
                  Text('✅ Screenshot capture'),
                  Text('✅ Download handling'),
                  Text('✅ Full navigation control'),
                ],
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
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class WebViewExamplePage extends StatefulWidget {
  const WebViewExamplePage({super.key});

  @override
  State<WebViewExamplePage> createState() => _WebViewExamplePageState();
}

class _WebViewExamplePageState extends State<WebViewExamplePage> {
  RealWebViewController? _webViewController;
  final TextEditingController _urlController = TextEditingController(
    text: 'https://flutter.dev',
  );

  String _currentUrl = '';
  int _progress = 0;
  bool _isLoading = false;
  String _title = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real WebView Example'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              if (_isLoading)
                LinearProgressIndicator(
                  value: _progress / 100,
                  backgroundColor: Colors.grey[300],
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          hintText: 'Enter URL',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onSubmitted: (value) {
                          _loadUrl(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _webViewController?.reload(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (_title.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Text(
                _title,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            child: RealWebView(
              initialUrl: _urlController.text,
              initialSettings: WebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                supportZoom: true,
                builtInZoomControls: true,
                displayZoomControls: false,
                useWideViewPort: true,
                loadWithOverviewMode: true,
                // DRM Configuration example
                drmConfiguration: DRMConfiguration.widevine(
                  licenseServerUrl: 'https://example.com/drm/license',
                  headers: {
                    'X-Custom-Header': 'value',
                  },
                ),
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                _setupCookies();
              },
              onUrlChanged: (controller, url) {
                setState(() {
                  _currentUrl = url;
                  _urlController.text = url;
                });
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _isLoading = true;
                  _currentUrl = url;
                });
              },
              onLoadStop: (controller, url) {
                setState(() {
                  _isLoading = false;
                });
                _updateTitle();
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress;
                });
              },
              onLoadError: (controller, error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${error.description}'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              onConsoleMessage: (controller, message) {
                debugPrint('Console [${message.level}]: ${message.message}');
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                final canGoBack = await _webViewController?.canGoBack() ?? false;
                if (canGoBack) {
                  _webViewController?.goBack();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () async {
                final canGoForward =
                    await _webViewController?.canGoForward() ?? false;
                if (canGoForward) {
                  _webViewController?.goForward();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.cookie),
              onPressed: _showCookieDialog,
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettingsDialog,
            ),
            IconButton(
              icon: const Icon(Icons.code),
              onPressed: _showJavaScriptDialog,
            ),
            IconButton(
              icon: const Icon(Icons.screenshot),
              onPressed: _takeScreenshot,
            ),
          ],
        ),
      ),
    );
  }

  void _loadUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    _webViewController?.loadUrl(url: url);
  }

  void _updateTitle() async {
    final title = await _webViewController?.getTitle();
    if (title != null && mounted) {
      setState(() {
        _title = title;
      });
    }
  }

  void _setupCookies() async {
    // Example: Setting cookies
    final cookieManager = CookieManager.instance();

    await cookieManager.setCookie(
      url: 'https://flutter.dev',
      cookie: Cookie(
        name: 'test_cookie',
        value: 'test_value',
        domain: '.flutter.dev',
        path: '/',
        isSecure: true,
        isHttpOnly: false,
        sameSite: CookieSameSitePolicy.lax,
      ),
    );
  }

  void _showCookieDialog() async {
    final cookies = await CookieManager.instance().getCookies(
      url: _currentUrl.isNotEmpty ? _currentUrl : 'https://flutter.dev',
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cookies'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: cookies.isEmpty
              ? const Center(child: Text('No cookies found'))
              : ListView.builder(
                  itemCount: cookies.length,
                  itemBuilder: (context, index) {
                    final cookie = cookies[index];
                    return ListTile(
                      title: Text(cookie.name),
                      subtitle: Text(cookie.value),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await CookieManager.instance().deleteCookie(
                            url: _currentUrl,
                            name: cookie.name,
                          );
                          Navigator.pop(context);
                          _showCookieDialog();
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              _showAddCookieDialog();
              Navigator.pop(context);
            },
            child: const Text('Add Cookie'),
          ),
        ],
      ),
    );
  }

  void _showAddCookieDialog() {
    final nameController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Cookie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(labelText: 'Value'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  valueController.text.isNotEmpty) {
                await CookieManager.instance().setCookie(
                  url: _currentUrl,
                  cookie: Cookie(
                    name: nameController.text,
                    value: valueController.text,
                  ),
                );
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cookie added')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() async {
    final settings = await _webViewController?.getSettings();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WebView Settings'),
        content: settings != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('JavaScript: ${settings.javaScriptEnabled}'),
                  Text('DOM Storage: ${settings.domStorageEnabled}'),
                  Text('Database: ${settings.databaseEnabled}'),
                  Text('Zoom Support: ${settings.supportZoom}'),
                  Text('User Agent: ${settings.userAgent ?? "Default"}'),
                ],
              )
            : const Text('No settings available'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showJavaScriptDialog() {
    final jsController = TextEditingController(
      text: 'document.title',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Execute JavaScript'),
        content: TextField(
          controller: jsController,
          decoration: const InputDecoration(
            labelText: 'JavaScript Code',
            hintText: 'e.g., document.title',
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
              final result = await _webViewController?.evaluateJavascript(
                source: jsController.text,
              );
              if (!mounted) return;
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Result'),
                  content: Text(result?.toString() ?? 'null'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Execute'),
          ),
        ],
      ),
    );
  }

  void _takeScreenshot() async {
    final screenshot = await _webViewController?.takeScreenshot();
    if (screenshot != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Screenshot'),
          content: Image.memory(screenshot),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _webViewController?.dispose();
    super.dispose();
  }
}
