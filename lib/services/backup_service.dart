import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../models/patient.dart';
import '../models/doctor.dart';
import '../models/medical_service.dart';
import '../models/visit.dart';
import '../models/doctor_settlement.dart';
import '../models/expense.dart';

class BackupService {
  static Future<String> exportBackupToJson() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    final patients = await db.query('patients');
    final doctors = await db.query('doctors');
    final services = await db.query('services');
    final visits = await db.query('visits');
    final doctorSettlements = await db.query('doctor_settlements');
    final expenses = await db.query('expenses');
    final auditLogs = await db.query('audit_logs');

    Map<String, dynamic> backupData = {
      'app': 'طبيب أشعة',
      'developer': 'المطور محمد الفقيه',
      'exportedAt': DateTime.now().toIso8601String(),
      'patients': patients,
      'doctors': doctors,
      'services': services,
      'visits': visits,
      'doctor_settlements': doctorSettlements,
      'expenses': expenses,
      'audit_logs': auditLogs,
    };

    String jsonStr = jsonEncode(backupData);
    final directory = await getApplicationDocumentsDirectory();
    String fileName = 'tabeeb_ashiah_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    File backupFile = File('${directory.path}/$fileName');
    await backupFile.writeAsString(jsonStr);

    return backupFile.path;
  }

  static Future<void> shareBackupFile(String filePath) async {
    final xFile = XFile(filePath);
    await Share.shareXFiles([xFile], text: 'نسخة احتياطية لنظام طبيب أشعة');
  }

  static Future<bool> restoreFromJsonString(String jsonContent) async {
    try {
      Map<String, dynamic> backupData = jsonDecode(jsonContent);
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      await db.transaction((txn) async {
        await txn.delete('visits');
        await txn.delete('patients');
        await txn.delete('doctors');
        await txn.delete('services');
        await txn.delete('doctor_settlements');
        await txn.delete('expenses');

        if (backupData.containsKey('patients')) {
          for (var item in backupData['patients']) {
            await txn.insert('patients', item);
          }
        }
        if (backupData.containsKey('doctors')) {
          for (var item in backupData['doctors']) {
            await txn.insert('doctors', item);
          }
        }
        if (backupData.containsKey('services')) {
          for (var item in backupData['services']) {
            await txn.insert('services', item);
          }
        }
        if (backupData.containsKey('visits')) {
          for (var item in backupData['visits']) {
            await txn.insert('visits', item);
          }
        }
        if (backupData.containsKey('doctor_settlements')) {
          for (var item in backupData['doctor_settlements']) {
            await txn.insert('doctor_settlements', item);
          }
        }
        if (backupData.containsKey('expenses')) {
          for (var item in backupData['expenses']) {
            await txn.insert('expenses', item);
          }
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
