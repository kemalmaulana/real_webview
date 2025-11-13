import 'package:flutter/services.dart';

/// Controller for pull-to-refresh functionality
class PullToRefreshController {
  final MethodChannel? _channel;
  final PullToRefreshSettings settings;
  final void Function()? onRefresh;

  bool _isRefreshing = false;

  PullToRefreshController({
    this.settings = const PullToRefreshSettings(),
    this.onRefresh,
  }) : _channel = null;

  PullToRefreshController._internal(
    this._channel,
    this.settings,
    this.onRefresh,
  );

  /// Whether currently refreshing
  bool get isRefreshing => _isRefreshing;

  /// Begin refreshing
  Future<void> beginRefreshing() async {
    if (_channel == null) return;
    _isRefreshing = true;
    await _channel.invokeMethod('pullToRefresh_beginRefreshing');
  }

  /// End refreshing
  Future<void> endRefreshing() async {
    if (_channel == null) return;
    _isRefreshing = false;
    await _channel.invokeMethod('pullToRefresh_endRefreshing');
  }

  /// Enable pull-to-refresh
  Future<void> setEnabled(bool enabled) async {
    if (_channel == null) return;
    await _channel.invokeMethod('pullToRefresh_setEnabled', enabled);
  }

  /// Set pull-to-refresh color
  Future<void> setColor(PullToRefreshColor color) async {
    if (_channel == null) return;
    await _channel.invokeMethod('pullToRefresh_setColor', color.toMap());
  }

  /// Set background color
  Future<void> setBackgroundColor(PullToRefreshColor color) async {
    if (_channel == null) return;
    await _channel.invokeMethod('pullToRefresh_setBackgroundColor', color.toMap());
  }
}

/// Pull-to-refresh settings
class PullToRefreshSettings {
  /// Enable pull-to-refresh
  final bool enabled;

  /// Refresh indicator color
  final PullToRefreshColor? color;

  /// Background color
  final PullToRefreshColor? backgroundColor;

  /// Distance to trigger refresh
  final double? distanceToTriggerSync;

  /// Slingshotdistance
  final double? slingshotDistance;

  const PullToRefreshSettings({
    this.enabled = true,
    this.color,
    this.backgroundColor,
    this.distanceToTriggerSync,
    this.slingshotDistance,
  });

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'color': color?.toMap(),
      'backgroundColor': backgroundColor?.toMap(),
      'distanceToTriggerSync': distanceToTriggerSync,
      'slingshotDistance': slingshotDistance,
    };
  }
}

/// Color representation for pull-to-refresh
class PullToRefreshColor {
  final int alpha;
  final int red;
  final int green;
  final int blue;

  const PullToRefreshColor({
    required this.alpha,
    required this.red,
    required this.green,
    required this.blue,
  });

  /// Create from hex color code
  factory PullToRefreshColor.fromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';

    return PullToRefreshColor(
      alpha: int.parse(hex.substring(0, 2), radix: 16),
      red: int.parse(hex.substring(2, 4), radix: 16),
      green: int.parse(hex.substring(4, 6), radix: 16),
      blue: int.parse(hex.substring(6, 8), radix: 16),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alpha': alpha,
      'red': red,
      'green': green,
      'blue': blue,
    };
  }

  @override
  String toString() {
    return 'Color(a: $alpha, r: $red, g: $green, b: $blue)';
  }
}
