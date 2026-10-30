import 'package:flutter/foundation.dart';

class AppConstants {
  // Host resolution: on Android Emulator, localhost is 10.0.2.2; on Windows/Web/iOS it is localhost
  static String get host {
    if (kIsWeb) return 'localhost';
    if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2';
    return 'localhost';
  }

  static String get baseUrl => 'http://$host:5000/api';
  static String get socketUrl => 'http://$host:5000';

  // Mapbox Configuration
  // Provide your Mapbox Public Token here:
  static const String mapboxAccessToken = 'pk.eyJ1IjoiaGFtaGEtbG9naXN0aWNzIiwiYSI6ImNtNWV4YW1wbGV4YW1wbGV4YW1wbGUifQ.mock';

  // Carto Dark / Mapbox Dark tiles URL template
  static const String mapboxDarkTileUrl =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  
  static const String mapboxNavigationDarkTileUrl =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
}

