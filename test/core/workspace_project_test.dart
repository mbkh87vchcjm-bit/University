import 'package:flutter_test/flutter_test.dart';
import 'package:sql_student_studio/core/models/workspace_project.dart';

void main() {
  group('WorkspaceProject', () {
    test('maps a valid persisted project record', () {
      final project = WorkspaceProject.fromMap({
        'id': 7,
        'name': 'University Database',
        'created_at': '2026-11-03T10:00:00.000Z',
        'last_opened_at': '2026-11-03T11:30:00.000Z',
      });

      expect(project.id, 7);
      expect(project.name, 'University Database');
      expect(project.createdAt, DateTime.utc(2026, 11, 3, 10));
      expect(project.lastOpenedAt, DateTime.utc(2026, 11, 3, 11, 30));
    });

    test('rejects incomplete or malformed database records', () {
      expect(
        () => WorkspaceProject.fromMap({
          'id': 'not-an-integer',
          'name': 'Broken project',
          'created_at': 'not-a-date',
          'last_opened_at': 'not-a-date',
        }),
        throwsFormatException,
      );
    });
  });
}
