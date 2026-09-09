import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../database/database_helper.dart';
import '../models/patient.dart';
import '../models/doctor.dart';
import '../models/medical_service.dart';
import '../models/visit.dart';
import '../services/pdf_service.dart';

class NewVisitScreen extends StatefulWidget {
  final Patient? initialPatient;
  const NewVisitScreen({super.key, this.initialPatient});

  @override
  State<NewVisitScreen> createState() => _NewVisitScreenState();
}

class _NewVisitScreenState extends State<NewVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final currencyFormatter = intl.NumberFormat('#,##0', 'ar');

  List<Patient> _patients = [];
  List<Doctor> _doctors = [];
  List<MedicalService> _services = [];

  Patient? _selectedPatient;
  Doctor? _selectedDoctor;
  MedicalService? _selectedService;

  // New patient controllers if creating new
  bool _isCreatingNewPatient = false;
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _patientPhoneController = TextEditingController();
  final TextEditingController _patientAgeController = TextEditingController();
  String _patientGender = 'ذكر';

  // Visit financial controllers
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _discountReasonController = TextEditingController();
  final TextEditingController _paidController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _paymentMethod = 'نقداً';

  double _calculatedNet = 0.0;
  double _calculatedDoctorCommission = 0.0;
  double _calculatedCenterIncome = 0.0;
  double _calculatedRemaining = 0.0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final pList = await _dbHelper.getPatients();
    final dList = await _dbHelper.getDoctors(activeOnly: true);
    final sList = await _dbHelper.getServices();

    setState(() {
      _patients = pList;
      _doctors = dList;
      _services = sList;

      if (widget.initialPatient != null) {
        _selectedPatient = pList.firstWhere((p) => p.id == widget.initialPatient!.id, orElse: () => widget.initialPatient!);
      }

      _isLoading = false;
    });
  }

  void _onServiceSelected(MedicalService? service) {
    if (service == null) return;
    setState(() {
      _selectedService = service;
      _priceController.text = service.defaultPrice.toStringAsFixed(0);
      _paidController.text = service.defaultPrice.toStringAsFixed(0);
      _recalculateFinancials();
    });
  }

  void _onDoctorSelected(Doctor? doctor) {
    setState(() {
      _selectedDoctor = doctor;
      _recalculateFinancials();
    });
  }

  void _recalculateFinancials() {
    double price = double.tryParse(_priceController.text) ?? 0.0;
    double discount = double.tryParse(_discountController.text) ?? 0.0;
    double paid = double.tryParse(_paidController.text) ?? 0.0;

    double net = price - discount;
    if (net < 0) net = 0;

    double commission = 0.0;
    if (_selectedDoctor != null) {
      commission = _selectedDoctor!.calculateCommission(net);
    }

    double centerNet = net - commission;
    double remaining = net - paid;
    if (remaining < 0) remaining = 0;

    setState(() {
      _calculatedNet = net;
      _calculatedDoctorCommission = commission;
      _calculatedCenterIncome = centerNet;
      _calculatedRemaining = remaining;
    });
  }

  Future<void> _saveVisit() async {
    if (!_formKey.currentState!.validate()) return;

    int patientId;
    String patientName;
    String patientPhone;

    if (_isCreatingNewPatient || _selectedPatient == null) {
      if (_patientNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال اسم المريض')));
        return;
      }

      int nextNum = await _dbHelper.generateNextPatientNumber();
      String pCode = 'P-${10000 + nextNum}';
      Patient newP = Patient(
        patientCode: pCode,
        name: _patientNameController.text.trim(),
        phone: _patientPhoneController.text.trim(),
        gender: _patientGender,
        age: int.tryParse(_patientAgeController.text) ?? 0,
        createdAt: DateTime.now().toIso8601String(),
      );

      patientId = await _dbHelper.insertPatient(newP);
      patientName = newP.name;
      patientPhone = newP.phone;
    } else {
      patientId = _selectedPatient!.id!;
      patientName = _selectedPatient!.name;
      patientPhone = _selectedPatient!.phone;
    }

    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار نوع الفحص')));
      return;
    }

    int nextVisitNum = await _dbHelper.generateNextVisitNumber();
    String dateStr = intl.DateFormat('yyyyMMdd').format(DateTime.now());
    String visitCode = 'VIS-$dateStr-${nextVisitNum.toString().padLeft(4, '0')}';
    String invoiceNum = 'INV-$dateStr-${nextVisitNum.toString().padLeft(4, '0')}';

    double price = double.tryParse(_priceController.text) ?? 0.0;
    double discount = double.tryParse(_discountController.text) ?? 0.0;
    double paid = double.tryParse(_paidController.text) ?? 0.0;

    Visit visit = Visit(
      visitCode: visitCode,
      invoiceNumber: invoiceNum,
      patientId: patientId,
      patientName: patientName,
      patientPhone: patientPhone,
      doctorId: _selectedDoctor?.id,
      doctorName: _selectedDoctor?.name,
      serviceId: _selectedService!.id!,
      serviceName: _selectedService!.name,
      visitDate: DateTime.now().toIso8601String(),
      servicePrice: price,
      discount: discount,
      discountReason: _discountReasonController.text.trim(),
      netAmount: _calculatedNet,
      paidAmount: paid,
      remainingAmount: _calculatedRemaining,
      doctorCommissionType: _selectedDoctor?.commissionType ?? 'none',
      doctorCommissionRate: _selectedDoctor?.commissionRate ?? 0.0,
      doctorCommissionValue: _calculatedDoctorCommission,
      centerNetIncome: _calculatedCenterIncome,
      paymentMethod: _paymentMethod,
      status: _calculatedRemaining > 0 ? 'متبقي' : 'مكتمل',
      notes: _notesController.text.trim(),
    );

    await _dbHelper.insertVisit(visit);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('تم حفظ الزيارة بنجاح'),
          ],
        ),
        content: Text('رقم الفاتورة: ${visit.invoiceNumber}\nالمبلغ الصافي: ${currencyFormatter.format(visit.netAmount)} ريال'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('إغلاق'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('طباعة / مشاركة الفاتورة'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await PdfService.printInvoice(visit);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل زيارة وفاتورة جديدة'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Section
                    _buildSectionHeader('1. بيانات المريض', Icons.person),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<bool>(
                                    title: const Text('مريض مسجل سابقاً', style: TextStyle(fontSize: 13)),
                                    value: false,
                                    groupValue: _isCreatingNewPatient,
                                    onChanged: (val) => setState(() => _isCreatingNewPatient = val!),
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<bool>(
                                    title: const Text('+ مريض جديد', style: TextStyle(fontSize: 13)),
                                    value: true,
                                    groupValue: _isCreatingNewPatient,
                                    onChanged: (val) => setState(() => _isCreatingNewPatient = val!),
                                  ),
                                ),
                              ],
                            ),
                            if (!_isCreatingNewPatient) ...[
                              DropdownButtonFormField<Patient>(
                                value: _selectedPatient,
                                decoration: const InputDecoration(labelText: 'اختر المريض', border: OutlineInputBorder()),
                                items: _patients.map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text('${p.patientCode} - ${p.name} (${p.phone})'),
                                  );
                                }).toList(),
                                onChanged: (p) => setState(() => _selectedPatient = p),
                              ),
                            ] else ...[
                              TextFormField(
                                controller: _patientNameController,
                                decoration: const InputDecoration(labelText: 'اسم المريض الثلاثي', border: OutlineInputBorder()),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _patientPhoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _patientAgeController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'العمر', border: OutlineInputBorder()),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                value: _patientGender,
                                decoration: const InputDecoration(labelText: 'الجنس', border: OutlineInputBorder()),
                                items: const [
                                  DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                                  DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                                ],
                                onChanged: (g) => setState(() => _patientGender = g!),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Service Section
                    _buildSectionHeader('2. بيانات الفحص الطبي', Icons.biotech),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            DropdownButtonFormField<MedicalService>(
                              value: _selectedService,
                              decoration: const InputDecoration(labelText: 'اختر نوع الأشعة / الفحص', border: OutlineInputBorder()),
                              items: _services.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text('${s.name} - (${currencyFormatter.format(s.defaultPrice)} ريال)'),
                                );
                              }).toList(),
                              onChanged: _onServiceSelected,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'سعر الفحص (قابل للتعديل)', border: OutlineInputBorder()),
                              onChanged: (_) => _recalculateFinancials(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Referring Doctor
                    _buildSectionHeader('3. بيانات الإحالة والعمولة', Icons.badge),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            DropdownButtonFormField<Doctor?>(
                              value: _selectedDoctor,
                              decoration: const InputDecoration(labelText: 'الطبيب المحيل (اختياري)', border: OutlineInputBorder()),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('بدون طبيب محيل (حالة مباشرة)')),
                                ..._doctors.map((d) {
                                  String rateStr = d.commissionType == 'percentage' ? '${d.commissionRate}%' : '${d.commissionRate} ريال ثابت';
                                  return DropdownMenuItem(
                                    value: d,
                                    child: Text('${d.name} ($rateStr)'),
                                  );
                                }),
                              ],
                              onChanged: _onDoctorSelected,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Discounts & Payment
                    _buildSectionHeader('4. الخصم والمبلغ المدفوع', Icons.payments),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _discountController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'الخصم (ريال)', border: OutlineInputBorder()),
                                    onChanged: (_) => _recalculateFinancials(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _discountReasonController,
                                    decoration: const InputDecoration(labelText: 'سبب الخصم', border: OutlineInputBorder()),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _paidController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'المبلغ المدفوع', border: OutlineInputBorder()),
                                    onChanged: (_) => _recalculateFinancials(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _paymentMethod,
                                    decoration: const InputDecoration(labelText: 'طريقة الدفع', border: OutlineInputBorder()),
                                    items: const [
                                      DropdownMenuItem(value: 'نقداً', child: Text('نقداً')),
                                      DropdownMenuItem(value: 'شبكة', child: Text('شبكة')),
                                      DropdownMenuItem(value: 'تحويل', child: Text('تحويل')),
                                    ],
                                    onChanged: (val) => setState(() => _paymentMethod = val!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(labelText: 'ملاحظات الزيارة', border: OutlineInputBorder()),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Live Calculation Preview Card
                    Card(
                      color: Colors.teal.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.teal)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('المعاينة الحسابية للعملية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal)),
                            const Divider(),
                            _buildPreviewRow('المبلغ الصافي للفاتورة:', '${currencyFormatter.format(_calculatedNet)} ريال'),
                            _buildPreviewRow('عمولة الطبيب المستحقة:', '${currencyFormatter.format(_calculatedDoctorCommission)} ريال', color: Colors.orange.shade800),
                            _buildPreviewRow('صافي دخل المركز:', '${currencyFormatter.format(_calculatedCenterIncome)} ريال', color: Colors.green.shade800, isBold: true),
                            _buildPreviewRow('المبلغ المتبقي كدين:', '${currencyFormatter.format(_calculatedRemaining)} ريال', color: _calculatedRemaining > 0 ? Colors.red : Colors.black),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('حفظ العملية وإصدار الفاتورة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saveVisit,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
