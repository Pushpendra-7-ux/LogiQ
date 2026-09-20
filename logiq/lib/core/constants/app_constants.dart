class AppConstants {
  AppConstants._();

  static const String appName = 'LOGIQ';
  static const String appTagline = 'Reverse Auction System';

  static const String dbName = 'logiq_local.db';
  static const int dbVersion = 1;

  // Business defaults (configurable in one place only)
  static const double defaultPriceDifference = 25.0;
  static const double minPriceDifference = 25.0;
  static const double defaultCeilingBid = 75000.0;
  static const double defaultMinDecrement = 500.0;

  static const int top5Size = 5;

  // Draft countdown — 3 minutes to edit/cancel before auto-publish
  static const Duration draftCountdownDuration = Duration(minutes: 3);

  static const List<String> materialUnits = ['MT', 'Tons', 'Kg', 'Quintal', 'Bags'];

  static const List<String> vehicleTypes = ['Truck', 'Trailer', 'Container', 'Other'];
  static const Map<String, String> vehicleTypeSubtitles = {
    'Truck': 'Open / Closed body',
    'Trailer': 'Flatbed / Lowbed',
    'Container': '20ft / 40ft HQ',
    'Other': 'Specialized / ODC',
  };
}
