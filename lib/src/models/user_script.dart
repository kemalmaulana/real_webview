/// User script injection configuration
class UserScript {
  /// JavaScript source code to inject
  final String source;

  /// When to inject the script
  final UserScriptInjectionTime injectionTime;

  /// Target frames for injection
  final ContentWorld contentWorld;

  /// Group name for the script (optional, for management)
  final String? groupName;

  UserScript({
    required this.source,
    this.injectionTime = UserScriptInjectionTime.atDocumentStart,
    this.contentWorld = ContentWorld.page,
    this.groupName,
  });

  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'injectionTime': injectionTime.index,
      'contentWorld': contentWorld.index,
      'groupName': groupName,
    };
  }

  factory UserScript.fromMap(Map<String, dynamic> map) {
    return UserScript(
      source: map['source'] as String,
      injectionTime: UserScriptInjectionTime.values[map['injectionTime'] as int? ?? 0],
      contentWorld: ContentWorld.values[map['contentWorld'] as int? ?? 0],
      groupName: map['groupName'] as String?,
    );
  }
}

/// When to inject user scripts
enum UserScriptInjectionTime {
  /// Inject at document start (before any content loads)
  atDocumentStart,

  /// Inject at document end (after DOM is loaded)
  atDocumentEnd,
}

/// Content world for script execution
enum ContentWorld {
  /// Page content world (shares JavaScript context with web page)
  page,

  /// Default content world (isolated from web page)
  defaultClient,
}
