class Item {
  final int? id;
  final String barcode;
  final String name;
  final int quantity; // <-- ADDED: Missing quantity field
  final String dateSubmitted;

  Item({
    this.id,
    required this.barcode,
    required this.name,
    required this.quantity, // <-- ADDED
    required this.dateSubmitted,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'quantity': quantity, // <-- ADDED
      'dateSubmitted': dateSubmitted,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      barcode: map['barcode'],
      name: map['name'],
      quantity: map['quantity'], // <-- ADDED
      dateSubmitted: map['dateSubmitted'],
    );
  }
}