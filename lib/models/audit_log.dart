class AuditLog {
  final int? id;
  final String action;
  final String userName;
  final String timestamp;
  final String details;

  AuditLog({
    this.id,
    required this.action,
    required this.userName,
    required this.timestamp,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'userName': userName,
      'timestamp': timestamp,
      'details': details,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'],
      action: map['action'] ?? '',
      userName: map['userName'] ?? 'النظام',
      timestamp: map['timestamp'] ?? '',
      details: map['details'] ?? '',
    );
  }
}
