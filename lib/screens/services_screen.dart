import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../database/database_helper.dart';
import '../models/medical_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final currencyFormatter = intl.NumberFormat('#,##0', 'ar');

  List<MedicalService> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    final list = await _dbHelper.getServices();
    setState(() {
      _services = list;
      _isLoading = false;
    });
  }

  void _showAddEditServiceModal([MedicalService? service]) {
    final nameController = TextEditingController(text: service?.name ?? '');
    final priceController = TextEditingController(text: service?.defaultPrice.toStringAsFixed(0) ?? '');
    final categoryController = TextEditingController(text: service?.category ?? 'أشعة عامة');
    final durationController = TextEditingController(text: service?.durationMinutes.toString() ?? '15');
    final notesController = TextEditingController(text: service?.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(service == null ? 'إضافة فحص أشعة جديد' : 'تعديل بيانات الفحص'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الفحص / الخدمة', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر الافتراضي (ريال)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'القسم / التصنيف', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: durationController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المدة التقريبية (بالدقائق)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'ملاحظات وتوجيهات', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              MedicalService item = MedicalService(
                id: service?.id,
                name: nameController.text.trim(),
                defaultPrice: double.tryParse(priceController.text) ?? 0.0,
                category: categoryController.text.trim(),
                durationMinutes: int.tryParse(durationController.text) ?? 15,
                notes: notesController.text.trim(),
              );

              if (service == null) {
                await _dbHelper.insertService(item);
              } else {
                await _dbHelper.updateService(item);
              }

              if (mounted) Navigator.pop(ctx);
              _loadServices();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل فحوصات الأشعة والخدمات'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditServiceModal(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة فحص'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _services.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final s = _services[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade50,
                      child: const Icon(Icons.biotech, color: Colors.teal),
                    ),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text('القسم: ${s.category} | المدة: ${s.durationMinutes} دقيقة'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${currencyFormatter.format(s.defaultPrice)} ريال',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddEditServiceModal(s),
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
