import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../models/doctor.dart';
import '../models/medical_service.dart';
import '../models/visit.dart';
import '../models/doctor_settlement.dart';
import '../models/expense.dart';
import '../models/audit_log.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'tabeeb_ashiah.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientCode TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        gender TEXT NOT NULL,
        age INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE doctors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doctorCode TEXT NOT NULL,
        name TEXT NOT NULL,
        specialty TEXT NOT NULL,
        phone TEXT NOT NULL,
        commissionRate REAL NOT NULL,
        commissionType TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        defaultPrice REAL NOT NULL,
        category TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visitCode TEXT NOT NULL,
        invoiceNumber TEXT NOT NULL,
        patientId INTEGER NOT NULL,
        patientName TEXT NOT NULL,
        patientPhone TEXT NOT NULL,
        doctorId INTEGER,
        doctorName TEXT,
        serviceId INTEGER NOT NULL,
        serviceName TEXT NOT NULL,
        visitDate TEXT NOT NULL,
        servicePrice REAL NOT NULL,
        discount REAL NOT NULL,
        discountReason TEXT,
        netAmount REAL NOT NULL,
        paidAmount REAL NOT NULL,
        remainingAmount REAL NOT NULL,
        doctorCommissionType TEXT NOT NULL,
        doctorCommissionRate REAL NOT NULL,
        doctorCommissionValue REAL NOT NULL,
        centerNetIncome REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE doctor_settlements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doctorId INTEGER NOT NULL,
        doctorName TEXT NOT NULL,
        amount REAL NOT NULL,
        settlementDate TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        expenseDate TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        userName TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        details TEXT NOT NULL
      )
    ''');

    // Seed default standard Radiology Services
    await _seedDefaultData(db);
  }

  Future<void> _seedDefaultData(Database db) async {
    List<MedicalService> defaultServices = [
      MedicalService(name: 'أشعة الصدر X-Ray Chest', defaultPrice: 10000, category: 'X-Ray', durationMinutes: 10),
      MedicalService(name: 'أشعة مقطعية للمخ CT Scan Brain', defaultPrice: 35000, category: 'CT Scan', durationMinutes: 20),
      MedicalService(name: 'رنين مغناطيسي للعمود الفقري MRI Spine', defaultPrice: 60000, category: 'MRI', durationMinutes: 30),
      MedicalService(name: 'موجات صوتية للبطن والحوض Ultrasound Abdomen', defaultPrice: 15000, category: 'Ultrasound', durationMinutes: 15),
      MedicalService(name: 'أشعة الثدي Mammography', defaultPrice: 25000, category: 'Mammography', durationMinutes: 20),
      MedicalService(name: 'أشعة أسنان بانوراما Dental Panoramic X-Ray', defaultPrice: 12000, category: 'Dental X-Ray', durationMinutes: 10),
    ];

    for (var service in defaultServices) {
      await db.insert('services', service.toMap());
    }

    // Seed initial doctors
    List<Doctor> defaultDoctors = [
      Doctor(doctorCode: 'DOC-101', name: 'د. أحمد علي', specialty: 'باطنية عامة', phone: '771234567', commissionRate: 10, commissionType: 'percentage'),
      Doctor(doctorCode: 'DOC-102', name: 'د. محمد حسن', specialty: 'عظام ومفاصل', phone: '772345678', commissionRate: 15, commissionType: 'percentage'),
      Doctor(doctorCode: 'DOC-103', name: 'د. خالد العمري', specialty: 'مخ وأعصاب', phone: '773456789', commissionRate: 2000, commissionType: 'fixed'),
    ];

    for (var doc in defaultDoctors) {
      await db.insert('doctors', doc.toMap());
    }

    // Seed initial sample patient & visit if starting up
    int patientId = await db.insert('patients', Patient(
      patientCode: 'P-10001',
      name: 'أحمد محمد عبدالله',
      phone: '770000001',
      gender: 'ذكر',
      age: 35,
      createdAt: DateTime.now().toIso8601String(),
    ).toMap());

    String todayIso = DateTime.now().toIso8601String();
    String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());

    await db.insert('visits', Visit(
      visitCode: 'VIS-$formattedDate-00001',
      invoiceNumber: 'INV-$formattedDate-00001',
      patientId: patientId,
      patientName: 'أحمد محمد عبدالله',
      patientPhone: '770000001',
      doctorId: 1,
      doctorName: 'د. أحمد علي',
      serviceId: 1,
      serviceName: 'أشعة الصدر X-Ray Chest',
      visitDate: todayIso,
      servicePrice: 10000,
      discount: 0,
      discountReason: '',
      netAmount: 10000,
      paidAmount: 10000,
      remainingAmount: 0,
      doctorCommissionType: 'percentage',
      doctorCommissionRate: 10,
      doctorCommissionValue: 1000,
      centerNetIncome: 9000,
      paymentMethod: 'نقداً',
      status: 'مكتمل',
      notes: 'زيارة أولية ممتازة',
    ).toMap());

    // Seed Audit Log
    await db.insert('audit_logs', AuditLog(
      action: 'إنشاء النظام',
      userName: 'المطور محمد الفقيه',
      timestamp: todayIso,
      details: 'تم التهيئة وتوليد البيانات الأولية للنظام بنجاح',
    ).toMap());
  }

  // --- Patients CRUD ---
  Future<int> insertPatient(Patient patient) async {
    final db = await database;
    return await db.insert('patients', patient.toMap());
  }

  Future<List<Patient>> getPatients({String? query}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (query != null && query.trim().isNotEmpty) {
      maps = await db.query(
        'patients',
        where: 'patientCode LIKE ? OR name LIKE ? OR phone LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'id DESC',
      );
    } else {
      maps = await db.query('patients', orderBy: 'id DESC');
    }
    return maps.map((e) => Patient.fromMap(e)).toList();
  }

  Future<Patient?> getPatientById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('patients', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Patient.fromMap(maps.first);
    }
    return null;
  }

  Future<int> generateNextPatientNumber() async {
    final db = await database;
    var result = await db.rawQuery('SELECT MAX(id) as max_id FROM patients');
    int maxId = (result.first['max_id'] as int?) ?? 0;
    return maxId + 1;
  }

  // --- Doctors CRUD ---
  Future<int> insertDoctor(Doctor doctor) async {
    final db = await database;
    return await db.insert('doctors', doctor.toMap());
  }

  Future<int> updateDoctor(Doctor doctor) async {
    final db = await database;
    return await db.update('doctors', doctor.toMap(), where: 'id = ?', whereArgs: [doctor.id]);
  }

  Future<List<Doctor>> getDoctors({bool activeOnly = false}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (activeOnly) {
      maps = await db.query('doctors', where: 'isActive = 1', orderBy: 'name ASC');
    } else {
      maps = await db.query('doctors', orderBy: 'name ASC');
    }
    return maps.map((e) => Doctor.fromMap(e)).toList();
  }

  // --- Medical Services CRUD ---
  Future<int> insertService(MedicalService service) async {
    final db = await database;
    return await db.insert('services', service.toMap());
  }

  Future<int> updateService(MedicalService service) async {
    final db = await database;
    return await db.update('services', service.toMap(), where: 'id = ?', whereArgs: [service.id]);
  }

  Future<int> deleteService(int id) async {
    final db = await database;
    return await db.delete('services', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MedicalService>> getServices() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('services', orderBy: 'name ASC');
    return maps.map((e) => MedicalService.fromMap(e)).toList();
  }

  // --- Visits CRUD ---
  Future<int> insertVisit(Visit visit) async {
    final db = await database;
    int id = await db.insert('visits', visit.toMap());

    // Record Audit Log
    await db.insert('audit_logs', AuditLog(
      action: 'تسجيل زيارة جديد',
      userName: 'الموظف',
      timestamp: DateTime.now().toIso8601String(),
      details: 'تم إضافة فاتورة رقم ${visit.invoiceNumber} للمريض ${visit.patientName} بمبلغ ${visit.netAmount}',
    ).toMap());

    return id;
  }

  Future<int> updateVisitPayment(int visitId, double additionalPaid) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('visits', where: 'id = ?', whereArgs: [visitId]);
    if (maps.isEmpty) return 0;

    Visit visit = Visit.fromMap(maps.first);
    double newPaid = visit.paidAmount + additionalPaid;
    double newRemaining = visit.netAmount - newPaid;
    if (newRemaining < 0) newRemaining = 0;
    String newStatus = newRemaining <= 0 ? 'مكتمل' : 'متبقي';

    int rows = await db.update(
      'visits',
      {
        'paidAmount': newPaid,
        'remainingAmount': newRemaining,
        'status': newStatus,
      },
      where: 'id = ?',
      whereArgs: [visitId],
    );

    await db.insert('audit_logs', AuditLog(
      action: 'تحديث سداد فاتورة',
      userName: 'الموظف',
      timestamp: DateTime.now().toIso8601String(),
      details: 'سداد مبلغ $additionalPaid للفاتورة ${visit.invoiceNumber}. المتبقي: $newRemaining',
    ).toMap());

    return rows;
  }

  Future<List<Visit>> getVisits({String? searchQuery, DateTime? startDate, DateTime? endDate, int? doctorId, int? patientId}) async {
    final db = await database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(invoiceNumber LIKE ? OR patientName LIKE ? OR patientPhone LIKE ? OR serviceName LIKE ?)');
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%', '%$searchQuery%', '%$searchQuery%']);
    }

    if (startDate != null) {
      whereClauses.add('visitDate >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('visitDate <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    if (doctorId != null) {
      whereClauses.add('doctorId = ?');
      whereArgs.add(doctorId);
    }

    if (patientId != null) {
      whereClauses.add('patientId = ?');
      whereArgs.add(patientId);
    }

    String? whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    List<Map<String, dynamic>> maps = await db.query(
      'visits',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'id DESC',
    );

    return maps.map((e) => Visit.fromMap(e)).toList();
  }

  Future<int> generateNextVisitNumber() async {
    final db = await database;
    var result = await db.rawQuery('SELECT MAX(id) as max_id FROM visits');
    int maxId = (result.first['max_id'] as int?) ?? 0;
    return maxId + 1;
  }

  // --- Doctor Settlements CRUD ---
  Future<int> insertDoctorSettlement(DoctorSettlement settlement) async {
    final db = await database;
    int id = await db.insert('doctor_settlements', settlement.toMap());

    await db.insert('audit_logs', AuditLog(
      action: 'تسوية حساب طبيب',
      userName: 'المحاسب',
      timestamp: DateTime.now().toIso8601String(),
      details: 'تم تسديد مبلغ ${settlement.amount} للطبيب ${settlement.doctorName}',
    ).toMap());

    return id;
  }

  Future<List<DoctorSettlement>> getDoctorSettlements(int doctorId) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'doctor_settlements',
      where: 'doctorId = ?',
      whereArgs: [doctorId],
      orderBy: 'id DESC',
    );
    return maps.map((e) => DoctorSettlement.fromMap(e)).toList();
  }

  // --- Expenses CRUD ---
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    int id = await db.insert('expenses', expense.toMap());

    await db.insert('audit_logs', AuditLog(
      action: 'إضافة مصروف',
      userName: 'المحاسب',
      timestamp: DateTime.now().toIso8601String(),
      details: 'إضافة مصروف ${expense.title} بمبلغ ${expense.amount} ريال (${expense.category})',
    ).toMap());

    return id;
  }

  Future<List<Expense>> getExpenses({DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClauses.add('expenseDate >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('expenseDate <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    String? whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'id DESC',
    );

    return maps.map((e) => Expense.fromMap(e)).toList();
  }

  // --- Financial Statistics & Reports ---
  Future<Map<String, dynamic>> getDashboardStats(DateTime start, DateTime end) async {
    final db = await database;
    String startIso = start.toIso8601String();
    String endIso = end.toIso8601String();

    var visitsResult = await db.rawQuery('''
      SELECT
        COUNT(id) as patientCount,
        COALESCE(SUM(netAmount), 0) as totalRevenue,
        COALESCE(SUM(paidAmount), 0) as totalPaid,
        COALESCE(SUM(remainingAmount), 0) as totalRemainingDebt,
        COALESCE(SUM(doctorCommissionValue), 0) as totalDoctorCommissions,
        COALESCE(SUM(centerNetIncome), 0) as totalCenterIncome
      FROM visits
      WHERE visitDate >= ? AND visitDate <= ?
    ''', [startIso, endIso]);

    var expensesResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as totalExpenses
      FROM expenses
      WHERE expenseDate >= ? AND expenseDate <= ?
    ''', [startIso, endIso]);

    var activeDoctorsResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT doctorId) as activeDoctorCount
      FROM visits
      WHERE visitDate >= ? AND visitDate <= ? AND doctorId IS NOT NULL
    ''', [startIso, endIso]);

    Map<String, dynamic> vData = visitsResult.first;
    double totalRevenue = (vData['totalRevenue'] as num).toDouble();
    double totalDoctorCommissions = (vData['totalDoctorCommissions'] as num).toDouble();
    double totalExpenses = (expensesResult.first['totalExpenses'] as num).toDouble();
    double netProfit = totalRevenue - totalDoctorCommissions - totalExpenses;

    return {
      'patientCount': vData['patientCount'],
      'totalRevenue': totalRevenue,
      'totalPaid': (vData['totalPaid'] as num).toDouble(),
      'totalRemainingDebt': (vData['totalRemainingDebt'] as num).toDouble(),
      'totalDoctorCommissions': totalDoctorCommissions,
      'totalCenterIncome': (vData['totalCenterIncome'] as num).toDouble(),
      'totalExpenses': totalExpenses,
      'netProfit': netProfit,
      'activeDoctorCount': activeDoctorsResult.first['activeDoctorCount'],
    };
  }

  Future<Map<String, dynamic>> getDoctorReport(int doctorId) async {
    final db = await database;
    var visitsResult = await db.rawQuery('''
      SELECT
        COUNT(id) as patientCount,
        COALESCE(SUM(netAmount), 0) as totalServiceValue,
        COALESCE(SUM(doctorCommissionValue), 0) as totalCommissionEarned
      FROM visits
      WHERE doctorId = ?
    ''', [doctorId]);

    var settlementsResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as totalSettled
      FROM doctor_settlements
      WHERE doctorId = ?
    ''', [doctorId]);

    double earned = (visitsResult.first['totalCommissionEarned'] as num).toDouble();
    double settled = (settlementsResult.first['totalSettled'] as num).toDouble();
    double remainingDue = earned - settled;

    return {
      'patientCount': visitsResult.first['patientCount'],
      'totalServiceValue': (visitsResult.first['totalServiceValue'] as num).toDouble(),
      'totalCommissionEarned': earned,
      'totalSettled': settled,
      'remainingDue': remainingDue,
    };
  }

  // --- Audit Logs ---
  Future<List<AuditLog>> getAuditLogs() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('audit_logs', orderBy: 'id DESC', limit: 100);
    return maps.map((e) => AuditLog.fromMap(e)).toList();
  }
}
