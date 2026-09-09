import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../database/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final currencyFormatter = intl.NumberFormat('#,##0', 'ar');

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  bool _isLoading = true;
  Map<String, dynamic> _monthlyStats = {};

  final List<String> _monthNames = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    DateTime start = DateTime(_selectedYear, _selectedMonth, 1);
    DateTime end = DateTime(_selectedYear, _selectedMonth + 1, 0, 23, 59, 59);

    final stats = await _dbHelper.getDashboardStats(start, end);
    setState(() {
      _monthlyStats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير المالية والتحليلية'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month / Year Selector
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        decoration: const InputDecoration(labelText: 'الشهر', border: OutlineInputBorder()),
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(value: index + 1, child: Text(_monthNames[index]));
                        }),
                        onChanged: (m) {
                          setState(() => _selectedMonth = m!);
                          _loadReport();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: const InputDecoration(labelText: 'السنة', border: OutlineInputBorder()),
                        items: [2024, 2025, 2026, 2027].map((y) {
                          return DropdownMenuItem(value: y, child: Text('$y'));
                        }).toList(),
                        onChanged: (y) {
                          setState(() => _selectedYear = y!);
                          _loadReport();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else ...[
              // Comprehensive Executive Summary Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.teal, width: 1.5)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التقرير المالي الإداري الشامل — ${_monthNames[_selectedMonth - 1]} $_selectedYear',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                      ),
                      const Divider(height: 20),
                      _buildReportRow('إجمالي عدد الحالات/المرضى:', '${_monthlyStats['patientCount']} حالة'),
                      _buildReportRow('إجمالي الإيرادات الكلية:', '${currencyFormatter.format(_monthlyStats['totalRevenue'])} ريال', isBold: true),
                      _buildReportRow('إجمالي العمولات المستحقة للأطباء:', '${currencyFormatter.format(_monthlyStats['totalDoctorCommissions'])} ريال', color: Colors.orange.shade800),
                      _buildReportRow('إجمالي المصروفات التشغيلية:', '${currencyFormatter.format(_monthlyStats['totalExpenses'])} ريال', color: Colors.red.shade800),
                      _buildReportRow('إجمالي الديون والمبالغ غير المسددة:', '${currencyFormatter.format(_monthlyStats['totalRemainingDebt'])} ريال', color: Colors.deepOrange),
                      const Divider(),
                      _buildReportRow(
                        'صافي الأرباح النهائية للمركز:',
                        '${currencyFormatter.format(_monthlyStats['netProfit'])} ريال',
                        isBold: true,
                        fontSize: 16,
                        color: Colors.green.shade800,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Executive Insights Banner
              Card(
                color: Colors.amber.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.amber.shade400)),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('مؤشرات الإدارة الذكية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('• يتم احتساب صافي أرباح المركز تلقائياً بعد خصم عمولات الأطباء المحيلين والمصروفات.', style: TextStyle(fontSize: 12)),
                      Text('• التقرير يعتمد على نسب العمولات وقت إجراء الفحص لضمان الدقة المالية عند تغيير النسب.', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value, {bool isBold = false, double fontSize = 13, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: fontSize + 1, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
