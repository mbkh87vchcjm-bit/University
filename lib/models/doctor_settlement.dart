class DoctorSettlement {
  final int? id;
  final int doctorId;
  final String doctorName;
  final double amount;
  final String settlementDate;
  final String paymentMethod;
  final String notes;

  DoctorSettlement({
    this.id,
    required this.doctorId,
    required this.doctorName,
    required this.amount,
    required this.settlementDate,
    required this.paymentMethod,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'amount': amount,
      'settlementDate': settlementDate,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  factory DoctorSettlement.fromMap(Map<String, dynamic> map) {
    return DoctorSettlement(
      id: map['id'],
      doctorId: map['doctorId'] ?? 0,
      doctorName: map['doctorName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      settlementDate: map['settlementDate'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'نقداً',
      notes: map['notes'] ?? '',
    );
  }
}
