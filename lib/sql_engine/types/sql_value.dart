import 'package:meta/meta.dart';

/// Strongly-typed SQL Value abstraction hierarchy.
@immutable
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

  /// Returns the standard T-SQL literal string representation.
  String toSqlLiteral();
}

final class SqlNull extends SqlValue {
  const SqlNull();

  @override
  bool operator ==(Object other) => other is SqlNull;

  @override
  int get hashCode => 0;

  @override
  String toSqlLiteral() => 'NULL';

  @override
  String toString() => 'NULL';
}

final class SqlInt extends SqlValue {
  final int value;
  const SqlInt(this.value);

  @override
  bool operator ==(Object other) => other is SqlInt && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() => value.toString();

  @override
  String toString() => value.toString();
}

final class SqlBigInt extends SqlValue {
  final int value;
  const SqlBigInt(this.value);

  @override
  bool operator ==(Object other) => other is SqlBigInt && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() => value.toString();

  @override
  String toString() => value.toString();
}

final class SqlSmallInt extends SqlValue {
  final int value;
  const SqlSmallInt(this.value);

  @override
  bool operator ==(Object other) => other is SqlSmallInt && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() => value.toString();

  @override
  String toString() => value.toString();
}

final class SqlTinyInt extends SqlValue {
  final int value;
  const SqlTinyInt(this.value);

  @override
  bool operator ==(Object other) => other is SqlTinyInt && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() => value.toString();

  @override
  String toString() => value.toString();
}

final class SqlDecimal extends SqlValue {
  final String value; // Canonical exact decimal string representation
  const SqlDecimal(this.value);

  @override
  bool operator ==(Object other) => other is SqlDecimal && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() => value;

  @override
  String toString() => value;
}

final class SqlFloat extends SqlValue {
  final double value;
  const SqlFloat(this.value);

  @override
  bool operator ==(Object other) => other is SqlFloat && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() => value.toString();

  @override
  String toString() => value.toString();
}

final class SqlString extends SqlValue {
  final String value;
  const SqlString(this.value);

  @override
  bool operator ==(Object other) => other is SqlString && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() {
    final escaped = value.replaceAll("'", "''");
    return "'$escaped'";
  }

  @override
  String toString() => value;
}

final class SqlBoolean extends SqlValue {
  final bool value;
  const SqlBoolean(this.value);

  @override
  bool operator ==(Object other) => other is SqlBoolean && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() => value ? '1' : '0';

  @override
  String toString() => value ? '1' : '0';
}

final class SqlDateTime extends SqlValue {
  final DateTime value;
  const SqlDateTime(this.value);

  @override
  bool operator ==(Object other) => other is SqlDateTime && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() => "'${value.toIso8601String()}'";

  @override
  String toString() => value.toIso8601String();
}

typedef SqlRow = Map<String, SqlValue>;
