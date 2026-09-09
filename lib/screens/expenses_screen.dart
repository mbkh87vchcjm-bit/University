import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../database/database_helper.dart';
import '../models/expense.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final currencyFormatter = intl.NumberFormat('#,##0', 'ar');

  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    final list = await _dbHelper.getExpenses();
    setState(() {
      _expenses = list;
      _isLoading = false;
    });
  }

  void _showAddExpenseModal() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String category = 'كهرباء';

    List<String> categories = ['كهرباء', 'إنترنت', 'رواتب', 'صيانة جهاز الأشعة', 'مواد تشغيل', 'إيجار', 'مشتريات', 'مصاريف أخرى'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل مصروف تشغيلي جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'بيان / عنوان المصروف', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'التصنيف', border: OutlineInputBorder()),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => category = v!,
              ),
              const SizedBox(height: 10),
              TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ (ريال)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'ملاحظات إضافية', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              double amt = double.tryParse(amountController.text) ?? 0.0;
              if (amt <= 0) return;

              Expense item = Expense(
                title: titleController.text.trim(),
                category: category,
                amount: amt,
                expenseDate: DateTime.now().toIso8601String(),
                notes: notesController.text.trim(),
              );

              await _dbHelper.insertExpense(item);
              if (mounted) Navigator.pop(ctx);
              _loadExpenses();
            },
            child: const Text('إضافة المصروف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalExpenses = _expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المصروفات النثرية والتشغيلية'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseModal,
        icon: const Icon(Icons.add),
        label: const Text('تسجيل مصروف'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.red.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('إجمالي المصروفات المسجلة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('${currencyFormatter.format(totalExpenses)} ريال', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
                    ],
                  ),
                ),
                Expanded(
                  child: _expenses.isEmpty
                      ? const Center(child: Text('لا توجد مصروفات مسجلة'))
                      : ListView.builder(
                          itemCount: _expenses.length,
                          padding: const EdgeInsets.all(12),
                          itemBuilder: (context, index) {
                            final item = _expenses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red.shade100,
                                  child: Icon(Icons.receipt_long, color: Colors.red.shade900),
                                ),
                                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text('التصنيف: ${item.category} | التاريخ: ${item.expenseDate.split("T").first}'),
                                trailing: Text(
                                  '- ${currencyFormatter.format(item.amount)} ريال',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14),
                                ),
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
