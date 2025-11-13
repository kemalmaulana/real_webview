/// Cookie model for managing web cookies
class Cookie {
  /// The name of the cookie
  final String name;

  /// The value of the cookie
  final String value;

  /// The domain of the cookie
  final String? domain;

  /// The path of the cookie
  final String? path;

  /// Expiration date of the cookie (in milliseconds since epoch)
  final int? expiresDate;

  /// Maximum age of the cookie in seconds
  final int? maxAge;

  /// Whether the cookie is secure (HTTPS only)
  final bool isSecure;

  /// Whether the cookie is HTTP only
  final bool isHttpOnly;

  /// SameSite attribute of the cookie
  final CookieSameSitePolicy sameSite;

  Cookie({
    required this.name,
    required this.value,
    this.domain,
    this.path = '/',
    this.expiresDate,
    this.maxAge,
    this.isSecure = false,
    this.isHttpOnly = false,
    this.sameSite = CookieSameSitePolicy.noRestriction,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'value': value,
      'domain': domain,
      'path': path,
      'expiresDate': expiresDate,
      'maxAge': maxAge,
      'isSecure': isSecure,
      'isHttpOnly': isHttpOnly,
      'sameSite': sameSite.index,
    };
  }

  factory Cookie.fromMap(Map<String, dynamic> map) {
    return Cookie(
      name: map['name'] as String,
      value: map['value'] as String,
      domain: map['domain'] as String?,
      path: map['path'] as String? ?? '/',
      expiresDate: map['expiresDate'] as int?,
      maxAge: map['maxAge'] as int?,
      isSecure: map['isSecure'] as bool? ?? false,
      isHttpOnly: map['isHttpOnly'] as bool? ?? false,
      sameSite: CookieSameSitePolicy.values[map['sameSite'] as int? ?? 0],
    );
  }

  @override
  String toString() {
    return 'Cookie{name: $name, value: $value, domain: $domain, path: $path}';
  }
}

/// Cookie SameSite policy
enum CookieSameSitePolicy {
  noRestriction,
  lax,
  strict,
}
