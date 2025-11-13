import 'package:flutter/material.dart';
import 'package:real_webview/real_webview.dart';

/// Example demonstrating automatic DRM handling for streaming services
/// Works like Chrome - no need to manually configure license servers!
class StreamingDemoPage extends StatefulWidget {
  const StreamingDemoPage({super.key});

  @override
  State<StreamingDemoPage> createState() => _StreamingDemoPageState();
}

class _StreamingDemoPageState extends State<StreamingDemoPage> {
  RealWebViewController? _controller;
  String _selectedPreset = 'netflix';

  // Popular streaming services that work with auto-DRM
  final Map<String, Map<String, String>> _streamingServices = {
    'netflix': {
      'name': 'Netflix',
      'url': 'https://www.netflix.com',
      'description': 'Widevine DRM (Auto-configured)',
    },
    'disneyplus': {
      'name': 'Disney+',
      'url': 'https://www.disneyplus.com',
      'description': 'Widevine DRM (Auto-configured)',
    },
    'prime': {
      'name': 'Amazon Prime Video',
      'url': 'https://www.amazon.com/Prime-Video',
      'description': 'Widevine DRM (Auto-configured)',
    },
    'youtube': {
      'name': 'YouTube',
      'url': 'https://www.youtube.com',
      'description': 'No DRM or auto-configured',
    },
    'custom': {
      'name': 'Custom URL',
      'url': '',
      'description': 'Auto-detect DRM from stream',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-DRM Streaming Demo'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                DropdownButton<String>(
                  value: _selectedPreset,
                  isExpanded: true,
                  items: _streamingServices.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.value['name']!),
                          Text(
                            entry.value['description']!,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPreset = value;
                      });
                      _loadService(value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.blue[50],
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Auto-DRM enabled - No manual configuration needed!',
                    style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RealWebView(
              initialUrl: _streamingServices[_selectedPreset]!['url'],
              initialSettings: WebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                // AUTOMATIC DRM - Just use the preset!
                drmConfiguration: AutoDRMHandler.getPreset(_selectedPreset),
                // Or use createAutoDRM() for generic auto-detection:
                // drmConfiguration: AutoDRMHandler.createAutoDRM(),
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
                _setupStreamingCookies();
              },
              onLoadStart: (controller, url) {
                debugPrint('[Streaming] Loading: $url');
              },
              onLoadStop: (controller, url) {
                debugPrint('[Streaming] Loaded: $url');
              },
              onConsoleMessage: (controller, message) {
                // Log DRM-related console messages
                if (message.message.contains('DRM') ||
                    message.message.contains('RealWebView')) {
                  debugPrint('[DRM] ${message.message}');
                }
              },
              onLoadError: (controller, error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${error.description}'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            onPressed: _showCustomURLDialog,
            heroTag: 'custom_url',
            child: const Icon(Icons.link),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            onPressed: () => _controller?.reload(),
            heroTag: 'reload',
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  void _loadService(String preset) {
    final url = _streamingServices[preset]!['url']!;
    if (url.isNotEmpty) {
      _controller?.loadUrl(url: url);
    }
  }

  void _setupStreamingCookies() async {
    // Example: Set cookies for authenticated streaming
    // In production, you'd get these from your auth system
    final cookieManager = CookieManager.instance();

    // Example cookie setup (adjust based on your needs)
    await cookieManager.setCookie(
      url: 'https://www.netflix.com',
      cookie: Cookie(
        name: 'example_cookie',
        value: 'example_value',
        domain: '.netflix.com',
        isSecure: true,
        sameSite: CookieSameSitePolicy.lax,
      ),
    );
  }

  void _showCustomURLDialog() {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Custom Streaming URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Streaming URL',
                hintText: 'https://example.com/video',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'DRM will be automatically detected from the stream',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                _controller?.loadUrl(url: urlController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }
}

/// Standalone example showing different DRM configurations
class DRMConfigurationExamples extends StatelessWidget {
  const DRMConfigurationExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DRM Configuration Examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExample(
            'Automatic DRM (Recommended)',
            'Let the WebView detect and configure DRM automatically - just like Chrome!',
            '''
RealWebView(
  initialUrl: 'https://streaming-service.com/video',
  initialSettings: WebViewSettings(
    // AUTO-DRM: No license server needed!
    drmConfiguration: AutoDRMHandler.createAutoDRM(),
  ),
)
            ''',
          ),
          const Divider(),
          _buildExample(
            'Netflix Preset',
            'Pre-configured for Netflix with Widevine auto-detection',
            '''
RealWebView(
  initialUrl: 'https://www.netflix.com',
  initialSettings: WebViewSettings(
    drmConfiguration: AutoDRMHandler.getPreset('netflix'),
  ),
)
            ''',
          ),
          const Divider(),
          _buildExample(
            'Disney+ Preset',
            'Pre-configured for Disney+ with Widevine auto-detection',
            '''
RealWebView(
  initialUrl: 'https://www.disneyplus.com',
  initialSettings: WebViewSettings(
    drmConfiguration: AutoDRMHandler.getPreset('disneyplus'),
  ),
)
            ''',
          ),
          const Divider(),
          _buildExample(
            'Apple TV+ / FairPlay',
            'Auto-configured for FairPlay DRM (iOS/macOS)',
            '''
RealWebView(
  initialUrl: 'https://tv.apple.com',
  initialSettings: WebViewSettings(
    drmConfiguration: AutoDRMHandler.getPreset('appletv'),
  ),
)
            ''',
          ),
          const Divider(),
          _buildExample(
            'Generic HLS with FairPlay',
            'Auto-detect FairPlay from HLS streams',
            '''
RealWebView(
  initialUrl: 'https://example.com/stream.m3u8',
  initialSettings: WebViewSettings(
    drmConfiguration: AutoDRMHandler.getPreset('hls-fairplay'),
  ),
)
            ''',
          ),
          const Divider(),
          _buildExample(
            'Generic DASH with Widevine',
            'Auto-detect Widevine from DASH streams',
            '''
RealWebView(
  initialUrl: 'https://example.com/manifest.mpd',
  initialSettings: WebViewSettings(
    drmConfiguration: AutoDRMHandler.getPreset('dash-widevine'),
  ),
)
            ''',
          ),
          const Divider(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Key Benefits',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('✅ No license server URLs needed'),
                const Text('✅ Automatic DRM scheme detection'),
                const Text('✅ Works with Netflix, Disney+, Prime, etc.'),
                const Text('✅ Supports Widevine, FairPlay, PlayReady'),
                const Text('✅ EME API automatically configured'),
                const Text('✅ Chrome-like streaming experience'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExample(String title, String description, String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            code.trim(),
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}
