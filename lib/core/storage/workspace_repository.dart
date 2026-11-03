import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/workspace_project.dart';

abstract interface class WorkspaceRepository {
  Future<List<WorkspaceProject>> getProjects();
  Future<WorkspaceProject> createProject(String name);
  Future<WorkspaceProject> openProject(int id);
  Future<void> deleteProject(int id);
  Future<String> getThemeMode();
  Future<void> setThemeMode(String mode);
  Future<void> close();
}

/// Stores application workspace metadata separately from student SQL data.
class SqliteWorkspaceRepository implements WorkspaceRepository {
  static const _databaseName = 'sql_student_studio_workspace.db';
  static const _databaseVersion = 2;

  final DatabaseFactory _factory;
  final String? _databasePath;

  SqliteWorkspaceRepository({
    DatabaseFactory? factory,
    String? databasePath,
  })  : _factory = factory ?? databaseFactory,
        _databasePath = databasePath;

  Database? _database;
  Future<Database>? _openingDatabase;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final opening = _openingDatabase ??= _openDatabase();
    try {
      final database = await opening;
      _database ??= database;
      return _database!;
    } catch (_) {
      _openingDatabase = null;
      rethrow;
    }
  }

  Future<Database> _openDatabase() async {
    final path = _databasePath ?? p.join(await _factory.getDatabasesPath(), _databaseName);
    return _factory.openDatabase(
      path,
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
        await db.execute('''
          CREATE TABLE app_settings (
            setting_key TEXT PRIMARY KEY,
            setting_value TEXT NOT NULL
          )
        ''');
        await db.insert('app_settings', {
          'setting_key': 'theme_mode',
          'setting_value': 'system',
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE app_settings (
              setting_key TEXT PRIMARY KEY,
              setting_value TEXT NOT NULL
            )
          ''');
          await db.insert('app_settings', {
            'setting_key': 'theme_mode',
            'setting_value': 'system',
          });
        }
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
  Future<String> getThemeMode() async {
    final db = await _db;
    final rows = await db.query(
      'app_settings',
      columns: ['setting_value'],
      where: 'setting_key = ?',
      whereArgs: ['theme_mode'],
      limit: 1,
    );
    if (rows.isEmpty) return 'system';
    final value = rows.single['setting_value'];
    if (value is! String || !const {'system', 'light', 'dark'}.contains(value)) {
      return 'system';
    }
    return value;
  }

  @override
  Future<void> setThemeMode(String mode) async {
    if (!const {'system', 'light', 'dark'}.contains(mode)) {
      throw ArgumentError.value(mode, 'mode', 'Unsupported theme mode.');
    }
    final db = await _db;
    await db.insert(
      'app_settings',
      {'setting_key': 'theme_mode', 'setting_value': mode},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> close() async {
    final db = _database;
    _database = null;
    _openingDatabase = null;
    await db?.close();
  }
}
