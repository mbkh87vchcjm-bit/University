import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/audit_log.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<AuditLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final list = await _dbHelper.getAuditLogs();
    setState(() {
      _logs = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل العمليات والتدقيق Audit Log'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('لا يوجد سجل عمليات بعد'))
              : ListView.builder(
                  itemCount: _logs.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.history, color: Colors.white),
                        ),
                        title: Text('${log.action} - بواسطة: ${log.userName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('${log.details}\nالتاريخ: ${log.timestamp.split("T").first} ${log.timestamp.contains("T") ? log.timestamp.split("T").last.substring(0, 5) : ""}'),
                      ),
                    );
                  },
                ),
    );
  }
}
