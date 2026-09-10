import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isExporting = false;
  bool _isRestoring = false;

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);
    try {
      String filePath = await BackupService.exportBackupToJson();
      setState(() => _isExporting = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنشاء النسخة الاحتياطية بنجاح:\n$filePath')));

      await BackupService.shareBackupFile(filePath);
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء التصدير: $e')));
      }
    }
  }

  Future<void> _restoreBackup() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isRestoring = true);
      File file = File(result.files.single.path!);
      String content = await file.readAsString();

      bool success = await BackupService.restoreFromJsonString(content);
      setState(() => _isRestoring = false);

      if (!mounted) return;
      if (success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('نجحت استعادة البيانات'),
            content: const Text('تم استرجاع كامل بيانات المركز بنجاح من النسخة الاحتياطية.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً')),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر استعادة البيانات. يرجى التأكد من اختيار ملف صحبح.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي واستعادة البيانات'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.cloud_upload, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 12),
                    const Text('تصدير نسخة احتياطية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text('قم بتصدير جميع بيانات المركز (المرضى، الأطباء، الفواتير، المصروفات) لحفظها بأمان خارج الجهاز أو مشاركتها.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.share),
                        label: Text(_isExporting ? 'جاري التصدير...' : 'تصدير ومشاركة النسخة الاحتياطية'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                        onPressed: _isExporting ? null : _exportBackup,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.deepOrange,
                      child: Icon(Icons.cloud_download, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 12),
                    const Text('استعادة نسخة احتياطية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text('قم باختيار ملف النسخة الاحتياطية (.json) لاسترجاع البيانات السابقة إلى البرنامج.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.folder_open),
                        label: Text(_isRestoring ? 'جاري الاستعادة...' : 'اختيار ملف الاستعادة'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                        onPressed: _isRestoring ? null : _restoreBackup,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
