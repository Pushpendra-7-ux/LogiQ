import 'app_constants.dart';

/// Demo-only constants. Everything the prototype simulates lives here so the
/// mock layer can later be removed / replaced without touching business UI.
class DemoConstants {
  DemoConstants._();

  // ---- Mock login (no real authentication) ----
  static const String demoPassword = '123456';
  static const String demoUserEmail = 'user@logiq.com';
  static const String demoTransporterEmail = 'transporter1@logiq.com';
  static const String demoAdminEmail = 'admin@logiq.com';

  // Role-specific demo credentials
  static const String userDemoEmail = 'user@logiq.demo';
  static const String userDemoPassword = 'User@123';
  static const String shipperDemoEmail = 'shipper@logiq.demo';
  static const String shipperDemoPassword = 'Shipper@123';
  static const String transporterDemoEmail = 'transporter@logiq.demo';
  static const String transporterDemoPassword = 'Transporter@123';
  static const String adminDemoEmail = 'admin@logiq.demo';
  static const String adminDemoPassword = 'Admin@123';

  // ---- Draft countdown (3-min security window before auto-publish) ----
  static const Duration draftCountdownDuration = Duration(minutes: 3);

  // ---- Auction timing (kept short so the full flow is demoable) ----
  static const Duration demoStartDelay = Duration(seconds: 8);
  static const Duration stage1Duration = Duration(minutes: 3);
  static const Duration stage2Duration = Duration(minutes: 2);

  // ---- Late-bid extension (single configurable source) ----
  static const Duration extensionWindow = Duration(seconds: 45);
  static const Duration extensionAmount = Duration(seconds: 30);
  static const Duration hardStopBuffer = Duration(minutes: 10);

  // ---- Mock competitor simulation ----
  static const double baseBidAmount = 50000.0;
  static const Duration competitorBidMinInterval = Duration(seconds: 6);
  static const Duration competitorBidMaxInterval = Duration(seconds: 13);
  static const Duration stage2CompetitorMinDelay = Duration(seconds: 4);
  static const Duration stage2CompetitorMaxDelay = Duration(seconds: 16);

  static const double defaultPriceDifference = AppConstants.defaultPriceDifference;

  // ---- Stage transition screen pacing ----
  static const Duration transitionStep = Duration(milliseconds: 950);

  // ---- Demo locations ----
  static const List<String> demoPickupLocations = [
    'Bhiwandi Hub 4, Maharashtra - 421302',
    'Gwalior, Madhya Pradesh',
    'Nagpur, Maharashtra',
    'Bhopal, Madhya Pradesh',
    'Mumbai, Maharashtra',
    'Chennai, Tamil Nadu',
  ];

  static const List<String> demoDropLocations = [
    'Manesar Sector 8, Haryana - 122051',
    'Raipur, Chhattisgarh',
    'Pune, Maharashtra',
    'Indore, Madhya Pradesh',
    'Delhi, NCR',
    'Bengaluru, Karnataka',
  ];
}
