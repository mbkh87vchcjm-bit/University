import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sql_student_studio/core/storage/workspace_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test(
    'migrates version 1 workspace data and persists projects and settings',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'sql_student_studio_workspace_test_',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final databasePath = p.join(directory.path, 'workspace.db');
      final legacyDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE workspace_projects (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              created_at TEXT NOT NULL,
              last_opened_at TEXT NOT NULL
            )
          ''');
            await db.execute(
              'CREATE INDEX idx_workspace_projects_last_opened '
              'ON workspace_projects(last_opened_at DESC)',
            );
          },
        ),
      );

      await legacyDatabase.insert('workspace_projects', {
        'name': 'مشروع قديم',
        'created_at': '2026-11-03T10:00:00.000Z',
        'last_opened_at': '2026-11-03T10:30:00.000Z',
      });
      await legacyDatabase.close();

      final repository = SqliteWorkspaceRepository(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );

      expect(await repository.getThemeMode(), 'system');
      expect((await repository.getProjects()).single.name, 'مشروع قديم');

      final created = await repository.createProject('قاعدة بيانات الجامعة');
      expect(created.name, 'قاعدة بيانات الجامعة');

      await repository.setThemeMode('dark');
      await repository.close();

      final reopened = SqliteWorkspaceRepository(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );

      expect(await reopened.getThemeMode(), 'dark');
      expect(
        (await reopened.getProjects()).map((project) => project.name),
        containsAll(['مشروع قديم', 'قاعدة بيانات الجامعة']),
      );

      await reopened.close();
    },
  );

  test('rejects unknown theme mode values', () async {
    final directory = await Directory.systemTemp.createTemp(
      'sql_student_studio_invalid_setting_test_',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final repository = SqliteWorkspaceRepository(
      factory: databaseFactoryFfi,
      databasePath: p.join(directory.path, 'workspace.db'),
    );

    await expectLater(repository.setThemeMode('neon'), throwsArgumentError);
    await repository.close();
  });
}
