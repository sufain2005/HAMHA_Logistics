import 'package:flutter/foundation.dart';

class AdminConstants {
  static String get host {
    if (kIsWeb) return 'localhost';
    if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2';
    return 'localhost';
  }

  static String get baseUrl => 'http://$host:5000/api';
  static String get socketUrl => 'http://$host:5000';

  // Tile endpoints for high-contrast command center
  static const String mapboxNavDarkTiles =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const String mapboxVoyagerTiles =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
}

