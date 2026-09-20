class MaterialItem {
  final int? id;
  final int? tenderId;
  final String hsnCode;
  final String description;
  final double quantity;
  final String unit;
  final String remarks;

  const MaterialItem({
    this.id,
    this.tenderId,
    this.hsnCode = '',
    required this.description,
    this.quantity = 0,
    this.unit = 'MT',
    this.remarks = '',
  });

  String get label =>
      description.isEmpty ? '$quantity $unit' : '$description · $quantity $unit';

  Map<String, Object?> toMap() => {
        'id': id,
        'tender_id': tenderId,
        'hsn_code': hsnCode,
        'description': description,
        'quantity': quantity,
        'unit': unit,
        'remarks': remarks,
      };

  factory MaterialItem.fromMap(Map<String, Object?> m) => MaterialItem(
        id: m['id'] as int?,
        tenderId: m['tender_id'] as int?,
        hsnCode: (m['hsn_code'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        quantity: (m['quantity'] as num? ?? 0).toDouble(),
        unit: (m['unit'] ?? 'MT') as String,
        remarks: (m['remarks'] ?? '') as String,
      );
}
