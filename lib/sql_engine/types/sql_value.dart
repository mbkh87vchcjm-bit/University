import 'package:meta/meta.dart';

/// Strongly-typed SQL Value abstraction hierarchy covering T-SQL data types.
@immutable
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

final class SqlVarchar extends SqlValue {
  final String value;
  const SqlVarchar(this.value);

  @override
  bool operator ==(Object other) => other is SqlVarchar && other.value == value;

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

final class SqlNVarchar extends SqlValue {
  final String value;
  const SqlNVarchar(this.value);

  @override
  bool operator ==(Object other) => other is SqlNVarchar && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() {
    final escaped = value.replaceAll("'", "''");
    return "N'$escaped'";
  }

  @override
  String toString() => value;
}

final class SqlChar extends SqlValue {
  final String value;
  const SqlChar(this.value);

  @override
  bool operator ==(Object other) => other is SqlChar && other.value == value;

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

final class SqlNChar extends SqlValue {
  final String value;
  const SqlNChar(this.value);

  @override
  bool operator ==(Object other) => other is SqlNChar && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() {
    final escaped = value.replaceAll("'", "''");
    return "N'$escaped'";
  }

  @override
  String toString() => value;
}

final class SqlBit extends SqlValue {
  final bool value;
  const SqlBit(this.value);

  @override
  bool operator ==(Object other) => other is SqlBit && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() => value ? '1' : '0';

  @override
  String toString() => value ? '1' : '0';
}

final class SqlDate extends SqlValue {
  final DateTime value;
  const SqlDate(this.value);

  @override
  bool operator ==(Object other) => other is SqlDate && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() {
    final formatted = "${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}";
    return "'$formatted'";
  }

  @override
  String toString() => toSqlLiteral();
}

final class SqlTime extends SqlValue {
  final String value; // HH:mm:ss format
  const SqlTime(this.value);

  @override
  bool operator ==(Object other) => other is SqlTime && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() => "'$value'";

  @override
  String toString() => value;
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
