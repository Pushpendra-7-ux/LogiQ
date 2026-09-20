/// Realistic HSN (Harmonized System of Nomenclature) code data for demo.
/// Each entry maps an HSN code to a material description and default unit.
class HsnData {
  HsnData._();

  static const List<HsnEntry> entries = [
    HsnEntry(code: '7208', name: 'Steel Coils', unit: 'MT'),
    HsnEntry(code: '7209', name: 'Cold Rolled Steel', unit: 'MT'),
    HsnEntry(code: '7210', name: 'Galvanized Steel Sheets', unit: 'MT'),
    HsnEntry(code: '2701', name: 'Coal (Bituminous)', unit: 'MT'),
    HsnEntry(code: '2523', name: 'Portland Cement', unit: 'Bags'),
    HsnEntry(code: '2517', name: 'Crushed Stone / Aggregate', unit: 'MT'),
    HsnEntry(code: '3901', name: 'Polyethylene Granules', unit: 'MT'),
    HsnEntry(code: '3902', name: 'Polypropylene Resin', unit: 'MT'),
    HsnEntry(code: '4801', name: 'Newsprint Paper', unit: 'MT'),
    HsnEntry(code: '4802', name: 'Writing / Printing Paper', unit: 'MT'),
    HsnEntry(code: '1001', name: 'Wheat (Grain)', unit: 'MT'),
    HsnEntry(code: '1006', name: 'Rice (Paddy)', unit: 'Bags'),
    HsnEntry(code: '1005', name: 'Maize / Corn', unit: 'MT'),
    HsnEntry(code: '1507', name: 'Soybean Oil', unit: 'MT'),
    HsnEntry(code: '2710', name: 'Petroleum Products', unit: 'MT'),
    HsnEntry(code: '3105', name: 'Fertilizers (NPK)', unit: 'Bags'),
    HsnEntry(code: '6810', name: 'Concrete Blocks / Tiles', unit: 'Nos'),
    HsnEntry(code: '7304', name: 'Seamless Steel Pipes', unit: 'MT'),
    HsnEntry(code: '8429', name: 'Heavy Machinery Parts', unit: 'Nos'),
    HsnEntry(code: '8703', name: 'Motor Vehicles (Auto)', unit: 'Nos'),
  ];

  /// Search HSN entries by code or name prefix.
  static List<HsnEntry> search(String query) {
    if (query.isEmpty) return entries;
    final q = query.toLowerCase();
    return entries.where((e) =>
        e.code.toLowerCase().contains(q) ||
        e.name.toLowerCase().contains(q)).toList();
  }

  /// Find exact HSN entry by code.
  static HsnEntry? byCode(String code) {
    try {
      return entries.firstWhere((e) => e.code == code);
    } catch (_) {
      return null;
    }
  }
}

class HsnEntry {
  final String code;
  final String name;
  final String unit;

  const HsnEntry({
    required this.code,
    required this.name,
    required this.unit,
  });

  /// Display label: "HSN 7208 – Steel Coils"
  String get label => 'HSN $code – $name';

  /// Short label: "7208 – Steel Coils"
  String get shortLabel => '$code – $name';
}
