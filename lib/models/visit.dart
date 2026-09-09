class Visit {
  final int? id;
  final String visitCode;
  final String invoiceNumber;
  final int patientId;
  final String patientName;
  final String patientPhone;
  final int? doctorId;
  final String? doctorName;
  final int serviceId;
  final String serviceName;
  final String visitDate;
  final double servicePrice;
  final double discount;
  final String discountReason;
  final double netAmount;
  final double paidAmount;
  final double remainingAmount;
  final String doctorCommissionType;
  final double doctorCommissionRate;
  final double doctorCommissionValue;
  final double centerNetIncome;
  final String paymentMethod;
  final String status;
  final String notes;

  Visit({
    this.id,
    required this.visitCode,
    required this.invoiceNumber,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    this.doctorId,
    this.doctorName,
    required this.serviceId,
    required this.serviceName,
    required this.visitDate,
    required this.servicePrice,
    required this.discount,
    required this.discountReason,
    required this.netAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.doctorCommissionType,
    required this.doctorCommissionRate,
    required this.doctorCommissionValue,
    required this.centerNetIncome,
    required this.paymentMethod,
    required this.status,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visitCode': visitCode,
      'invoiceNumber': invoiceNumber,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'visitDate': visitDate,
      'servicePrice': servicePrice,
      'discount': discount,
      'discountReason': discountReason,
      'netAmount': netAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'doctorCommissionType': doctorCommissionType,
      'doctorCommissionRate': doctorCommissionRate,
      'doctorCommissionValue': doctorCommissionValue,
      'centerNetIncome': centerNetIncome,
      'paymentMethod': paymentMethod,
      'status': status,
      'notes': notes,
    };
  }

  factory Visit.fromMap(Map<String, dynamic> map) {
    return Visit(
      id: map['id'],
      visitCode: map['visitCode'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      patientId: map['patientId'] ?? 0,
      patientName: map['patientName'] ?? '',
      patientPhone: map['patientPhone'] ?? '',
      doctorId: map['doctorId'],
      doctorName: map['doctorName'],
      serviceId: map['serviceId'] ?? 0,
      serviceName: map['serviceName'] ?? '',
      visitDate: map['visitDate'] ?? '',
      servicePrice: (map['servicePrice'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      discountReason: map['discountReason'] ?? '',
      netAmount: (map['netAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      doctorCommissionType: map['doctorCommissionType'] ?? 'percentage',
      doctorCommissionRate: (map['doctorCommissionRate'] as num?)?.toDouble() ?? 0.0,
      doctorCommissionValue: (map['doctorCommissionValue'] as num?)?.toDouble() ?? 0.0,
      centerNetIncome: (map['centerNetIncome'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'نقداً',
      status: map['status'] ?? 'مكتمل',
      notes: map['notes'] ?? '',
    );
  }
}
