class WorkspaceProject {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime lastOpenedAt;

  const WorkspaceProject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastOpenedAt,
  });

  factory WorkspaceProject.fromMap(Map<String, Object?> map) {
    final id = map['id'];
    final name = map['name'];
    final createdAt = map['created_at'];
    final lastOpenedAt = map['last_opened_at'];

    if (id is! int ||
        name is! String ||
        createdAt is! String ||
        lastOpenedAt is! String) {
      throw const FormatException('Invalid workspace project record.');
    }

    return WorkspaceProject(
      id: id,
      name: name,
      createdAt: DateTime.parse(createdAt),
      lastOpenedAt: DateTime.parse(lastOpenedAt),
    );
  }
}
