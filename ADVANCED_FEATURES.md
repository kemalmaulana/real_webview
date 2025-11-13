# Advanced Features Guide

This guide covers the advanced features now available in Real WebView that match and extend flutter_inappwebview functionality.

## Table of Contents

1. [Pull-to-Refresh](#pull-to-refresh)
2. [User Script Injection](#user-script-injection)
3. [Download Handling](#download-handling)
4. [URL Navigation Override](#url-navigation-override)
5. [Permission Requests](#permission-requests)
6. [Complete Integration Example](#complete-integration-example)

---

## Pull-to-Refresh

Add native pull-to-refresh functionality to your WebView, just like in mobile browsers.

### Basic Setup

```dart
late PullToRefreshController _pullToRefreshController;

@override
void initState() {
  super.initState();

  _pullToRefreshController = PullToRefreshController(
    settings: const PullToRefreshSettings(
      enabled: true,
      color: PullToRefreshColor(alpha: 255, red: 33, green: 150, blue: 243),
    ),
    onRefresh: () async {
      await _controller?.reload();
      await _pullToRefreshController.endRefreshing();
    },
  );
}
```

### Usage in RealWebView

```dart
RealWebView(
  initialUrl: 'https://example.com',
  pullToRefreshController: _pullToRefreshController,
  // ... other settings
)
```

### Advanced Pull-to-Refresh Settings

```dart
PullToRefreshController(
  settings: PullToRefreshSettings(
    enabled: true,
    color: PullToRefreshColor.fromHex('#2196F3'),
    backgroundColor: PullToRefreshColor.fromHex('#FFFFFF'),
    distanceToTriggerSync: 100.0,
    slingshotDistance: 150.0,
  ),
  onRefresh: () async {
    // Custom refresh logic
    await performCustomRefresh();
    await _pullToRefreshController.endRefreshing();
  },
)
```

### Programmatic Control

```dart
// Start refreshing programmatically
await _pullToRefreshController.beginRefreshing();

// Stop refreshing
await _pullToRefreshController.endRefreshing();

// Enable/disable pull-to-refresh
await _pullToRefreshController.setEnabled(false);

// Change color dynamically
await _pullToRefreshController.setColor(
  PullToRefreshColor.fromHex('#FF5722')
);
```

---

## User Script Injection

Inject JavaScript at document start or end, perfect for DOM manipulation before page load.

### Injection Timing

- **atDocumentStart**: Before any web page content loads
- **atDocumentEnd**: After DOM is loaded but before images

### Basic User Script

```dart
await _controller?.addUserScript(
  UserScript(
    source: '''
      console.log('RealWebView: Script injected!');
      document.body.style.backgroundColor = 'lightblue';
    ''',
    injectionTime: UserScriptInjectionTime.atDocumentStart,
  ),
);
```

### Grouped Scripts (For Management)

```dart
// Add script with group name
await _controller?.addUserScript(
  UserScript(
    source: '''
      // Dark mode override
      document.documentElement.classList.add('dark-mode');
    ''',
    injectionTime: UserScriptInjectionTime.atDocumentStart,
    groupName: 'darkMode',
  ),
);

// Remove all scripts in a group
await _controller?.removeUserScriptsByGroupName('darkMode');

// Remove all user scripts
await _controller?.removeAllUserScripts();
```

### Real-World Examples

#### 1. Ad Blocker

```dart
await _controller?.addUserScript(
  UserScript(
    source: '''
      (function() {
        // Block common ad elements
        const adSelectors = [
          '.ad', '.advertisement', '#ad-container',
          '[class*="ad-"]', '[id*="ad-"]'
        ];

        function removeAds() {
          adSelectors.forEach(selector => {
            document.querySelectorAll(selector).forEach(el => {
              el.remove();
            });
          });
        }

        // Remove on load
        removeAds();

        // Remove on DOM changes
        const observer = new MutationObserver(removeAds);
        observer.observe(document.body, {
          childList: true,
          subtree: true
        });
      })();
    ''',
    injectionTime: UserScriptInjectionTime.atDocumentStart,
    groupName: 'adBlocker',
  ),
);
```

#### 2. Auto-Login Script

```dart
await _controller?.addUserScript(
  UserScript(
    source: '''
      window.addEventListener('DOMContentLoaded', function() {
        const username = document.querySelector('#username');
        const password = document.querySelector('#password');
        const submit = document.querySelector('#submit');

        if (username && password && submit) {
          username.value = 'user@example.com';
          password.value = 'securePassword';
          // Auto-submit if needed
          // submit.click();
        }
      });
    ''',
    injectionTime: UserScriptInjectionTime.atDocumentEnd,
    groupName: 'autoLogin',
  ),
);
```

#### 3. Download Interceptor

```dart
await _controller?.addUserScript(
  UserScript(
    source: '''
      document.addEventListener('click', function(e) {
        let target = e.target;
        while (target && target.tagName !== 'A') {
          target = target.parentElement;
        }

        if (target && target.download) {
          e.preventDefault();
          window.flutter_inappwebview.callHandler('downloadHandler', target.href);
        }
      }, true);
    ''',
    injectionTime: UserScriptInjectionTime.atDocumentStart,
    groupName: 'downloadHandler',
  ),
);
```

---

## Download Handling

Handle file downloads with full metadata access.

### Basic Download Handler

```dart
RealWebView(
  initialUrl: 'https://example.com',
  onDownloadStart: (controller, request) {
    print('Download started: ${request.url}');
    print('Filename: ${request.suggestedFilename}');
    print('MIME type: ${request.mimeType}');
    print('Size: ${request.contentLength} bytes');

    // Handle the download
    _handleDownload(request);
  },
)
```

### Advanced Download Handling

```dart
Future<void> _handleDownload(DownloadRequest request) async {
  // Show download dialog
  final shouldDownload = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Download File'),
      content: Text(
        'Do you want to download:\n'
        '${request.suggestedFilename ?? request.url}\n\n'
        'Size: ${_formatBytes(request.contentLength)}\n'
        'Type: ${request.mimeType}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Download'),
        ),
      ],
    ),
  );

  if (shouldDownload == true) {
    // Use Dio or http package to download
    await _downloadFile(request);
  }
}

Future<void> _downloadFile(DownloadRequest request) async {
  final dio = Dio();

  // Get download directory
  final dir = await getApplicationDocumentsDirectory();
  final filename = request.suggestedFilename ?? 'download';
  final savePath = '${dir.path}/$filename';

  try {
    await dio.download(
      request.url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          print('${(received / total * 100).toStringAsFixed(0)}%');
        }
      },
    );

    // Show success notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloaded to $savePath')),
    );
  } catch (e) {
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Download failed: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Blob Download Handling

For blob URLs created by JavaScript:

```dart
// Add JavaScript handler for blob downloads
await _controller?.addJavaScriptHandler(
  handlerName: 'blobDownloadHandler',
  callback: (args) {
    if (args.isNotEmpty && args[0] is Map) {
      final data = args[0] as Map;
      final base64Data = data['data'] as String?;
      final mimeType = data['type'] as String?;
      final size = data['size'] as int?;

      // Decode and save blob
      _saveBlobDownload(base64Data, mimeType, size);
    }
  },
);

// Inject blob interceptor
await _controller?.addUserScript(
  UserScript(
    source: '''
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
    ''',
    injectionTime: UserScriptInjectionTime.atDocumentStart,
  ),
);
```

---

## URL Navigation Override

Control which URLs can be loaded in your WebView.

### Basic URL Filtering

```dart
RealWebView(
  initialUrl: 'https://example.com',
  shouldOverrideUrlLoading: (controller, action) async {
    print('Navigation to: ${action.url}');
    print('Type: ${action.navigationType}');
    print('Is main frame: ${action.isForMainFrame}');

    // Block external navigation
    if (action.url.startsWith('https://example.com')) {
      return NavigationActionPolicy.allow;
    }

    return NavigationActionPolicy.cancel;
  },
)
```

### Advanced Navigation Control

```dart
Future<NavigationActionPolicy> _shouldOverrideUrlLoading(
  RealWebViewController controller,
  NavigationAction action,
) async {
  final uri = Uri.parse(action.url);

  // 1. Handle deep links
  if (action.url.startsWith('myapp://')) {
    _handleDeepLink(action.url);
    return NavigationActionPolicy.cancel;
  }

  // 2. Handle external apps
  if (action.url.startsWith('intent://') ||
      action.url.startsWith('market://') ||
      action.url.startsWith('tel:') ||
      action.url.startsWith('mailto:')) {
    await launchUrl(Uri.parse(action.url));
    return NavigationActionPolicy.cancel;
  }

  // 3. Whitelist domains
  final allowedDomains = ['example.com', 'api.example.com'];
  if (!allowedDomains.contains(uri.host)) {
    // Ask user
    final allow = await _askUserToOpenExternal(action.url);
    return allow ? NavigationActionPolicy.allow : NavigationActionPolicy.cancel;
  }

  // 4. Handle specific paths
  if (uri.path == '/logout') {
    _handleLogout();
    return NavigationActionPolicy.cancel;
  }

  // 5. Track analytics
  if (action.navigationType == NavigationType.linkActivated) {
    _trackNavigation(action.url);
  }

  // Allow by default
  return NavigationActionPolicy.allow;
}
```

### Navigation Types

```dart
switch (action.navigationType) {
  case NavigationType.linkActivated:
    print('User clicked a link');
    break;
  case NavigationType.formSubmitted:
    print('Form submitted');
    break;
  case NavigationType.backForward:
    print('Back/Forward navigation');
    break;
  case NavigationType.reload:
    print('Page reloaded');
    break;
  case NavigationType.formResubmitted:
    print('Form resubmitted');
    break;
  case NavigationType.other:
    print('Other navigation');
    break;
}
```

---

## Permission Requests

Handle camera, microphone, location, and other permission requests from web pages.

### Basic Permission Handling

```dart
RealWebView(
  initialUrl: 'https://example.com',
  onPermissionRequest: (controller, request) {
    print('Permission requested by: ${request.origin}');
    print('Resources: ${request.resources}');

    // Show dialog to user
    _showPermissionDialog(controller, request);
  },
)
```

### Permission Dialog

```dart
void _showPermissionDialog(
  RealWebViewController controller,
  PermissionRequest request,
) {
  final resourceNames = request.resources.map((r) {
    switch (r) {
      case PermissionResourceType.camera:
        return 'Camera';
      case PermissionResourceType.microphone:
        return 'Microphone';
      case PermissionResourceType.geolocation:
        return 'Location';
      case PermissionResourceType.mediaId:
        return 'Camera & Microphone';
      default:
        return r.toString();
    }
  }).join(', ');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Permission Request'),
      content: Text(
        '${request.origin}\n\nwants to access:\n$resourceNames',
      ),
      actions: [
        TextButton(
          onPressed: () {
            controller.respondToPermissionRequest(
              request.requestId,
              PermissionResponse.deny,
            );
            Navigator.pop(context);
          },
          child: const Text('Deny'),
        ),
        TextButton(
          onPressed: () {
            controller.respondToPermissionRequest(
              request.requestId,
              PermissionResponse.grant,
            );
            Navigator.pop(context);
          },
          child: const Text('Allow'),
        ),
      ],
    ),
  );
}
```

### Auto-Grant for Trusted Origins

```dart
RealWebView(
  onPermissionRequest: (controller, request) async {
    // Trusted domains
    final trustedOrigins = [
      'https://meet.google.com',
      'https://zoom.us',
      'https://teams.microsoft.com',
    ];

    if (trustedOrigins.any((origin) => request.origin.startsWith(origin))) {
      // Auto-grant for trusted sites
      await controller.respondToPermissionRequest(
        request.requestId,
        PermissionResponse.grant,
      );
      return;
    }

    // Ask user for others
    _showPermissionDialog(controller, request);
  },
)
```

### Permission Types

```dart
for (final resource in request.resources) {
  switch (resource) {
    case PermissionResourceType.camera:
      print('Camera access requested');
      break;
    case PermissionResourceType.microphone:
      print('Microphone access requested');
      break;
    case PermissionResourceType.geolocation:
      print('Location access requested');
      break;
    case PermissionResourceType.mediaId:
      print('Media ID requested');
      break;
    case PermissionResourceType.midiSysex:
      print('MIDI access requested');
      break;
    case PermissionResourceType.protectedMediaId:
      print('Protected media ID requested');
      break;
    case PermissionResourceType.videoCapture:
      print('Video capture requested');
      break;
    case PermissionResourceType.audioCapture:
      print('Audio capture requested');
      break;
  }
}
```

---

## Complete Integration Example

Here's a complete example using all advanced features:

```dart
class AdvancedWebViewPage extends StatefulWidget {
  const AdvancedWebViewPage({super.key});

  @override
  State<AdvancedWebViewPage> createState() => _AdvancedWebViewPageState();
}

class _AdvancedWebViewPageState extends State<AdvancedWebViewPage> {
  RealWebViewController? _controller;
  late PullToRefreshController _pullToRefreshController;

  @override
  void initState() {
    super.initState();

    // Initialize pull-to-refresh
    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        enabled: true,
        color: PullToRefreshColor.fromHex('#2196F3'),
      ),
      onRefresh: () async {
        await _controller?.reload();
        await _pullToRefreshController.endRefreshing();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced WebView')),
      body: RealWebView(
        initialUrl: 'https://example.com',
        pullToRefreshController: _pullToRefreshController,

        initialSettings: WebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          drmConfiguration: AutoDRMHandler.createAutoDRM(),
        ),

        onWebViewCreated: (controller) async {
          _controller = controller;

          // Inject user scripts
          await _injectUserScripts(controller);

          // Set up JavaScript handlers
          await _setupJavaScriptHandlers(controller);
        },

        // Download handling
        onDownloadStart: (controller, request) {
          _handleDownload(request);
        },

        // Navigation override
        shouldOverrideUrlLoading: (controller, action) async {
          return _shouldOverrideUrlLoading(action);
        },

        // Permission requests
        onPermissionRequest: (controller, request) {
          _showPermissionDialog(request);
        },

        onLoadStop: (controller, url) async {
          print('Loaded: $url');
        },
      ),
    );
  }

  Future<void> _injectUserScripts(RealWebViewController controller) async {
    // Dark mode
    await controller.addUserScript(
      UserScript(
        source: '''
          document.documentElement.classList.add('dark-mode');
        ''',
        injectionTime: UserScriptInjectionTime.atDocumentStart,
        groupName: 'darkMode',
      ),
    );

    // Ad blocker
    await controller.addUserScript(
      UserScript(
        source: '''
          // Ad blocking logic
        ''',
        injectionTime: UserScriptInjectionTime.atDocumentStart,
        groupName: 'adBlocker',
      ),
    );
  }

  Future<void> _setupJavaScriptHandlers(RealWebViewController controller) async {
    await controller.addJavaScriptHandler(
      handlerName: 'customHandler',
      callback: (args) {
        print('Custom handler called: $args');
      },
    );
  }

  void _handleDownload(DownloadRequest request) {
    // Implement download logic
  }

  Future<NavigationActionPolicy> _shouldOverrideUrlLoading(
    NavigationAction action,
  ) async {
    // Implement navigation logic
    return NavigationActionPolicy.allow;
  }

  void _showPermissionDialog(PermissionRequest request) {
    // Show permission dialog
  }
}
```

---

## Best Practices

### 1. User Scripts
- Keep scripts lightweight
- Use groups for easy management
- Test thoroughly on different pages
- Consider security implications

### 2. Downloads
- Always ask user before downloading
- Show progress indicators
- Handle errors gracefully
- Respect storage permissions

### 3. Navigation Override
- Whitelist known domains
- Handle deep links properly
- Provide user feedback
- Track analytics

### 4. Permissions
- Show clear explanations
- Remember user choices
- Auto-grant for trusted origins
- Handle denials gracefully

### 5. Pull-to-Refresh
- Match your app's theme
- Provide visual feedback
- Handle errors during refresh
- Don't force refresh

---

## Migration from flutter_inappwebview

### User Scripts
```dart
// Before (flutter_inappwebview)
webViewController?.addUserScript(
  userScript: UserScript(
    source: "...",
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  ),
);

// After (real_webview)
await controller?.addUserScript(
  UserScript(
    source: "...",
    injectionTime: UserScriptInjectionTime.atDocumentStart,
  ),
);
```

### Pull-to-Refresh
```dart
// Before
PullToRefreshController(
  options: PullToRefreshOptions(
    color: Colors.blue,
  ),
  onRefresh: () async {
    await controller?.reload();
  },
);

// After
PullToRefreshController(
  settings: PullToRefreshSettings(
    enabled: true,
    color: PullToRefreshColor.fromHex('#2196F3'),
  ),
  onRefresh: () async {
    await controller?.reload();
    await pullToRefreshController.endRefreshing();
  },
);
```

### Downloads
```dart
// Before
onDownloadStart: (controller, url) {
  // Handle download
}

// After
onDownloadStart: (controller, request) {
  // More metadata available!
  print(request.suggestedFilename);
  print(request.mimeType);
  print(request.contentLength);
}
```

---

## See Also

- [Migration Guide](MIGRATION_FROM_INAPPWEBVIEW.md)
- [Auto-DRM Guide](AUTO_DRM_GUIDE.md)
- [Quick Start](QUICK_START.md)
- [Example App](example/lib/example_migration.dart)
