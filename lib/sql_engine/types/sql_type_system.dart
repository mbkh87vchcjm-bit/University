import 'dart:typed_data';

import 'sql_type_spec.dart';
import 'sql_value.dart';

enum SqlVarcharCodePage {
  asciiOnly,
  latin1,
}

class SqlTypeException implements Exception {
  final String code;
  final String message;

  const SqlTypeException(this.code, this.message);

  @override
  String toString() => '$code: $message';
}

/// Validates and converts values for the documented SQL Server 2014 teaching
/// subset. This is not the complete SQL Server conversion implementation.
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
        final value = _quantizeDecimal(
          _numericText(source),
          precision: 19,
          scale: 4,
          typeName: 'MONEY',
        );
        _checkScaledRange(
          value,
          BigInt.parse('-9223372036854775808'),
          BigInt.parse('9223372036854775807'),
          'MONEY',
        );
        return SqlValue.money(value);
      case SqlTypeKind.smallMoneyType:
        final value = _quantizeDecimal(
          _numericText(source),
          precision: 10,
          scale: 4,
          typeName: 'SMALLMONEY',
        );
        _checkScaledRange(
          value,
          BigInt.from(-2147483648),
          BigInt.from(2147483647),
          'SMALLMONEY',
        );
        return SqlValue.smallMoney(value);
      case SqlTypeKind.floatType:
        final value = _toDouble(source, target.displayName);
        if (target.precision! <= 24) {
          final data = ByteData(4)..setFloat32(0, value, Endian.little);
          final rounded = data.getFloat32(0, Endian.little);
          if (!rounded.isFinite) {
            _fail('SSS-TYPE-OVERFLOW', 'Value exceeds the FLOAT precision range.');
          }
          return SqlValue.float(rounded);
        }
        return SqlValue.float(value);
      case SqlTypeKind.realType:
        final value = _toDouble(source, target.displayName);
        final data = ByteData(4)..setFloat32(0, value, Endian.little);
        final rounded = data.getFloat32(0, Endian.little);
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
        final original = _toDateTime(source, target.displayName);
        _checkDateRange(
          original,
          DateTime(1753, 1, 1),
          DateTime(9999, 12, 31, 23, 59, 59, 999, 999),
          'DATETIME',
        );
        final rounded = _roundDateTime(original);
        _checkDateRange(
          rounded,
          DateTime(1753, 1, 1),
          DateTime(9999, 12, 31, 23, 59, 59, 997),
          'DATETIME',
        );
        return SqlValue.dateTime(rounded);
      case SqlTypeKind.dateTime2Type:
        final original = _toDateTime(source, target.displayName);
        final rounded = _roundDateTimeScale(original, target.scale!);
        _checkDateRange(
          rounded,
          DateTime(1, 1, 1),
          DateTime(9999, 12, 31, 23, 59, 59, 999, 999),
          'DATETIME2',
        );
        return SqlValue.dateTime2(rounded, scale: target.scale!);
      case SqlTypeKind.dateTimeOffsetType:
        final offset = source is SqlDateTimeOffset
            ? source
            : _parseDateTimeOffset(_textValue(source), target.scale!);
        if (offset.offsetMinutes.abs() > 14 * 60 ||
            (offset.offsetMinutes.abs() == 14 * 60 &&
                offset.offsetMinutes % 60 != 0)) {
          _fail(
            'SSS-TYPE-DATETIMEOFFSET',
            'Offset must be between -14:00 and +14:00.',
          );
        }
        final rounded = _roundDateTimeScale(offset.value, target.scale!);
        _checkDateRange(
          rounded,
          DateTime(1, 1, 1),
          DateTime(9999, 12, 31, 23, 59, 59, 999, 999),
          'DATETIMEOFFSET',
        );
        return SqlValue.dateTimeOffset(
          rounded,
          offsetMinutes: offset.offsetMinutes,
          scale: target.scale!,
        );
      case SqlTypeKind.uniqueIdentifierType:
        final value = _textValue(source).trim();
        if (!_guidPattern.hasMatch(value)) {
          _fail(
            'SSS-TYPE-GUID',
            'Value is not a canonical UNIQUEIDENTIFIER.',
          );
        }
        return SqlValue.uniqueIdentifier(value.toLowerCase());
      case SqlTypeKind.rowVersionType:
        _fail(
          'SSS-TYPE-GENERATED',
          'ROWVERSION is generated by the database engine and cannot be assigned from a literal.',
        );
    }
  }

  static SqlValue validate(
    SqlValue value,
    SqlTypeSpec target, {
    SqlVarcharCodePage varcharCodePage = SqlVarcharCodePage.asciiOnly,
  }) =>
      convert(value, target, varcharCodePage: varcharCodePage);

  /// Bounded SQL Server numeric-precedence subset for future expression binding.
  /// This is not a complete implicit-conversion matrix or an assignment check.
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
    SqlTypeKind.bitType: 0,
    SqlTypeKind.tinyIntType: 1,
    SqlTypeKind.smallIntType: 2,
    SqlTypeKind.intType: 3,
    SqlTypeKind.bigIntType: 4,
    SqlTypeKind.smallMoneyType: 5,
    SqlTypeKind.moneyType: 6,
    SqlTypeKind.decimalType: 7,
    SqlTypeKind.numericType: 7,
    SqlTypeKind.realType: 8,
    SqlTypeKind.floatType: 9,
  };

  static int _boundedInteger(
    SqlValue source,
    BigInt minimum,
    BigInt maximum,
    SqlTypeSpec target,
  ) {
    final parts = _parseDecimal(_numericText(source));
    final integer = BigInt.parse(parts.integer);
    final value = parts.negative ? -integer : integer;
    if (value < minimum || value > maximum) {
      _fail(
        'SSS-TYPE-OVERFLOW',
        'Value is outside the ${target.displayName} range.',
      );
    }
    return value.toInt();
  }

  static String _quantizeDecimal(
    String text, {
    required int precision,
    required int scale,
    required String typeName,
  }) {
    final parts = _parseDecimal(text);
    final kept = parts.fraction.padRight(scale, '0').substring(0, scale);
    var magnitude = BigInt.parse(parts.integer + kept);

    // Round half away from zero when reducing scale.
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
    final integerDigits =
        normalizedInteger == '0' ? 0 : normalizedInteger.length;

    if (integerDigits > precision - scale) {
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
    final magnitude = BigInt.parse(unsigned.replaceAll('.', ''));
    final value = negative ? -magnitude : magnitude;
    if (value < minimum || value > maximum) {
      _fail(
        'SSS-TYPE-OVERFLOW',
        'Value is outside the $typeName range.',
      );
    }
  }

  static _DecimalParts _parseDecimal(String input) {
    final match = _decimalPattern.firstMatch(input.trim());
    if (match == null) {
      _fail(
        'SSS-TYPE-CONVERSION',
        'Value "$input" is not a supported exact numeric literal.',
      );
    }
    final integer =
        match.group(2)!.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    return _DecimalParts(
      negative: match.group(1) == '-',
      integer: integer,
      fraction: match.group(3) ?? '',
    );
  }

  static final RegExp _decimalPattern =
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
      'Cannot convert ${value.runtimeType} to a numeric SQL type.',
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
    final result = double.tryParse(_numericText(value).trim());
    if (result == null || !result.isFinite) {
      _fail(
        'SSS-TYPE-CONVERSION',
        'Value cannot be converted to $typeName.',
      );
    }
    return result;
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
    final parts = _parseDecimal(_numericText(value));
    final digits = BigInt.parse(parts.integer + parts.fraction);
    return digits != BigInt.zero;
  }

  static SqlValue _convertText(
    SqlValue source,
    SqlTypeSpec target, {
    required bool truncate,
    required SqlVarcharCodePage codePage,
  }) {
    var text = _textValue(source);
    final unicode =
        target.kind == SqlTypeKind.ncharType ||
        target.kind == SqlTypeKind.nvarcharType;
    final fixed =
        target.kind == SqlTypeKind.charType ||
        target.kind == SqlTypeKind.ncharType;

    if (!unicode) {
      final maxCodePoint =
          codePage == SqlVarcharCodePage.asciiOnly ? 0x7F : 0xFF;
      if (text.runes.any((rune) => rune > maxCodePoint)) {
        _fail(
          'SSS-TYPE-CODEPAGE',
          'Value is not representable in the selected VARCHAR/CHAR code page. Use NVARCHAR/NCHAR for Arabic and other Unicode text.',
        );
      }
    }

    if (!target.isMax) {
      final maxLength = target.length!;
      if (text.length > maxLength) {
        if (!truncate) {
          _fail(
            'SSS-TYPE-TRUNCATION',
            'Value length ${text.length} exceeds ${target.displayName}.'
          );
        }
        text = _truncateUtf16(text, maxLength);
      }
      if (fixed && text.length < maxLength) {
        text = text.padRight(maxLength, ' ');
      }
    }

    return switch (target.kind) {
      SqlTypeKind.charType => SqlValue.char(text),
      SqlTypeKind.varcharType => SqlValue.varchar(text),
      SqlTypeKind.ncharType => SqlValue.nchar(text),
      SqlTypeKind.nvarcharType => SqlValue.nvarchar(text),
      _ => throw StateError('Unexpected text target ${target.kind.name}.'),
    };
  }

  static String _truncateUtf16(String value, int maxUnits) {
    final buffer = StringBuffer();
    var units = 0;
    for (final rune in value.runes) {
      final runeUnits = rune > 0xFFFF ? 2 : 1;
      if (units + runeUnits > maxUnits) break;
      buffer.writeCharCode(rune);
      units += runeUnits;
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
    if (value is SqlDateTimeOffset) {
      return value.toSqlLiteral().replaceAll("'", '');
    }
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
    var bytes = _binaryBytes(source);
    if (!target.isMax) {
      final maxLength = target.length!;
      if (bytes.length > maxLength) {
        if (!truncate) {
          _fail(
            'SSS-TYPE-TRUNCATION',
            'Binary value exceeds ${target.displayName}.'
          );
        }
        bytes = bytes.sublist(0, maxLength);
      }
      if (target.kind == SqlTypeKind.binaryType &&
          bytes.length < maxLength) {
        bytes = [
          ...bytes,
          ...List<int>.filled(maxLength - bytes.length, 0),
        ];
      }
    }
    return target.kind == SqlTypeKind.binaryType
        ? SqlValue.binary(bytes)
        : SqlValue.varBinary(bytes);
  }

  static List<int> _binaryBytes(SqlValue source) {
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
      final digits = text.substring(2);
      final bytes = <int>[];
      for (var i = 0; i < digits.length; i += 2) {
        final byte = int.tryParse(digits.substring(i, i + 2), radix: 16);
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
      'Cannot convert ${source.runtimeType} to BINARY/VARBINARY.',
    );
  }

  static DateTime _toDateTime(SqlValue source, String typeName) {
    if (source is SqlDate) return source.value;
    if (source is SqlDateTime) return source.value;
    if (source is SqlDateTime2) return source.value;
    if (source is SqlDateTimeOffset) return source.value;

    final text = _textValue(source).trim();
    final zoneMatch = _offsetSuffix.firstMatch(text);
    final dateText =
        zoneMatch == null ? text : text.substring(0, zoneMatch.start);
    return _parseIsoDateTime(dateText, typeName);
  }

  /// Parses only the documented ISO-oriented subset and rejects calendar/time
  /// overflow instead of accepting DateTime.parse normalization.
  static DateTime _parseIsoDateTime(String input, String typeName) {
    final match = _isoDateTimePattern.firstMatch(input);
    if (match == null) {
      _fail(
        'SSS-TYPE-DATE',
        'Value cannot be converted to $typeName. Use YYYY-MM-DD or an ISO date/time value.',
      );
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final hour = int.parse(match.group(4) ?? '0');
    final minute = int.parse(match.group(5) ?? '0');
    final second = int.parse(match.group(6) ?? '0');
    final fraction = (match.group(7) ?? '').padRight(6, '0');
    final millisecond = int.parse(fraction.substring(0, 3));
    final microsecond = int.parse(fraction.substring(3, 6));

    final parsed = DateTime(
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
    if (parsed.year != year ||
        parsed.month != month ||
        parsed.day != day ||
        parsed.hour != hour ||
        parsed.minute != minute ||
        parsed.second != second) {
      _fail(
        'SSS-TYPE-DATE',
        'Value contains an invalid calendar date or clock time for $typeName.',
      );
    }
    return parsed;
  }

  static DateTime _wallClock(DateTime value) => DateTime(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
        value.second,
        value.millisecond,
        value.microsecond,
      );

  static DateTime _toSmallDateTime(DateTime value) {
    final roundedUp = value.second > 29 ||
        (value.second == 29 && value.millisecond >= 999);
    final rounded = DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute + (roundedUp ? 1 : 0),
    );
    _checkDateRange(
      rounded,
      DateTime(1900, 1, 1),
      DateTime(2079, 6, 6, 23, 59, 0),
      'SMALLDATETIME',
    );
    return rounded;
  }

  /// Rounds DATETIME to the nearest 1/300-second storage tick.
  static DateTime _roundDateTime(DateTime value) {
    final microseconds = value.millisecond * 1000 + value.microsecond;
    final ticks = (microseconds * 300 / 1000000).round();
    final rounded = (ticks * 1000000 / 300).round();
    if (rounded >= 1000000) {
      return DateTime(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
        value.second + 1,
      );
    }
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      rounded ~/ 1000,
      rounded % 1000,
    );
  }

  /// DateTime has microsecond precision. Scale 7 is represented internally
  /// at scale 6; the seventh digit remains unavailable in this simulator.
  static DateTime _roundDateTimeScale(DateTime value, int scale) {
    final effectiveScale = scale > 6 ? 6 : scale;
    final microseconds = value.millisecond * 1000 + value.microsecond;
    final factor = _powerOfTen(6 - effectiveScale);
    final rounded = ((microseconds + factor ~/ 2) ~/ factor) * factor;
    if (rounded >= 1000000) {
      return DateTime(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
        value.second + 1,
      );
    }
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      rounded ~/ 1000,
      rounded % 1000,
    );
  }

  static SqlDateTimeOffset _parseDateTimeOffset(String input, int scale) {
    final text = input.trim();
    final zoneMatch = _offsetSuffix.firstMatch(text);
    var dateText = text;
    var offsetMinutes = 0;

    if (zoneMatch != null) {
      dateText = text.substring(0, zoneMatch.start);
      final zone = zoneMatch.group(0)!;
      if (zone.toUpperCase() != 'Z') {
        final sign = zone.startsWith('-') ? -1 : 1;
        final hours = int.parse(zone.substring(1, 3));
        final minutes = int.parse(zone.substring(4, 6));
        if (minutes > 59 || hours > 14 || (hours == 14 && minutes != 0)) {
          _fail(
            'SSS-TYPE-DATETIMEOFFSET',
            'Offset must be between -14:00 and +14:00.',
          );
        }
        offsetMinutes = sign * (hours * 60 + minutes);
      }
    }

    final parsed = _parseIsoDateTime(dateText, 'DATETIMEOFFSET');
    return SqlDateTimeOffset(
      parsed,
      offsetMinutes: offsetMinutes,
      scale: scale,
    );
  }

  static final RegExp _isoDateTimePattern = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,7}))?)?)?$',
  );
  static final RegExp _offsetSuffix =
      RegExp(r'(Z|[+-]\d{2}:\d{2})$', caseSensitive: false);

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
    final fraction =
        ((value.millisecond * 1000 + value.microsecond) * 10)
            .toString()
            .padLeft(7, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second.$fraction';
  }

  static String _normalizeTime(String input, int scale) {
    final match = _timePattern.firstMatch(input.trim());
    if (match == null) {
      _fail(
        'SSS-TYPE-TIME',
        'TIME must use HH:mm:ss with up to seven fractional digits.',
      );
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final second = int.parse(match.group(3)!);
    final fraction = match.group(4) ?? '';
    final ticks =
        (hour * 3600 + minute * 60 + second) * 10000000 +
        int.parse(fraction.padRight(7, '0'));
    final factor = _powerOfTen(7 - scale);
    final rounded = ((ticks + factor ~/ 2) ~/ factor) * factor;

    if (rounded >= 86400 * 10000000) {
      _fail(
        'SSS-TYPE-TIME-RANGE',
        'Rounded TIME value exceeds 23:59:59.',
      );
    }

    final seconds = rounded ~/ 10000000;
    final fractionTicks = rounded % 10000000;
    final hourText = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minuteText = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secondText = (seconds % 60).toString().padLeft(2, '0');
    final base = '$hourText:$minuteText:$secondText';
    if (scale == 0) return base;
    final decimal = fractionTicks.toString().padLeft(7, '0');
    return '$base.${decimal.substring(0, scale)}';
  }

  static int _powerOfTen(int exponent) {
    var value = 1;
    for (var i = 0; i < exponent; i++) {
      value *= 10;
    }
    return value;
  }

  static final RegExp _timePattern =
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
