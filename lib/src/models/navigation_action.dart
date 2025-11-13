/// Navigation action information for URL loading decisions
class NavigationAction {
  /// Target URL
  final String url;

  /// Navigation type
  final NavigationType navigationType;

  /// Whether navigation is for main frame
  final bool isForMainFrame;

  /// Whether navigation is redirect
  final bool isRedirect;

  /// HTTP method (GET, POST, etc.)
  final String? method;

  /// Request headers
  final Map<String, String>? headers;

  NavigationAction({
    required this.url,
    this.navigationType = NavigationType.other,
    this.isForMainFrame = true,
    this.isRedirect = false,
    this.method,
    this.headers,
  });

  factory NavigationAction.fromMap(Map<String, dynamic> map) {
    return NavigationAction(
      url: map['url'] as String,
      navigationType: NavigationType.values[map['navigationType'] as int? ?? 0],
      isForMainFrame: map['isForMainFrame'] as bool? ?? true,
      isRedirect: map['isRedirect'] as bool? ?? false,
      method: map['method'] as String?,
      headers: map['headers'] != null
          ? Map<String, String>.from(map['headers'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'navigationType': navigationType.index,
      'isForMainFrame': isForMainFrame,
      'isRedirect': isRedirect,
      'method': method,
      'headers': headers,
    };
  }

  @override
  String toString() {
    return 'NavigationAction{url: $url, type: $navigationType, mainFrame: $isForMainFrame}';
  }
}

/// Navigation type
enum NavigationType {
  /// Link clicked
  linkActivated,

  /// Form submitted
  formSubmitted,

  /// Back/forward navigation
  backForward,

  /// Page reload
  reload,

  /// Form resubmitted
  formResubmitted,

  /// Other navigation
  other,
}

/// Navigation action policy (return value for shouldOverrideUrlLoading)
enum NavigationActionPolicy {
  /// Allow navigation to proceed
  allow,

  /// Cancel navigation
  cancel,
}
