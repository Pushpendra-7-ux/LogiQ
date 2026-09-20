import '../../models/transporter.dart';

/// Rich transporter data matching the reference UI screenshots.
/// Names, codes, ratings, trip counts and fleet sizes are realistic demo values.
class MockTransporters {
  MockTransporters._();

  /// Enrichment data for each seeded transporter (indexed 0-6).
  /// Applied after DB load since SQLite doesn't store display-only fields.
  static const List<_TransporterMeta> _meta = [
    _TransporterMeta('Agarwal Fast Freight', 'TR-1024', 4.9, 1420, '140+', '23AABCA1234A1Z5'),
    _TransporterMeta('BlueDart Surface Cargo', 'TR-2088', 4.8, 2890, '310+', '23AACBD5678C1Z9'),
    _TransporterMeta('Safexpress Industrial', 'TR-3419', 4.7, 980, '85+', '27AABCS1122B1Z4'),
    _TransporterMeta('VRL Logistics Special', 'TR-1185', 4.6, 1740, '120+', '22AACSG3344D1Z1'),
    _TransporterMeta('Delhivery Heavy Freight', 'TR-4926', 4.5, 3120, '220+', '23AACSK5566E1Z7'),
    _TransporterMeta('TCI Freight Express', 'TR-1862', 4.8, 2040, '160+', '23AACSS7788F1Z2'),
    _TransporterMeta('Gati KWE Bulk Line', 'TR-3912', 4.9, 1610, '95+', '27AACSR9900G1Z8'),
  ];

  static const List<Transporter> approved = [
    Transporter(userId: 0, companyName: 'Agarwal Fast Freight', gstin: '23AABCA1234A1Z5', vahanId: 'MH-12-AB-1001'),
    Transporter(userId: 0, companyName: 'BlueDart Surface Cargo', gstin: '23AACBD5678C1Z9', vahanId: 'MP-09-CD-2002'),
    Transporter(userId: 0, companyName: 'Safexpress Industrial', gstin: '27AABCS1122B1Z4', vahanId: 'MH-14-EF-3003'),
    Transporter(userId: 0, companyName: 'VRL Logistics Special', gstin: '22AACSG3344D1Z1', vahanId: 'UP-32-GH-4004'),
    Transporter(userId: 0, companyName: 'Delhivery Heavy Freight', gstin: '23AACSK5566E1Z7', vahanId: 'MP-21-JK-5005'),
    Transporter(userId: 0, companyName: 'TCI Freight Express', gstin: '23AACSS7788F1Z2', vahanId: 'RJ-19-LM-6006'),
    Transporter(userId: 0, companyName: 'Gati KWE Bulk Line', gstin: '27AACSR9900G1Z8', vahanId: 'MH-22-NO-7007'),
  ];

  static const pending = [
    Transporter(userId: 0, companyName: 'Vardhman Carriers', gstin: '23AACSV2468H1Z3', vahanId: 'MP-07-PQ-8008', isApproved: false),
  ];

  /// Enrich a list of transporters loaded from SQLite with display-only metadata.
  static List<Transporter> enrichWithDisplayData(List<Transporter> dbTransporters) {
    return dbTransporters.map((t) {
      final metaIndex = _meta.indexWhere((m) => m.companyName == t.companyName);
      if (metaIndex >= 0) {
        final m = _meta[metaIndex];
        return t.withDisplayData(
          rating: m.rating,
          tripCount: m.tripCount,
          fleetSize: m.fleetSize,
          transportCode: m.transportCode,
        );
      }
      // Fallback for transporters not in meta list
      return t.withDisplayData(
        rating: 4.0,
        tripCount: 500,
        fleetSize: '30+',
        transportCode: 'TR-${t.id ?? 0}',
      );
    }).toList();
  }

  static List<String> get names => approved.map((t) => t.companyName).toList();
}

class _TransporterMeta {
  final String companyName;
  final String transportCode;
  final double rating;
  final int tripCount;
  final String fleetSize;
  final String gstin;

  const _TransporterMeta(
    this.companyName,
    this.transportCode,
    this.rating,
    this.tripCount,
    this.fleetSize,
    this.gstin,
  );
}
