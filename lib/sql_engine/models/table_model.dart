import '../types/sql_type_spec.dart';
import '../types/sql_value.dart';

enum SqlDataType {
  intType,
  bigIntType,
  smallIntType,
  tinyIntType,
  decimalType,
  moneyType,
  smallMoneyType,
  floatType,
  realType,
  varcharType,
  nvarcharType,
  charType,
  ncharType,
  binaryType,
  varBinaryType,
  dateType,
  timeType,
  smallDateTimeType,
  dateTimeType,
  dateTime2Type,
  dateTimeOffsetType,
  uniqueIdentifierType,
  rowVersionType,
  bitType,
}

class ColumnModel {
  final String name;
  final SqlDataType dataType;
  /// Optional length/precision/scale-aware descriptor for the declared column.
  /// The SQL parser/catalog will populate this when DDL execution is introduced.
  final SqlTypeSpec? typeSpec;
  final bool isNullable;
  final bool isIdentity;

  const ColumnModel({
    required this.name,
    required this.dataType,
    this.typeSpec,
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
  const PrimaryKeyConstraint({String? name, required this.columns})
    : super(name);
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
      throw ArgumentError(
        'Foreign key source and referenced column counts must match.',
      );
    }
  }
}

class UniqueConstraint extends ConstraintModel {
  final List<String> columns;
  const UniqueConstraint({String? name, required this.columns}) : super(name);
}

class DefaultConstraint extends ConstraintModel {
  final String column;
  final String expressionSql; // Default AST expression string

  const DefaultConstraint({
    String? name,
    required this.column,
    required this.expressionSql,
  }) : super(name);
}

class CheckConstraint extends ConstraintModel {
  final String expressionSql; // Check AST expression string

  const CheckConstraint({String? name, required this.expressionSql})
    : super(name);
}

class StoredRow {
  final int rowId;
  final SqlRow values;

  const StoredRow({required this.rowId, required this.values});
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
  }) : constraints = constraints ?? [],
       rows = rows ?? [],
       _nextRowId = nextRowId;

  int allocateRowId() => _nextRowId++;
}

class SchemaModel {
  final String name;
  final Map<String, TableModel> tables;

  SchemaModel({required this.name, Map<String, TableModel>? tables})
    : tables = tables ?? {};
}

class DatabaseModel {
  final String name;
  final Map<String, SchemaModel> schemas;

  DatabaseModel({required this.name, Map<String, SchemaModel>? schemas})
    : schemas = schemas ?? {'dbo': SchemaModel(name: 'dbo')};
}
