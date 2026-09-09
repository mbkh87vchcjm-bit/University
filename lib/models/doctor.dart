class Doctor {
  final int? id;
  final String doctorCode;
  final String name;
  final String specialty;
  final String phone;
  final double commissionRate;
  final String commissionType; // 'percentage' or 'fixed'
  final bool isActive;

  Doctor({
    this.id,
    required this.doctorCode,
    required this.name,
    required this.specialty,
    required this.phone,
    required this.commissionRate,
    required this.commissionType,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorCode': doctorCode,
      'name': name,
      'specialty': specialty,
      'phone': phone,
      'commissionRate': commissionRate,
      'commissionType': commissionType,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'],
      doctorCode: map['doctorCode'] ?? '',
      name: map['name'] ?? '',
      specialty: map['specialty'] ?? '',
      phone: map['phone'] ?? '',
      commissionRate: (map['commissionRate'] as num?)?.toDouble() ?? 0.0,
      commissionType: map['commissionType'] ?? 'percentage',
      isActive: map['isActive'] == 1,
    );
  }

  /// Calculates commission amount based on a net price
  double calculateCommission(double netPrice) {
    if (commissionType == 'percentage') {
      return (netPrice * commissionRate) / 100.0;
    } else {
      return commissionRate;
    }
  }
}
