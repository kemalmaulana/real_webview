/// Permission request from web page
class PermissionRequest {
  /// Origin of the permission request
  final String origin;

  /// Requested resources/permissions
  final List<PermissionResourceType> resources;

  /// Request ID for responding
  final String requestId;

  PermissionRequest({
    required this.origin,
    required this.resources,
    required this.requestId,
  });

  factory PermissionRequest.fromMap(Map<String, dynamic> map) {
    return PermissionRequest(
      origin: map['origin'] as String,
      resources: (map['resources'] as List)
          .map((e) => PermissionResourceType.values[e as int])
          .toList(),
      requestId: map['requestId'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'origin': origin,
      'resources': resources.map((e) => e.index).toList(),
      'requestId': requestId,
    };
  }

  @override
  String toString() {
    return 'PermissionRequest{origin: $origin, resources: $resources}';
  }
}

/// Permission resource types
enum PermissionResourceType {
  /// Camera access
  camera,

  /// Microphone access
  microphone,

  /// Geolocation access
  geolocation,

  /// Media ID (camera/microphone combined)
  mediaId,

  /// MIDI access
  midiSysex,

  /// Protected media identifier
  protectedMediaId,

  /// Video capture
  videoCapture,

  /// Audio capture
  audioCapture,
}

/// Permission response
enum PermissionResponse {
  /// Grant the permission
  grant,

  /// Deny the permission
  deny,

  /// Deny and don't ask again
  denyAndNeverAskAgain,
}
