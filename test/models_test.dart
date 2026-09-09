import 'package:flutter_test/flutter_test.dart';
import 'package:tabeeb_ashiah/models/doctor.dart';
import 'package:tabeeb_ashiah/models/patient.dart';
import 'package:tabeeb_ashiah/models/visit.dart';

void main() {
  group('Doctor Model Tests', () {
    test('Percentage commission calculation', () {
      final doctor = Doctor(
        id: 1,
        doctorCode: 'DOC-101',
        name: 'د. محمد',
        specialty: 'عام',
        phone: '770000000',
        commissionRate: 10.0,
        commissionType: 'percentage',
      );

      final commission = doctor.calculateCommission(10000);
      expect(commission, 1000.0);
    });

    test('Fixed commission calculation', () {
      final doctor = Doctor(
        id: 2,
        doctorCode: 'DOC-102',
        name: 'د. خالد',
        specialty: 'مخ وأعصاب',
        phone: '771111111',
        commissionRate: 1500.0,
        commissionType: 'fixed',
      );

      final commission = doctor.calculateCommission(10000);
      expect(commission, 1500.0);
    });
  });

  group('Visit Model Tests', () {
    test('Visit financial serialization & snapshot verification', () {
      final visit = Visit(
        id: 1,
        visitCode: 'VIS-20260909-001',
        invoiceNumber: 'INV-20260909-00125',
        patientId: 10,
        patientName: 'أحمد محمد',
        patientPhone: '772222222',
        doctorId: 1,
        doctorName: 'د. محمد',
        serviceId: 2,
        serviceName: 'CT Scan Brain',
        visitDate: '2026-09-09T10:00:00Z',
        servicePrice: 20000,
        discount: 2000,
        discountReason: 'خصم خاص',
        netAmount: 18000,
        paidAmount: 15000,
        remainingAmount: 3000,
        doctorCommissionType: 'percentage',
        doctorCommissionRate: 10,
        doctorCommissionValue: 1800,
        centerNetIncome: 16200,
        paymentMethod: 'نقداً',
        status: 'متبقي',
        notes: 'ملاحظة تجريبية',
      );

      final map = visit.toMap();
      final restored = Visit.fromMap(map);

      expect(restored.netAmount, 18000.0);
      expect(restored.doctorCommissionValue, 1800.0);
      expect(restored.centerNetIncome, 16200.0);
      expect(restored.remainingAmount, 3000.0);
    });
  });
}
