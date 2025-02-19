class Item {
  int? id;
  String title;
  double amount;
  String type; // 'income' or 'expense'
  String category;
  DateTime dateTime; // Added timestamp

  Item({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    DateTime? dateTime,
  }) : dateTime = dateTime ?? DateTime.now() {
    // Validate type
    if (type != 'income' && type != 'expense') {
      throw ArgumentError('Type must be either "income" or "expense"');
    }
    // Validate amount
    if (amount < 0) {
      throw ArgumentError('Amount must be non-negative');
    }
  }

  // Convert a Map into an Item object
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      title: map['title'],
      amount: (map['amount'] as num).toDouble(),
      type: map['type'],
      category: map['category'],
      dateTime: map['dateTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dateTime'] as int)
          : DateTime.now(),
    );
  }

  // Convert an Item object into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'dateTime': dateTime.millisecondsSinceEpoch,
    };
  }

  // Format amount as currency
  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';

  // Check if the item is an income
  bool get isIncome => type == 'income';

  // Check if the item is an expense
  bool get isExpense => type == 'expense';

  // Create a copy of the item with optional new values
  Item copyWith({
    int? id,
    String? title,
    double? amount,
    String? type,
    String? category,
    DateTime? dateTime,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
    );
  }
}
