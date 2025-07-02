class QuoteItem {
  String designation;
  double quantity;
  double unitPrice;

  QuoteItem({
    required this.designation,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  factory QuoteItem.fromMap(Map<String, dynamic> map) => QuoteItem(
    designation: map['designation'] as String? ?? '',
    quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
    unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toMap() => {
    'designation': designation,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };
}