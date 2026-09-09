class Expense {
  final int? id;
  final String title;
  final String category;
  final double amount;
  final String expenseDate;
  final String notes;

  Expense({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.expenseDate,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'expenseDate': expenseDate,
      'notes': notes,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'] ?? '',
      category: map['category'] ?? 'عام',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: map['expenseDate'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}
