# Engine Storage & Database Data Models

## Overview
SQL Student Studio separates application metadata models (stored in local SQLite / local app storage) from student database engine models (managed via `DatabaseStorage` and `Persistent Engine Store`).

---

## 1. T-SQL Data Type Specifications & Bounds

To ensure educational alignment with Microsoft SQL Server standards, all engine data types enforce explicit bounds during validation:

| T-SQL Data Type | Underlying Engine Class | Bounds / Constraints |
|---|---|---|
| `INT` | `SqlInt` | Signed 32-bit integer (-2,147,483,648 to 2,147,483,647) |
| `BIGINT` | `SqlBigInt` | Signed 64-bit integer (-9,223,372,036,854,775,808 to 9,223,372,036,854,775,807) |
| `SMALLINT` | `SqlSmallInt` | Signed 16-bit integer (-32,768 to 32,767) |
| `TINYINT` | `SqlTinyInt` | Unsigned 8-bit integer (0 to 255) |
| `DECIMAL(p, s)` | `SqlDecimal` | Canonical exact string representation with specified precision `p` and scale `s` |
| `FLOAT` | `SqlFloat` | 64-bit IEEE 754 floating point (NaN / Infinity values rejected) |
| `VARCHAR(n)` | `SqlVarchar` | Single-byte character string up to length `n` |
| `NVARCHAR(n)` | `SqlNVarchar` | Unicode string up to length `n` |
| `CHAR(n)` | `SqlChar` | Fixed-length single-byte string of length `n` |
| `NCHAR(n)` | `SqlNChar` | Fixed-length Unicode string of length `n` |
| `BIT` | `SqlBit` | Boolean flag (0 or 1) |
| `DATE` | `SqlDate` | Date only (`YYYY-MM-DD`, zeroed time component) |
| `TIME` | `SqlTime` | Time string (`HH:mm:ss` validation format) |
| `DATETIME` | `SqlDateTime` | Date and time ISO-8601 string representation |

---

## 2. Strongly-Typed Value Abstraction (`SqlValue`)

All engine value instances strictly inherit from `SqlValue`:

```dart
sealed class SqlValue {
  const SqlValue();

  const factory SqlValue.nullValue() = SqlNull;
  const factory SqlValue.integer(int value) = SqlInt;
  const factory SqlValue.bigInt(int value) = SqlBigInt;
  const factory SqlValue.smallInt(int value) = SqlSmallInt;
  const factory SqlValue.tinyInt(int value) = SqlTinyInt;
  const factory SqlValue.decimal(String value) = SqlDecimal;
  const factory SqlValue.float(double value) = SqlFloat;
  const factory SqlValue.varchar(String value) = SqlVarchar;
  const factory SqlValue.nvarchar(String value) = SqlNVarchar;
  const factory SqlValue.char(String value) = SqlChar;
  const factory SqlValue.nchar(String value) = SqlNChar;
  const factory SqlValue.bit(bool value) = SqlBit;
  const factory SqlValue.date(DateTime value) = SqlDate;
  const factory SqlValue.time(String value) = SqlTime;
  const factory SqlValue.dateTime(DateTime value) = SqlDateTime;

  String toSqlLiteral();
}

typedef SqlRow = Map<String, SqlValue>;
```

---

## 3. Storage Interface Abstraction (`DatabaseStorage`)

`DatabaseStorage` provides clean query and row-mutation methods by stable `rowId`:

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
  List<StoredRow> selectStoredRows(String dbName, String schema, String tableName);
  int updateRowsByRowId(String dbName, String schema, String tableName, List<int> targetRowIds, Map<String, SqlValue> updates);
  int deleteRowsByRowId(String dbName, String schema, String tableName, List<int> targetRowIds);

  Future<void> persistState();
  Future<void> restoreState();
}
```

---

## 4. Schema, Table, Column & Constraint Models

```dart
class StoredRow {
  final int rowId;
  final SqlRow values;

  const StoredRow({
    required this.rowId,
    required this.values,
  });
}

class TableModel {
  final String name;
  final String schema;
  final List<ColumnModel> columns;
  final List<ConstraintModel> constraints;
  final List<StoredRow> rows;
  int _nextRowId;

  TableModel({
    required this.name,
    this.schema = 'dbo',
    required this.columns,
    List<ConstraintModel>? constraints,
    List<StoredRow>? rows,
    int nextRowId = 1,
  })  : constraints = constraints ?? [],
        rows = rows ?? [],
        _nextRowId = nextRowId;

  int allocateRowId() => _nextRowId++;
}
```

---

## 5. Persistence Strategy for Student Database Engine
To ensure student databases survive application restarts:
- Student database instances, schemas, tables, constraints, and rows are serialized inside the application's local document storage directory (`student_db/`).
- Calling `persistState()` flushes `DatabaseStorage` state to disk; calling `restoreState()` reloads it into memory upon app launch.
