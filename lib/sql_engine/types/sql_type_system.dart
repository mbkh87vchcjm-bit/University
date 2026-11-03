import 'dart:typed_data';

import 'sql_type_spec.dart';
import 'sql_value.dart';

enum SqlVarcharCodePage {
  /// Safe fallback when the server collation/code page has not been selected.
  asciiOnly,

  /// A small deterministic Latin-1 teaching profile (U+0000..U+00FF).
  latin1,
}

class SqlTypeException implements Exception {
  final String code;
  final String message;

  const SqlTypeException(this.code, this.message);

  @override
  String toString() => '$code: $message';
}

/// Type validation and explicit conversion rules for the simulator.
///
/// This is a documented subset of SQL Server 2014 semantics. It deliberately
/// fails closed when the selected code page or precision cannot be represented.
class SqlTypeSystem {
  const SqlTypeSystem._();

  static SqlValue convert(
    SqlValue source,
    SqlTypeSpec target, {
    bool truncateStrings = false,
    SqlVarcharCodePage varcharCodePage = SqlVarcharCodePage.asciiOnly,
  }) {
    if (source is SqlNull) return source;

    switch (target.kind) {
      case SqlTypeKind.bitType:
        return SqlValue.bit(_toBit(source));

      case SqlTypeKind.tinyIntType:
        return SqlValue.tinyInt(
          _boundedInteger(source, BigInt.zero, BigInt.from(255), target),
        );

      case SqlTypeKind.smallIntType:
        return SqlValue.smallInt(
          _boundedInteger(
            source,
            BigInt.from(-32768),
            BigInt.from(32767),
            target,
          ),
        );

      case SqlTypeKind.intType:
        return SqlValue.integer(
          _boundedInteger(
            source,
            BigInt.from(-2147483648),
            BigInt.from(2147483647),
            target,
          ),
        );

      case SqlTypeKind.bigIntType:
        return SqlValue.bigInt(
          _boundedInteger(
            source,
            BigInt.parse('-9223372036854775808'),
            BigInt.parse('9223372036854775807'),
            target,
          ),
        );

      case SqlTypeKind.decimalType:
      case SqlTypeKind.numericType:
        return SqlValue.decimal(
          _quantizeDecimal(
            _numericText(source),
            precision: target.precision!,
            scale: target.scale!,
            typeName: target.displayName,
          ),
        );

      case SqlTypeKind.moneyType:
        final money = _quantizeDecimal(
          _numericText(source),
          precision: 19,
          scale: 4,
          typeName: target.displayName,
        );
        _checkScaledRange(
          money,
          BigInt.parse('-9223372036854775808'),
          BigInt.parse('9223372036854775807'),
          target.displayName,
        );
        return SqlValue.money(money);

      case SqlTypeKind.smallMoneyType:
        final money = _quantizeDecimal(
          _numericText(source),
          precision: 10,
          scale: 4,
          typeName: target.displayName,
        );
        _checkScaledRange(
          money,
          BigInt.from(-2147483648),
          BigInt.from(2147483647),
          target.displayName,
        );
        return SqlValue.smallMoney(money);

      case SqlTypeKind.floatType:
        final value = _toDouble(source, target.displayName);
        return SqlValue.float(value);

      case SqlTypeKind.realType:
        final value = _toDouble(source, target.displayName);
        final buffer = ByteData(4)..setFloat32(0, value, Endian.little);
        final rounded = buffer.getFloat32(0, Endian.little);
        if (!rounded.isFinite) {
          _fail('SSS-TYPE-OVERFLOW', 'Value exceeds the REAL range.');
        }
        return SqlValue.real(rounded);

      case SqlTypeKind.charType:
      case SqlTypeKind.varcharType:
      case SqlTypeKind.ncharType:
      case SqlTypeKind.nvarcharType:
        return _convertText(
          source,
          target,
          truncate: truncateStrings,
          codePage: varcharCodePage,
        );

      case SqlTypeKind.binaryType:
      case SqlTypeKind.varBinaryType:
        return _convertBinary(source, target, truncate: truncateStrings);

      case SqlTypeKind.dateType:
        final date = _toDateTime(source, target.displayName);
        return SqlValue.date(DateTime(date.year, date.month, date.day));

      case SqlTypeKind.timeType:
        return SqlValue.time(
          _normalizeTime(_timeText(source), target.scale!),
        );

      case SqlTypeKind.smallDateTimeType:
        return SqlValue.dateTime(
          _toSmallDateTime(_toDateTime(source, target.displayName)),
        );

      case SqlTypeKind.dateTimeType:
        final dateTime = _toDateTime(source, target.displayName);
        _checkDateRange(
          dateTime,
          DateTime(1753, 1, 1),
          DateTime(9999, 12, 31, 23, 59, 59, 997),
          target.displayName,
        );
        return SqlValue.dateTime(dateTime);

      case SqlTypeKind.dateTime2Type:
        final dateTime = _toDateTime(source, target.displayName);
        return SqlValue.dateTime2(dateTime, scale: target.scale!);

      case SqlTypeKind.dateTimeOffsetType:
        final offsetValue = source is SqlDateTimeOffset
            ? source
            : SqlDateTimeOffset(
                _toDateTime(source, target.displayName),
                scale: target.scale!,
              );
        if (offsetValue.offsetMinutes.abs() > 14 * 60 ||
            offsetValue.offsetMinutes.abs() == 14 * 60 &&
                offsetValue.offsetMinutes % 60 != 0) {
          _fail(
            'SSS-TYPE-DATETIMEOFFSET',
            'DATETIMEOFFSET offset must be between -14:00 and +14:00.',
          );
        }
        return SqlValue.dateTimeOffset(
          offsetValue.value,
          offsetMinutes: offsetValue.offsetMinutes,
          scale: target.scale!,
        );

      case SqlTypeKind.uniqueIdentifierType:
        final text = _textValue(source).trim();
        if (!_guidPattern.hasMatch(text)) {
          _fail(
            'SSS-TYPE-GUID',
            'Value is not a valid UNIQUEIDENTIFIER.',
          );
        }
        return SqlValue.uniqueIdentifier(text.toLowerCase());

      case SqlTypeKind.rowVersionType:
        _fail(
          'SSS-TYPE-GENERATED',
          'ROWVERSION is generated by the database engine and cannot be assigned from a literal.',
        );
    }
  }

  /// Validates that a value can be represented by the requested SQL type.
  /// The normalized value is returned so callers can store the converted form.
  static SqlValue validate(
    SqlValue value,
    SqlTypeSpec target, {
    SqlVarcharCodePage varcharCodePage = SqlVarcharCodePage.asciiOnly,
  }) =>
      convert(value, target, varcharCodePage: varcharCodePage);

  /// Conservative implicit-conversion matrix used by expression binding.
  /// It intentionally omits conversions whose SQL Server behavior depends on
  /// expression context, collation, or style arguments.
  static bool canImplicitlyConvert(
    SqlTypeKind source,
    SqlTypeKind target,
  ) {
    if (source == target) return true;
    final sourceRank = _numericRank[source];
    final targetRank = _numericRank[target];
    if (sourceRank != null && targetRank != null) {
      return targetRank >= sourceRank;
    }
    const dateWidening = {
      SqlTypeKind.dateType: {
        SqlTypeKind.dateTimeType,
        SqlTypeKind.dateTime2Type,
        SqlTypeKind.dateTimeOffsetType,
      },
      SqlTypeKind.smallDateTimeType: {
        SqlTypeKind.dateTimeType,
        SqlTypeKind.dateTime2Type,
        SqlTypeKind.dateTimeOffsetType,
      },
      SqlTypeKind.dateTimeType: {
        SqlTypeKind.dateTime2Type,
        SqlTypeKind.dateTimeOffsetType,
      },
      SqlTypeKind.dateTime2Type: {
        SqlTypeKind.dateTimeOffsetType,
      },
    };
    return dateWidening[source]?.contains(target) ?? false;
  }

  static const Map<SqlTypeKind, int> _numericRank = {
    SqlTypeKind.tinyIntType: 1,
    SqlTypeKind.smallIntType: 2,
    SqlTypeKind.intType: 3,
    SqlTypeKind.bigIntType: 4,
    SqlTypeKind.smallMoneyType: 5,
    SqlTypeKind.moneyType: 5,
    SqlTypeKind.decimalType: 6,
    SqlTypeKind.numericType: 6,
    SqlTypeKind.realType: 7,
    SqlTypeKind.floatType: 8,
  };

  static int _boundedInteger(
    SqlValue source,
    BigInt minimum,
    BigInt maximum,
    SqlTypeSpec target,
  ) {
    final value = _integerPart(_numericText(source));
    if (value < minimum || value > maximum) {
      _fail(
        'SSS-TYPE-OVERFLOW',
        'Value is outside the \${target.displayName} range.',
      );
    }
    return value.toInt();
  }

  static BigInt _integerPart(String text) {
    final parts = _parseDecimal(text);
    final integer = BigInt.parse(parts.integer);
    return parts.negative ? -integer : integer;
  }

  static String _quantizeDecimal(
    String text, {
    required int precision,
    required int scale,
    required String typeName,
  }) {
    final parts = _parseDecimal(text);
    final keptFraction = parts.fraction.padRight(scale, '0').substring(0, scale);
    final digits = parts.integer + keptFraction;
    var magnitude = BigInt.parse(digits.isEmpty ? '0' : digits);

    // SQL decimal conversion rounds when reducing scale; it does not silently
    // truncate the fractional component.
    if (parts.fraction.length > scale &&
        int.parse(parts.fraction[scale]) >= 5) {
      magnitude += BigInt.one;
    }

    final scaled = magnitude.toString().padLeft(scale + 1, '0');
    final integerPart = scale == 0
        ? scaled
        : scaled.substring(0, scaled.length - scale);
    final normalizedInteger =
        integerPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final significantIntegerDigits =
        normalizedInteger == '0' ? 0 : normalizedInteger.length;

    if (significantIntegerDigits > precision - scale) {
      _fail(
        'SSS-TYPE-OVERFLOW',
        'Value exceeds the precision of $typeName.',
      );
    }

    final fractionPart =
        scale == 0 ? '' : scaled.substring(scaled.length - scale);
    final sign = parts.negative && magnitude != BigInt.zero ? '-' : '';
    return scale == 0
        ? '$sign$normalizedInteger'
        : '$sign$normalizedInteger.$fractionPart';
  }

  static void _checkScaledRange(
    String decimal,
    BigInt minimum,
    BigInt maximum,
    String typeName,
  ) {
    final negative = decimal.startsWith('-');
    final unsigned = negative ? decimal.substring(1) : decimal;
    final digits = unsigned.replaceAll('.', '');
    final magnitude = BigInt.parse(digits.isEmpty ? '0' : digits);
    final value = negative ? -magnitude : magnitude;
    if (value < minimum || value > maximum) {
      _fail(
        'SSS-TYPE-OVERFLOW',
        'Value is outside the $typeName range.',
      );
    }
  }

  static _DecimalParts _parseDecimal(String input) {
    final text = input.trim();
    final match = _decimalPattern.firstMatch(text);
    if (match == null) {
      _fail(
        'SSS-TYPE-CONVERSION',
        'Value "$input" is not a supported exact numeric literal.',
      );
    }
    final integer = match.group(2)!.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final fraction = match.group(3) ?? '';
    return _DecimalParts(
      negative: match.group(1) == '-',
      integer: integer,
      fraction: fraction,
    );
  }

  static const RegExp _decimalPattern =
      RegExp(r'^([+-]?)(\d+)(?:\.(\d*))?$');

  static String _numericText(SqlValue value) {
    if (value is SqlInt) return value.value.toString();
    if (value is SqlBigInt) return value.value.toString();
    if (value is SqlSmallInt) return value.value.toString();
    if (value is SqlTinyInt) return value.value.toString();
    if (value is SqlDecimal) return value.value;
    if (value is SqlMoney) return value.value;
    if (value is SqlSmallMoney) return value.value;
    if (value is SqlFloat) return _finiteDoubleText(value.value);
    if (value is SqlReal) return _finiteDoubleText(value.value);
    if (value is SqlBit) return value.value ? '1' : '0';
    if (value is SqlVarchar) return value.value;
    if (value is SqlNVarchar) return value.value;
    if (value is SqlChar) return value.value;
    if (value is SqlNChar) return value.value;
    _fail(
      'SSS-TYPE-CONVERSION',
      'Cannot convert \${value.runtimeType} to a numeric SQL type.',
    );
  }

  static String _finiteDoubleText(double value) {
    if (!value.isFinite) {
      _fail(
        'SSS-TYPE-NONFINITE',
        'NaN and infinity are not accepted by this SQL numeric profile.',
      );
    }
    return value.toString();
  }

  static double _toDouble(SqlValue value, String typeName) {
    final number = double.tryParse(_numericText(value).trim());
    if (number == null || !number.isFinite) {
      _fail(
        'SSS-TYPE-CONVERSION',
        'Value cannot be converted to $typeName.',
      );
    }
    return number;
  }

  static bool _toBit(SqlValue value) {
    if (value is SqlBit) return value.value;
    if (value is SqlVarchar ||
        value is SqlNVarchar ||
        value is SqlChar ||
        value is SqlNChar) {
      final text = _textValue(value).trim().toLowerCase();
      if (text == 'true') return true;
      if (text == 'false') return false;
    }
    final numeric = _parseDecimal(_numericText(value));
    return BigInt.parse(numeric.integer + numeric.fraction) != BigInt.zero;
  }

  static SqlValue _convertText(
    SqlValue source,
    SqlTypeSpec target, {
    required bool truncate,
    required SqlVarcharCodePage codePage,
  }) {
    var text = _textValue(source);
    final isUnicode =
        target.kind == SqlTypeKind.ncharType ||
        target.kind == SqlTypeKind.nvarcharType;
    final isFixed =
        target.kind == SqlTypeKind.charType ||
        target.kind == SqlTypeKind.ncharType;

    if (!isUnicode) {
      final maxCodePoint =
          codePage == SqlVarcharCodePage.asciiOnly ? 0x7F : 0xFF;
      if (text.runes.any((rune) => rune > maxCodePoint)) {
        _fail(
          'SSS-TYPE-CODEPAGE',
          'VARCHAR/CHAR value contains characters not representable by the selected code page. Use NVARCHAR/NCHAR or configure a supported code page.',
        );
      }
    }

    if (!target.isMax) {
      final maximumLength = target.length!;
      final actualLength = text.length;
      if (actualLength > maximumLength) {
        if (!truncate) {
          _fail(
            'SSS-TYPE-TRUNCATION',
            'Value length $actualLength exceeds \${target.displayName}.',
          );
        }
        text = _truncateUtf16(text, maximumLength);
      }
      if (isFixed && text.length < maximumLength) {
        text = text.padRight(maximumLength, ' ');
      }
    }

    return switch (target.kind) {
      SqlTypeKind.charType => SqlValue.char(text),
      SqlTypeKind.varcharType => SqlValue.varchar(text),
      SqlTypeKind.ncharType => SqlValue.nchar(text),
      SqlTypeKind.nvarcharType => SqlValue.nvarchar(text),
      _ => throw StateError('Unexpected text target \${target.kind}.'),
    };
  }

  static String _truncateUtf16(String value, int maximumUnits) {
    final buffer = StringBuffer();
    var usedUnits = 0;
    for (final rune in value.runes) {
      final units = rune > 0xFFFF ? 2 : 1;
      if (usedUnits + units > maximumUnits) break;
      buffer.writeCharCode(rune);
      usedUnits += units;
    }
    return buffer.toString();
  }

  static String _textValue(SqlValue value) {
    if (value is SqlVarchar) return value.value;
    if (value is SqlNVarchar) return value.value;
    if (value is SqlChar) return value.value;
    if (value is SqlNChar) return value.value;
    if (value is SqlUniqueIdentifier) return value.value;
    if (value is SqlDate) return value.value.toIso8601String().split('T').first;
    if (value is SqlDateTime) return value.value.toIso8601String();
    if (value is SqlDateTime2) return value.value.toIso8601String();
    if (value is SqlDateTimeOffset) return value.toSqlLiteral().replaceAll("'", '');
    if (value is SqlTime) return value.value;
    if (value is SqlBinary || value is SqlVarBinary) {
      return value.toSqlLiteral();
    }
    return value.toString();
  }

  static SqlValue _convertBinary(
    SqlValue source,
    SqlTypeSpec target, {
    required bool truncate,
  }) {
    var bytes = _bytesValue(source);
    if (!target.isMax) {
      final maximumLength = target.length!;
      if (bytes.length > maximumLength) {
        if (!truncate) {
          _fail(
            'SSS-TYPE-TRUNCATION',
            'Binary value exceeds \${target.displayName}.',
          );
        }
        bytes = bytes.sublist(0, maximumLength);
      }
      if (target.kind == SqlTypeKind.binaryType &&
          bytes.length < maximumLength) {
        bytes = [
          ...bytes,
          ...List<int>.filled(maximumLength - bytes.length, 0),
        ];
      }
    }
    return target.kind == SqlTypeKind.binaryType
        ? SqlValue.binary(bytes)
        : SqlValue.varBinary(bytes);
  }

  static List<int> _bytesValue(SqlValue source) {
    if (source is SqlBinary) return List<int>.from(source.value);
    if (source is SqlVarBinary) return List<int>.from(source.value);
    if (source is SqlVarchar ||
        source is SqlNVarchar ||
        source is SqlChar ||
        source is SqlNChar) {
      final text = _textValue(source).trim();
      if (!text.startsWith('0x') || text.length.isOdd) {
        _fail(
          'SSS-TYPE-BINARY',
          'Binary text must use an even-length hexadecimal 0x literal.',
        );
      }
      final hex = text.substring(2);
      final bytes = <int>[];
      for (var i = 0; i < hex.length; i += 2) {
        final byte = int.tryParse(hex.substring(i, i + 2), radix: 16);
        if (byte == null) {
          _fail(
            'SSS-TYPE-BINARY',
            'Binary text contains a non-hexadecimal character.',
          );
        }
        bytes.add(byte);
      }
      return bytes;
    }
    _fail(
      'SSS-TYPE-CONVERSION',
      'Cannot convert \${source.runtimeType} to BINARY/VARBINARY.',
    );
  }

  static DateTime _toDateTime(SqlValue source, String typeName) {
    if (source is SqlDate) return source.value;
    if (source is SqlDateTime) return source.value;
    if (source is SqlDateTime2) return source.value;
    if (source is SqlDateTimeOffset) return source.value;
    final text = _textValue(source).trim();
    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      _fail(
        'SSS-TYPE-DATE',
        'Value cannot be converted to $typeName. Use an ISO-8601 date/time value.',
      );
    }
    return parsed;
  }

  static DateTime _toSmallDateTime(DateTime value) {
    final minimum = DateTime(1900, 1, 1);
    final maximum = DateTime(2079, 6, 6, 23, 59, 0);
    var roundedMinute = value.minute;
    if (value.second > 29 ||
        value.second == 29 && value.millisecond >= 999) {
      roundedMinute++;
    }
    final rounded = DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      roundedMinute,
    );
    _checkDateRange(rounded, minimum, maximum, 'SMALLDATETIME');
    return rounded;
  }

  /// SQL DATETIME stores time in 1/300-second increments. Dart DateTime
  /// carries millisecond precision, so this rounds the available input
  /// precision to the nearest representable SQL DATETIME tick.
  static DateTime _roundDateTime(DateTime value) {
    final ticks = (value.millisecond * 300 / 1000).round();
    final roundedMilliseconds = (ticks * 1000 / 300).round();
    if (roundedMilliseconds >= 1000) {
      return DateTime(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
        value.second + 1,
        0,
        value.microsecond,
      );
    }
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      roundedMilliseconds,
      value.microsecond,
    );
  }

  static void _checkDateRange(
    DateTime value,
    DateTime minimum,
    DateTime maximum,
    String typeName,
  ) {
    if (value.isBefore(minimum) || value.isAfter(maximum)) {
      _fail(
        'SSS-TYPE-DATE-RANGE',
        'Value is outside the supported $typeName date range.',
      );
    }
  }

  static String _timeText(SqlValue source) {
    if (source is SqlTime) return source.value;
    if (source is SqlDateTime) return _formatTime(source.value);
    if (source is SqlDateTime2) return _formatTime(source.value);
    if (source is SqlDateTimeOffset) return _formatTime(source.value);
    return _textValue(source).trim();
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    final hundredNanoseconds =
        (value.millisecond * 1000 + value.microsecond) * 10;
    final fraction = hundredNanoseconds.toString().padLeft(7, '0');
    return '$hour:$minute:$second.$fraction';
  }

  static String _normalizeTime(String input, int scale) {
    final match = _timePattern.firstMatch(input.trim());
    if (match == null) {
      _fail(
        'SSS-TYPE-TIME',
        'TIME must be in HH:mm:ss[.fffffff] format.',
      );
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final second = int.parse(match.group(3)!);
    final fraction = match.group(4) ?? '';
    final fractionTicks = int.parse(fraction.padRight(7, '0'));
    final totalTicks =
        ((hour * 3600 + minute * 60 + second) * 10000000) +
            fractionTicks;
    final factor = _powerOfTen(7 - scale);
    final roundedTicks = ((totalTicks + factor ~/ 2) ~/ factor) * factor;
    if (roundedTicks >= 86400 * 10000000) {
      _fail(
        'SSS-TYPE-TIME-RANGE',
        'Rounded TIME value would exceed 23:59:59.',
      );
    }
    final wholeSeconds = roundedTicks ~/ 10000000;
    final remainingTicks = roundedTicks % 10000000;
    final resultHour = wholeSeconds ~/ 3600;
    final resultMinute = (wholeSeconds % 3600) ~/ 60;
    final resultSecond = wholeSeconds % 60;
    final base =
        '\${resultHour.toString().padLeft(2, '0')}:'
        '\${resultMinute.toString().padLeft(2, '0')}:'
        '\${resultSecond.toString().padLeft(2, '0')}';
    if (scale == 0) return base;
    final resultFraction =
        remainingTicks.toString().padLeft(7, '0').substring(0, scale);
    return '$base.$resultFraction';
  }

  static int _powerOfTen(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }

  static const RegExp _timePattern =
      RegExp(r'^([01]\d|2[0-3]):([0-5]\d):([0-5]\d)(?:\.(\d{1,7}))?$');

  static final RegExp _guidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static Never _fail(String code, String message) {
    throw SqlTypeException(code, message);
  }
}

class _DecimalParts {
  final bool negative;
  final String integer;
  final String fraction;

  const _DecimalParts({
    required this.negative,
    required this.integer,
    required this.fraction,
  });
}
