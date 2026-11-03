import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/workspace_project.dart';

abstract interface class WorkspaceRepository {
  Future<List<WorkspaceProject>> getProjects();
  Future<WorkspaceProject> createProject(String name);
  Future<WorkspaceProject> openProject(int id);
  Future<void> deleteProject(int id);
  Future<void> close();
}

/// Stores application workspace metadata separately from student SQL data.
class SqliteWorkspaceRepository implements WorkspaceRepository {
  static const _databaseName = 'sql_student_studio_workspace.db';
  static const _databaseVersion = 1;

  Database? _database;
  Future<Database>? _openingDatabase;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    _openingDatabase ??= _openDatabase();
    _database = await _openingDatabase;
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final root = await getDatabasesPath();
    return openDatabase(
      p.join(root, _databaseName),
      version: _databaseVersion,
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
      onUpgrade: (db, oldVersion, newVersion) async {
        // Future workspace schema migrations are added here, one version at a time.
      },
    );
  }

  @override
  Future<List<WorkspaceProject>> getProjects() async {
    final db = await _db;
    final rows = await db.query(
      'workspace_projects',
      orderBy: 'last_opened_at DESC, id DESC',
    );
    return rows.map(WorkspaceProject.fromMap).toList(growable: false);
  }

  @override
  Future<WorkspaceProject> createProject(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Project name cannot be empty.');
    }
    if (normalizedName.length > 60) {
      throw ArgumentError.value(name, 'name', 'Project name cannot exceed 60 characters.');
    }

    final db = await _db;
    final now = DateTime.now().toUtc().toIso8601String();
    final id = await db.insert('workspace_projects', {
      'name': normalizedName,
      'created_at': now,
      'last_opened_at': now,
    });
    return WorkspaceProject(
      id: id,
      name: normalizedName,
      createdAt: DateTime.parse(now),
      lastOpenedAt: DateTime.parse(now),
    );
  }

  @override
  Future<WorkspaceProject> openProject(int id) async {
    final db = await _db;
    final now = DateTime.now().toUtc().toIso8601String();
    final count = await db.update(
      'workspace_projects',
      {'last_opened_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count == 0) {
      throw StateError('Workspace project $id does not exist.');
    }
    final rows = await db.query(
      'workspace_projects',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return WorkspaceProject.fromMap(rows.single);
  }

  @override
  Future<void> deleteProject(int id) async {
    final db = await _db;
    await db.delete('workspace_projects', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> close() async {
    final db = _database;
    _database = null;
    _openingDatabase = null;
    await db?.close();
  }
}
