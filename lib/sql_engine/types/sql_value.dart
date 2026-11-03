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
  factory SqlValue.real(double value) = SqlReal;
  factory SqlValue.money(String value) = SqlMoney;
  factory SqlValue.smallMoney(String value) = SqlSmallMoney;
  factory SqlValue.binary(List<int> value) = SqlBinary;
  factory SqlValue.varBinary(List<int> value) = SqlVarBinary;
  factory SqlValue.dateTime2(DateTime value, {int scale = 7}) = SqlDateTime2;
  factory SqlValue.dateTimeOffset(
    DateTime value, {
    int offsetMinutes = 0,
    int scale = 7,
  }) = SqlDateTimeOffset;
  factory SqlValue.uniqueIdentifier(String value) = SqlUniqueIdentifier;

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

final class SqlReal extends SqlValue {
  final double value;
  const SqlReal(this.value);

  @override
  bool operator ==(Object other) => other is SqlReal && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() => value.toString();

  @override
  String toString() => value.toString();
}

final class SqlMoney extends SqlValue {
  final String value;
  const SqlMoney(this.value);

  @override
  bool operator ==(Object other) => other is SqlMoney && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() => value;

  @override
  String toString() => value;
}

final class SqlSmallMoney extends SqlValue {
  final String value;
  const SqlSmallMoney(this.value);

  @override
  bool operator ==(Object other) =>
      other is SqlSmallMoney && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toSqlLiteral() => value;

  @override
  String toString() => value;
}

final class SqlBinary extends SqlValue {
  final List<int> value;

  SqlBinary(List<int> value) : value = List<int>.unmodifiable(value) {
    _validateBytes(this.value);
  }

  @override
  bool operator ==(Object other) =>
      other is SqlBinary && _bytesEqual(other.value, value);

  @override
  int get hashCode => Object.hashAll(value);

  @override
  String toSqlLiteral() => _bytesToHex(value);

  @override
  String toString() => toSqlLiteral();
}

final class SqlVarBinary extends SqlValue {
  final List<int> value;

  SqlVarBinary(List<int> value) : value = List<int>.unmodifiable(value) {
    _validateBytes(this.value);
  }

  @override
  bool operator ==(Object other) =>
      other is SqlVarBinary && _bytesEqual(other.value, value);

  @override
  int get hashCode => Object.hashAll(value);

  @override
  String toSqlLiteral() => _bytesToHex(value);

  @override
  String toString() => toSqlLiteral();
}

final class SqlDateTime2 extends SqlValue {
  final DateTime value;
  final int scale;

  const SqlDateTime2(this.value, {this.scale = 7});

  @override
  bool operator ==(Object other) =>
      other is SqlDateTime2 &&
      other.value == value &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(value, scale);

  @override
  String toSqlLiteral() => "'\${value.toIso8601String()}'";

  @override
  String toString() => value.toIso8601String();
}

final class SqlDateTimeOffset extends SqlValue {
  final DateTime value;
  final int offsetMinutes;
  final int scale;

  const SqlDateTimeOffset(
    this.value, {
    this.offsetMinutes = 0,
    this.scale = 7,
  });

  @override
  bool operator ==(Object other) =>
      other is SqlDateTimeOffset &&
      other.value == value &&
      other.offsetMinutes == offsetMinutes &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(value, offsetMinutes, scale);

  @override
  String toSqlLiteral() {
    final sign = offsetMinutes < 0 ? '-' : '+';
    final absolute = offsetMinutes.abs();
    final hours = (absolute ~/ 60).toString().padLeft(2, '0');
    final minutes = (absolute % 60).toString().padLeft(2, '0');
    final wallClock = value.toIso8601String().replaceFirst('Z', '');
    return "'$wallClock$sign$hours:$minutes'";
  }

  @override
  String toString() => toSqlLiteral();
}

final class SqlUniqueIdentifier extends SqlValue {
  final String value;

  const SqlUniqueIdentifier(this.value);

  @override
  bool operator ==(Object other) =>
      other is SqlUniqueIdentifier &&
      other.value.toLowerCase() == value.toLowerCase();

  @override
  int get hashCode => value.toLowerCase().hashCode;

  @override
  String toSqlLiteral() => "'$value'";

  @override
  String toString() => value;
}

void _validateBytes(List<int> bytes) {
  if (bytes.any((byte) => byte < 0 || byte > 255)) {
    throw ArgumentError('Binary values must contain bytes from 0 to 255.');
  }
}

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

String _bytesToHex(List<int> bytes) {
  final buffer = StringBuffer('0x');
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
  }
  return buffer.toString();
}

typedef SqlRow = Map<String, SqlValue>;
