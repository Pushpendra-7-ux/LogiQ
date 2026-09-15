class MaterialItem {
  final int? id;
  final int? tenderId;
  final String? hsnCode;
  final String description;
  final double quantity;
  final String unit;
  final String? remarks;

  MaterialItem({
    this.id,
    this.tenderId,
    this.hsnCode,
    required this.description,
    required this.quantity,
    required this.unit,
    this.remarks,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) => MaterialItem(
        id: (json['id'] as num?)?.toInt(),
        tenderId: (json['tender_id'] as num?)?.toInt(),
        hsnCode: json['hsn_code']?.toString(),
        description: json['description']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit']?.toString() ?? 'MT',
        remarks: json['remarks']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tender_id': tenderId,
        'hsn_code': hsnCode,
        'description': description,
        'quantity': quantity,
        'unit': unit,
        'remarks': remarks,
      };
}