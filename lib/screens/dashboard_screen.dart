import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import 'new_visit_screen.dart';
import 'patients_screen.dart';
import 'doctors_screen.dart';
import 'services_screen.dart';
import 'expenses_screen.dart';
import 'reports_screen.dart';
import 'backup_screen.dart';
import 'audit_log_screen.dart';
import 'rag_assistant_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final currencyFormatter = intl.NumberFormat('#,##0', 'ar');

  String _timeRange = 'today'; // 'today', 'month', 'year'
  bool _isLoading = true;

  Map<String, dynamic> _stats = {
    'patientCount': 0,
    'totalRevenue': 0.0,
    'totalDoctorCommissions': 0.0,
    'totalExpenses': 0.0,
    'netProfit': 0.0,
    'totalRemainingDebt': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    DateTime now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (_timeRange == 'today') {
      start = DateTime(now.year, now.month, now.day);
    } else if (_timeRange == 'month') {
      start = DateTime(now.year, now.month, 1);
    } else {
      start = DateTime(now.year, 1, 1);
    }

    final stats = await _dbHelper.getDashboardStats(start, end);
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.local_hospital, color: Colors.teal),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('طبيب أشعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('نظام إدارة مركز الأشعة والحسابات', style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadStats,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time Filter Switcher
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildFilterTab('today', 'اليوم'),
                            _buildFilterTab('month', 'هذا الشهر'),
                            _buildFilterTab('year', 'هذا العام'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stat Cards Grid
                      if (_isLoading)
                        const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                      else ...[
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('عدد المرضى', '${_stats['patientCount']}', Icons.people, Colors.blue)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('إجمالي الإيرادات', '${currencyFormatter.format(_stats['totalRevenue'])} ريال', Icons.account_balance_wallet, Colors.teal)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('عمولات الأطباء', '${currencyFormatter.format(_stats['totalDoctorCommissions'])} ريال', Icons.badge, Colors.orange)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('المصروفات', '${currencyFormatter.format(_stats['totalExpenses'])} ريال', Icons.money_off, Colors.redAccent)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('صافي الربح', '${currencyFormatter.format(_stats['netProfit'])} ريال', Icons.trending_up, Colors.green, isHighlight: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard('الديون والمتبقي', '${currencyFormatter.format(_stats['totalRemainingDebt'])} ريال', Icons.pending_actions, Colors.deepOrange)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Mini Financial Chart
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('مؤشر الأداء المالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 140,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      barGroups: [
                                        BarChartGroupData(
                                          x: 0,
                                          barRods: [BarChartRodData(toY: (_stats['totalRevenue'] as num).toDouble(), color: Colors.teal, width: 22, borderRadius: BorderRadius.circular(4))],
                                        ),
                                        BarChartGroupData(
                                          x: 1,
                                          barRods: [BarChartRodData(toY: (_stats['totalDoctorCommissions'] as num).toDouble(), color: Colors.orange, width: 22, borderRadius: BorderRadius.circular(4))],
                                        ),
                                        BarChartGroupData(
                                          x: 2,
                                          barRods: [BarChartRodData(toY: (_stats['totalExpenses'] as num).toDouble(), color: Colors.redAccent, width: 22, borderRadius: BorderRadius.circular(4))],
                                        ),
                                        BarChartGroupData(
                                          x: 3,
                                          barRods: [BarChartRodData(toY: (_stats['netProfit'] as num).toDouble(), color: Colors.green, width: 22, borderRadius: BorderRadius.circular(4))],
                                        ),
                                      ],
                                      titlesData: FlTitlesData(
                                        show: true,
                                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              switch (value.toInt()) {
                                                case 0: return const Text('الإيراد', style: TextStyle(fontSize: 10));
                                                case 1: return const Text('العمولات', style: TextStyle(fontSize: 10));
                                                case 2: return const Text('المصروفات', style: TextStyle(fontSize: 10));
                                                case 3: return const Text('الربح', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold));
                                                default: return const Text('');
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      gridData: const FlGridData(show: false),
                                      borderData: FlBorderData(show: false),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Quick Actions Menu Grid
                        const Text('أقسام البرنامج الرئيسية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 1.4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildActionCard('تسجيل مريض / زيارة', Icons.add_task, Colors.indigo, () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const NewVisitScreen()));
                              _loadStats();
                            }),
                            _buildActionCard('إدارة المرضى والديون', Icons.people_alt, Colors.blue, () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientsScreen()));
                              _loadStats();
                            }),
                            _buildActionCard('الأطباء والعمولات', Icons.medical_services, Colors.teal, () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorsScreen()));
                              _loadStats();
                            }),
                            _buildActionCard('فحوصات الأشعة', Icons.biotech, Colors.deepPurple, () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesScreen()));
                            }),
                            _buildActionCard('المصروفات التشغيلية', Icons.receipt_long, Colors.red, () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen()));
                              _loadStats();
                            }),
                            _buildActionCard('التقارير الشاملة', Icons.analytics, Colors.amber.shade800, () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                            }),
                            _buildActionCard('النسخ الاحتياطي', Icons.cloud_download, Colors.cyan.shade800, () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen()));
                            }),
                            _buildActionCard('سجل العمليات Audit Log', Icons.history, Colors.grey.shade800, () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogScreen()));
                            }),
                            _buildActionCard('المساعد الذكي للمراجع (RAG)', Icons.psychology, Colors.teal.shade800, () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const RagAssistantScreen()));
                            }),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer Developer Attribution
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.teal.shade900,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('طبيب أشعة v1.0.0', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('المطور محمد الفقيه', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String key, String label) {
    bool isSelected = _timeRange == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _timeRange = key;
          });
          _loadStats();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isHighlight = false}) {
    return Card(
      elevation: isHighlight ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isHighlight ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
