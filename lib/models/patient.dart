class Patient {
  final int? id;
  final String patientCode;
  final String name;
  final String phone;
  final String gender;
  final int age;
  final String createdAt;

  Patient({
    this.id,
    required this.patientCode,
    required this.name,
    required this.phone,
    required this.gender,
    required this.age,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientCode': patientCode,
      'name': name,
      'phone': phone,
      'gender': gender,
      'age': age,
      'createdAt': createdAt,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      patientCode: map['patientCode'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      gender: map['gender'] ?? 'ذكر',
      age: map['age'] ?? 0,
      createdAt: map['createdAt'] ?? '',
    );
  }
}
