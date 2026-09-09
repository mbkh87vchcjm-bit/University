import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../database/database_helper.dart';
import '../models/doctor.dart';
import '../models/doctor_settlement.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final currencyFormatter = intl.NumberFormat('#,##0', 'ar');

  List<Doctor> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    final list = await _dbHelper.getDoctors();
    setState(() {
      _doctors = list;
      _isLoading = false;
    });
  }

  void _showAddEditDoctorModal([Doctor? doctor]) {
    final nameController = TextEditingController(text: doctor?.name ?? '');
    final specialtyController = TextEditingController(text: doctor?.specialty ?? '');
    final phoneController = TextEditingController(text: doctor?.phone ?? '');
    final rateController = TextEditingController(text: doctor?.commissionRate.toString() ?? '10');
    String type = doctor?.commissionType ?? 'percentage';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doctor == null ? 'إضافة طبيب محيل جديد' : 'تعديل بيانات الطبيب'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الطبيب', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: specialtyController, decoration: const InputDecoration(labelText: 'التخصص', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'نوع العمولة', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('نسبة مئوية (%)')),
                  DropdownMenuItem(value: 'fixed', child: Text('مبلغ ثابت لكل حالة (ريال)')),
                ],
                onChanged: (val) => type = val!,
              ),
              const SizedBox(height: 10),
              TextField(controller: rateController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قيمة النسبة/المبلغ', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              if (doctor == null) {
                Doctor newDoc = Doctor(
                  doctorCode: 'DOC-${100 + _doctors.length + 1}',
                  name: nameController.text.trim(),
                  specialty: specialtyController.text.trim(),
                  phone: phoneController.text.trim(),
                  commissionRate: double.tryParse(rateController.text) ?? 0.0,
                  commissionType: type,
                );
                await _dbHelper.insertDoctor(newDoc);
              } else {
                Doctor updatedDoc = Doctor(
                  id: doctor.id,
                  doctorCode: doctor.doctorCode,
                  name: nameController.text.trim(),
                  specialty: specialtyController.text.trim(),
                  phone: phoneController.text.trim(),
                  commissionRate: double.tryParse(rateController.text) ?? 0.0,
                  commissionType: type,
                  isActive: doctor.isActive,
                );
                await _dbHelper.updateDoctor(updatedDoc);
              }

              if (mounted) Navigator.pop(ctx);
              _loadDoctors();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showDoctorReportModal(Doctor doctor) async {
    final report = await _dbHelper.getDoctorReport(doctor.id!);
    final visits = await _dbHelper.getVisits(doctorId: doctor.id);
    final settlements = await _dbHelper.getDoctorSettlements(doctor.id!);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                      Text('التخصص: ${doctor.specialty} | الهاتف: ${doctor.phone}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),

              // Report summary cards
              Card(
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildReportRow('إجمالي عدد الحالات المحالة:', '${report['patientCount']} حالة'),
                      _buildReportRow('إجمالي قيمة فحوصات الإحالة:', '${currencyFormatter.format(report['totalServiceValue'])} ريال'),
                      _buildReportRow('إجمالي عمولة الطبيب المستحقة:', '${currencyFormatter.format(report['totalCommissionEarned'])} ريال', isBold: true, color: Colors.orange.shade900),
                      _buildReportRow('المبلغ المدفوع/المسدد للطبيب:', '${currencyFormatter.format(report['totalSettled'])} ريال', color: Colors.green.shade800),
                      const Divider(),
                      _buildReportRow('الرصيد المتبقي للطبيب:', '${currencyFormatter.format(report['remainingDue'])} ريال', isBold: true, color: Colors.red.shade900),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('عمليات الإحالة والتسوية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: const Text('تسوية حساب الطبيب'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showSettlementDialog(doctor, (report['remainingDue'] as num).toDouble());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Text('سجل زيارات الإحالة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              if (visits.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('لا توجد حالات إحالة لهذا الطبيب بعد')))
              else
                ...visits.map((v) => ListTile(
                      dense: true,
                      title: Text('${v.patientName} - ${v.serviceName}'),
                      subtitle: Text('التاريخ: ${v.visitDate.split("T").first} | الفاتورة: ${v.netAmount} ريال'),
                      trailing: Text('العمولة: ${currencyFormatter.format(v.doctorCommissionValue)} ريال', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    )),

              const SizedBox(height: 12),
              const Text('سجل المدفوعات والتسويات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              if (settlements.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('لم يتم تسديد أي عمولات هذا الشهر')))
              else
                ...settlements.map((s) => ListTile(
                      dense: true,
                      title: Text('تسوية بمبلغ ${currencyFormatter.format(s.amount)} ريال'),
                      subtitle: Text('التاريخ: ${s.settlementDate.split("T").first} | الطريقة: ${s.paymentMethod}'),
                      trailing: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettlementDialog(Doctor doctor, double remainingDue) {
    final amountController = TextEditingController(text: remainingDue.toStringAsFixed(0));
    final notesController = TextEditingController();
    String method = 'نقداً';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تسوية حساب ${doctor.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المبلغ المتبقي للطبيب: ${currencyFormatter.format(remainingDue)} ريال'),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ المدفوع الآن', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: method,
              decoration: const InputDecoration(labelText: 'طريقة الدفع', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'نقداً', child: Text('نقداً')),
                DropdownMenuItem(value: 'تحويل بنكي', child: Text('تحويل بنكي')),
                DropdownMenuItem(value: 'شيك', child: Text('شيك')),
              ],
              onChanged: (v) => method = v!,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'ملاحظات التسوية', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () async {
              double amt = double.tryParse(amountController.text) ?? 0.0;
              if (amt > 0) {
                DoctorSettlement settlement = DoctorSettlement(
                  doctorId: doctor.id!,
                  doctorName: doctor.name,
                  amount: amt,
                  settlementDate: DateTime.now().toIso8601String(),
                  paymentMethod: method,
                  notes: notesController.text.trim(),
                );
                await _dbHelper.insertDoctorSettlement(settlement);
                if (mounted) Navigator.pop(ctx);
                _loadDoctors();
              }
            },
            child: const Text('تسديد العمولات'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأطباء المحيلين والعمولات'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDoctorModal(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة طبيب'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _doctors.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final doc = _doctors[index];
                String commStr = doc.commissionType == 'percentage' ? '${doc.commissionRate}%' : '${currencyFormatter.format(doc.commissionRate)} ريال ثابت';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: Icon(Icons.person, color: Colors.teal.shade900),
                    ),
                    title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text('التخصص: ${doc.specialty} | النسبة: $commStr'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddEditDoctorModal(doc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.assessment, color: Colors.teal),
                          tooltip: 'تقرير كشف حساب الطبيب',
                          onPressed: () => _showDoctorReportModal(doc),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
