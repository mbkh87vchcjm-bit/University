import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../database/database_helper.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import 'new_visit_screen.dart';
import '../services/pdf_service.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final currencyFormatter = intl.NumberFormat('#,##0', 'ar');

  List<Patient> _patients = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    final pList = await _dbHelper.getPatients(query: _searchQuery);
    setState(() {
      _patients = pList;
      _isLoading = false;
    });
  }

  void _showPatientDetailsModal(Patient patient) async {
    final visits = await _dbHelper.getVisits(patientId: patient.id);
    double totalNet = visits.fold(0.0, (sum, v) => sum + v.netAmount);
    double totalPaid = visits.fold(0.0, (sum, v) => sum + v.paidAmount);
    double totalRemaining = visits.fold(0.0, (sum, v) => sum + v.remainingAmount);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
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
                      Text(patient.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('رقم الملف: ${patient.patientCode} | الهاتف: ${patient.phone}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(child: _buildSummaryBox('إجمالي الفحوصات', '${currencyFormatter.format(totalNet)} ريال', Colors.teal)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSummaryBox('إجمالي المدفوع', '${currencyFormatter.format(totalPaid)} ريال', Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSummaryBox('المتبقي كدين', '${currencyFormatter.format(totalRemaining)} ريال', Colors.red)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('سجل زيارات المريض:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('زيارة جديدة'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => NewVisitScreen(initialPatient: patient)));
                      _loadPatients();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (visits.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('لا توجد زيارات سابقة لهذا المريض')),
                )
              else
                ...visits.map((v) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text('${v.invoiceNumber} - ${v.serviceName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('التاريخ: ${v.visitDate.split("T").first} | المدفوع: ${currencyFormatter.format(v.paidAmount)} | المتبقي: ${currencyFormatter.format(v.remainingAmount)} ريال'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (v.remainingAmount > 0)
                              IconButton(
                                icon: const Icon(Icons.payment, color: Colors.green),
                                tooltip: 'سداد المتبقي',
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showPayDebtDialog(v);
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.print, color: Colors.blue),
                              tooltip: 'طباعة/مشاركة الفاتورة',
                              onPressed: () => PdfService.printInvoice(v),
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  void _showPayDebtDialog(Visit visit) {
    final controller = TextEditingController(text: visit.remainingAmount.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('سداد دَين الفاتورة ${visit.invoiceNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اسم المريض: ${visit.patientName}'),
            Text('إجمالي المتبقي: ${currencyFormatter.format(visit.remainingAmount)} ريال'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ المسدد الآن', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () async {
              double pay = double.tryParse(controller.text) ?? 0.0;
              if (pay > 0) {
                await _dbHelper.updateVisitPayment(visit.id!, pay);
                if (mounted) Navigator.pop(ctx);
                _loadPatients();
              }
            },
            child: const Text('تأكيد السداد'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade800)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المرضى والديون'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث بواسطة اسم المريض، رقم الملف، أو الهاتف...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
                _loadPatients();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _patients.isEmpty
                    ? const Center(child: Text('لا يوجد مرضى مطابقين للبحث'))
                    : ListView.builder(
                        itemCount: _patients.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (context, index) {
                          final patient = _patients[index];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.shade100,
                                child: Text(
                                  patient.gender == 'ذكر' ? '♂' : '♀',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                                ),
                              ),
                              title: Text('${patient.name} (${patient.patientCode})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('الهاتف: ${patient.phone} | الجنس: ${patient.gender} | العمر: ${patient.age} سنة'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              onTap: () => _showPatientDetailsModal(patient),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
