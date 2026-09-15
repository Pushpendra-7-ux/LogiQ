import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  static const String appName = 'LogiQ';
  static const String appTagline = 'Reverse Auction System';

  static String get apiBaseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
      return 'http://localhost:8000';
    } catch (_) {
      return 'http://localhost:8000';
    }
  }

  static String get wsBaseUrl {
    if (kIsWeb) return 'ws://localhost:8000';
    try {
      if (Platform.isAndroid) return 'ws://10.0.2.2:8000';
      return 'ws://localhost:8000';
    } catch (_) {
      return 'ws://localhost:8000';
    }
  }

  static const Duration splashDuration = Duration(milliseconds: 2000);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double defaultPriceDifference = 25.0;
  static const double minTouchTarget = 48.0;
}
