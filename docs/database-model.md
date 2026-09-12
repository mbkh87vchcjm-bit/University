# Engine Storage & Database Data Models

## Overview
SQL Student Studio separates application metadata models (stored in local SQLite / local storage) from student database engine models (managed via `DatabaseStorage` and `Persistent Engine Store`).

---

## 1. Application Metadata Models (Dart)

The application layer manages project workspaces, saved scripts, and query history:

```dart
class ProjectModel {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });
}

class ScriptFileModel {
  final String id;
  final String projectId;
  final String fileName;
  final String content;
  final DateTime updatedAt;

  const ScriptFileModel({
    required this.id,
    required this.projectId,
    required this.fileName,
    required this.content,
    required this.updatedAt,
  });
}

class QueryHistoryModel {
  final int id;
  final String projectId;
  final String queryText;
  final DateTime executedAt;
  final int executionDurationMs;
  final bool isSuccess;
  final String? errorMessage;

  const QueryHistoryModel({
    required this.id,
    required this.projectId,
    required this.queryText,
    required this.executedAt,
    required this.executionDurationMs,
    required this.isSuccess,
    this.errorMessage,
  });
}
```

---

## 2. Student Database Engine Models (`lib/sql_engine/`)

### Strongly-Typed Value Abstraction (`SqlValue`)
To prevent type-erasure issues with comparison, sorting, equality, aggregations, and NULL handling, all engine values strictly implement `SqlValue`:

```dart
sealed class SqlValue {
  const SqlValue();

  factory SqlValue.nullValue() = SqlNull;
  factory SqlValue.integer(int value) = SqlInt;
  factory SqlValue.bigInt(int value) = SqlBigInt;
  factory SqlValue.smallInt(int value) = SqlSmallInt;
  factory SqlValue.tinyInt(int value) = SqlTinyInt;
  factory SqlValue.decimal(String value) = SqlDecimal;
  factory SqlValue.float(double value) = SqlFloat;
  factory SqlValue.string(String value) = SqlString;
  factory SqlValue.boolean(bool value) = SqlBoolean;
  factory SqlValue.dateTime(DateTime value) = SqlDateTime;

  String toSqlLiteral();
}

typedef SqlRow = Map<String, SqlValue>;
```

---

### Storage Interface Abstraction (`DatabaseStorage`)
`DatabaseStorage` provides clean query and raw mutation methods for the Engine.

**Crucial Architecture Requirement**: The `Executor` and `ExpressionEvaluator` components are exclusively responsible for parsing, evaluating `WHERE` clauses, evaluating predicates, and calculating update values. `DatabaseStorage` does **not** accept or execute Dart lambdas, predicates, or evaluation logic; it purely accepts evaluated row subsets provided directly by the Executor.

```dart
abstract interface class DatabaseStorage {
  void createDatabase(String dbName);
  void dropDatabase(String dbName);
  DatabaseModel? getDatabase(String dbName);
  List<String> listDatabases();

  void createTable(String dbName, TableModel table);
  void dropTable(String dbName, String schema, String tableName);
  TableModel? getTable(String dbName, String schema, String tableName);
  List<String> listTables(String dbName, {String schema = 'dbo'});

  void insertRows(String dbName, String schema, String tableName, List<SqlRow> rows);
  List<SqlRow> selectRows(String dbName, String schema, String tableName);
  int updateRows(String dbName, String schema, String tableName, List<SqlRow> targetRows, Map<String, SqlValue> updates);
  int deleteRows(String dbName, String schema, String tableName, List<SqlRow> targetRows);

  Future<void> persistState();
  Future<void> restoreState();
}
```

---

### Schema, Table & Constraint Models

#### Single Source of Truth for DEFAULT Constraints
Default values are specified exclusively via `DefaultConstraint(column, expressionSql)`. To prevent duplicate or conflicting definitions, `ColumnModel` does not contain a raw `defaultValue` string field.

```dart
class DatabaseModel {
  final String name;
  final Map<String, SchemaModel> schemas;

  DatabaseModel({required this.name, Map<String, SchemaModel>? schemas})
      : schemas = schemas ?? {'dbo': SchemaModel(name: 'dbo')};
}

class SchemaModel {
  final String name;
  final Map<String, TableModel> tables;

  SchemaModel({required this.name, Map<String, TableModel>? tables})
      : tables = tables ?? {};
}

class TableModel {
  final String name;
  final String schema;
  final List<ColumnModel> columns;
  final List<ConstraintModel> constraints;
  final List<SqlRow> rows;

  TableModel({
    required this.name,
    this.schema = 'dbo',
    required this.columns,
    List<ConstraintModel>? constraints,
    List<SqlRow>? rows,
  })  : constraints = constraints ?? [],
        rows = rows ?? [];
}

class ColumnModel {
  final String name;
  final SqlDataType dataType;
  final bool isNullable;
  final bool isIdentity;

  const ColumnModel({
    required this.name,
    required this.dataType,
    this.isNullable = true,
    this.isIdentity = false,
  });
}

sealed class ConstraintModel {
  final String? name;
  const ConstraintModel(this.name);
}

class PrimaryKeyConstraint extends ConstraintModel {
  final List<String> columns;
  const PrimaryKeyConstraint({String? name, required this.columns}) : super(name);
}

class ForeignKeyConstraint extends ConstraintModel {
  final List<String> columns;
  final String referencedTable;
  final List<String> referencedColumns;

  ForeignKeyConstraint({
    String? name,
    required this.columns,
    required this.referencedTable,
    required this.referencedColumns,
  }) : super(name) {
    if (columns.length != referencedColumns.length) {
      throw ArgumentError('Foreign key source and referenced column counts must match.');
    }
  }
}

class UniqueConstraint extends ConstraintModel {
  final List<String> columns;
  const UniqueConstraint({String? name, required this.columns}) : super(name);
}

class DefaultConstraint extends ConstraintModel {
  final String column;
  final String expressionSql; // Default expression AST

  const DefaultConstraint({
    String? name,
    required this.column,
    required this.expressionSql,
  }) : super(name);
}

class CheckConstraint extends ConstraintModel {
  final String expressionSql; // Check expression AST

  const CheckConstraint({
    String? name,
    required this.expressionSql,
  }) : super(name);
}
```

---

## 3. Persistence Strategy for Student Database Engine
To ensure student databases survive application restarts:
- Student database instances, schemas, tables, constraints, and rows are stored in JSON/binary format inside the application's local document storage directory.
- Calling `persistState()` serializes `DatabaseStorage` state to disk; calling `restoreState()` loads it back into memory upon app launch.
