class MedicalService {
  final int? id;
  final String name;
  final double defaultPrice;
  final String category;
  final int durationMinutes;
  final String notes;

  MedicalService({
    this.id,
    required this.name,
    required this.defaultPrice,
    required this.category,
    this.durationMinutes = 15,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'defaultPrice': defaultPrice,
      'category': category,
      'durationMinutes': durationMinutes,
      'notes': notes,
    };
  }

  factory MedicalService.fromMap(Map<String, dynamic> map) {
    return MedicalService(
      id: map['id'],
      name: map['name'] ?? '',
      defaultPrice: (map['defaultPrice'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'أشعة عامة',
      durationMinutes: map['durationMinutes'] ?? 15,
      notes: map['notes'] ?? '',
    );
  }
}
