/// Download request information
class DownloadRequest {
  /// Download URL
  final String url;

  /// Suggested filename
  final String? suggestedFilename;

  /// MIME type of the download
  final String? mimeType;

  /// Content length in bytes
  final int? contentLength;

  /// User agent string
  final String? userAgent;

  /// Content disposition
  final String? contentDisposition;

  DownloadRequest({
    required this.url,
    this.suggestedFilename,
    this.mimeType,
    this.contentLength,
    this.userAgent,
    this.contentDisposition,
  });

  factory DownloadRequest.fromMap(Map<String, dynamic> map) {
    return DownloadRequest(
      url: map['url'] as String,
      suggestedFilename: map['suggestedFilename'] as String?,
      mimeType: map['mimeType'] as String?,
      contentLength: map['contentLength'] as int?,
      userAgent: map['userAgent'] as String?,
      contentDisposition: map['contentDisposition'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'suggestedFilename': suggestedFilename,
      'mimeType': mimeType,
      'contentLength': contentLength,
      'userAgent': userAgent,
      'contentDisposition': contentDisposition,
    };
  }

  @override
  String toString() {
    return 'DownloadRequest{url: $url, filename: $suggestedFilename, type: $mimeType}';
  }
}
