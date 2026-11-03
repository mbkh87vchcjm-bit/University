import 'package:flutter_test/flutter_test.dart';
import 'package:sql_student_studio/sql_engine/types/sql_type_spec.dart';
import 'package:sql_student_studio/sql_engine/types/sql_type_system.dart';
import 'package:sql_student_studio/sql_engine/types/sql_value.dart';

void main() {
  group('SQL numeric type validation', () {
    test('INT accepts both boundaries and rejects overflow', () {
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('-2147483648'),
          SqlTypeSpec.intType(),
        ),
        SqlValue.integer(-2147483648),
      );
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('2147483647'),
          SqlTypeSpec.intType(),
        ),
        SqlValue.integer(2147483647),
      );
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.varchar('2147483648'),
          SqlTypeSpec.intType(),
        ),
        throwsA(isA<SqlTypeException>()),
      );
    });

    test('TINYINT rejects negative and values above 255', () {
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.integer(-1),
          SqlTypeSpec.tinyInt(),
        ),
        throwsA(isA<SqlTypeException>()),
      );
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.integer(256),
          SqlTypeSpec.tinyInt(),
        ),
        throwsA(isA<SqlTypeException>()),
      );
    });

    test('BIGINT validates its signed 64-bit boundaries', () {
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('9223372036854775807'),
          SqlTypeSpec.bigInt(),
        ),
        SqlValue.bigInt(9223372036854775807),
      );
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.varchar('9223372036854775808'),
          SqlTypeSpec.bigInt(),
        ),
        throwsA(isA<SqlTypeException>()),
      );
    });

    test('DECIMAL preserves exact value and rounds reduced scale', () {
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('123.455'),
          SqlTypeSpec.decimal(precision: 6, scale: 2),
        ),
        SqlValue.decimal('123.46'),
      );
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('-0.004'),
          SqlTypeSpec.decimal(precision: 5, scale: 2),
        ),
        SqlValue.decimal('0.00'),
      );
    });

    test('DECIMAL rejects precision overflow after rounding', () {
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.varchar('999.995'),
          SqlTypeSpec.decimal(precision: 5, scale: 2),
        ),
        throwsA(isA<SqlTypeException>()),
      );
    });

    test('DECIMAL descriptor rejects invalid precision and scale', () {
      expect(
        () => SqlTypeSpec.decimal(precision: 39, scale: 0),
        throwsArgumentError,
      );
      expect(
        () => SqlTypeSpec.decimal(precision: 4, scale: 5),
        throwsArgumentError,
      );
    });

    test('MONEY and SMALLMONEY use four decimal places and exact bounds', () {
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('12.34567'),
          SqlTypeSpec.money(),
        ),
        SqlValue.money('12.3457'),
      );
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('214748.3647'),
          SqlTypeSpec.smallMoney(),
        ),
        SqlValue.smallMoney('214748.3647'),
      );
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.varchar('214748.3648'),
          SqlTypeSpec.smallMoney(),
        ),
        throwsA(isA<SqlTypeException>()),
      );
    });

    test('REAL and FLOAT reject non-finite values', () {
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.float(double.infinity),
          SqlTypeSpec.real(),
        ),
        throwsA(isA<SqlTypeException>()),
      );
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('3.5'),
          SqlTypeSpec.float(),
        ),
        SqlValue.float(3.5),
      );
    });

    test('BIT converts zero to 0 and non-zero to 1', () {
      expect(
        SqlTypeSystem.convert(
          SqlValue.integer(0),
          SqlTypeSpec.bit(),
        ),
        SqlValue.bit(false),
      );
      expect(
        SqlTypeSystem.convert(
          SqlValue.decimal('-0.01'),
          SqlTypeSpec.bit(),
        ),
        SqlValue.bit(true),
      );
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('false'),
          SqlTypeSpec.bit(),
        ),
        SqlValue.bit(false),
      );
    });
  });

  group('Character and binary type validation', () {
    test('VARCHAR enforces selected single-byte code page', () {
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.nvarchar('محمد'),
          SqlTypeSpec.varchar(length: 10),
        ),
        throwsA(isA<SqlTypeException>()),
      );
      expect(
        SqlTypeSystem.convert(
          SqlValue.nvarchar('café'),
          SqlTypeSpec.varchar(length: 10),
          varcharCodePage: SqlVarcharCodePage.latin1,
        ),
        SqlValue.varchar('café'),
      );
    });

    test('NVARCHAR counts UTF-16 code units and preserves Arabic', () {
      expect(
        SqlTypeSystem.convert(
          SqlValue.nvarchar('محمد'),
          SqlTypeSpec.nvarchar(length: 4),
        ),
        SqlValue.nvarchar('محمد'),
      );
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.nvarchar('😀'),
          SqlTypeSpec.nvarchar(length: 1),
        ),
        throwsA(isA<SqlTypeException>()),
      );
    });

    test('CHAR and NCHAR pad with spaces', () {
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('A'),
          SqlTypeSpec.char(length: 3),
        ),
        SqlValue.char('A  '),
      );
      expect(
        SqlTypeSystem.convert(
          SqlValue.nvarchar('ع'),
          SqlTypeSpec.nchar(length: 2),
        ),
        SqlValue.nchar('ع '),
      );
    });

    test('string truncation is explicit, not silent', () {
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.varchar('Hello'),
          SqlTypeSpec.varchar(length: 3),
        ),
        throwsA(isA<SqlTypeException>()),
      );
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('Hello'),
          SqlTypeSpec.varchar(length: 3),
          truncateStrings: true,
        ),
        SqlValue.varchar('Hel'),
      );
    });

    test('BINARY pads zero bytes and VARBINARY does not', () {
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('0x01A0'),
          SqlTypeSpec.binary(length: 4),
        ),
        SqlValue.binary([1, 160, 0, 0]),
      );
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('0x01A0'),
          SqlTypeSpec.varbinary(length: 4),
        ),
        SqlValue.varBinary([1, 160]),
      );
    });

    test('binary values reject malformed hex and out-of-range bytes', () {
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.varchar('0x0G'),
          SqlTypeSpec.varbinary(length: 4),
        ),
        throwsA(isA<SqlTypeException>()),
      );
      expect(() => SqlValue.binary([256]), throwsArgumentError);
    });
  });

  group('Date, time and identifier validation', () {
    test('DATE and DATETIME enforce SQL Server date ranges', () {
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.varchar('1600-01-01'),
          SqlTypeSpec.dateTime(),
        ),
        throwsA(isA<SqlTypeException>()),
      );
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('0001-01-01'),
          SqlTypeSpec.date(),
        ),
        SqlValue.date(DateTime(1, 1, 1)),
      );
    });

    test('SMALLDATETIME rounds to the nearest minute', () {
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('2026-11-03T10:15:29'),
          SqlTypeSpec.smallDateTime(),
        ),
        SqlValue.dateTime(DateTime(2026, 11, 3, 10, 15)),
      );
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('2026-11-03T10:15:30'),
          SqlTypeSpec.smallDateTime(),
        ),
        SqlValue.dateTime(DateTime(2026, 11, 3, 10, 16)),
      );
    });

    test('TIME rounds to declared scale and rejects invalid clock values', () {
      expect(
        SqlTypeSystem.convert(
          SqlValue.time('15:30:00.1299'),
          SqlTypeSpec.time(scale: 2),
        ),
        SqlValue.time('15:30:00.13'),
      );
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.time('25:00:00'),
          SqlTypeSpec.time(),
        ),
        throwsA(isA<SqlTypeException>()),
      );
    });

    test('DATETIME rounds to SQL Server 1/300-second display increments', () {
      final converted = SqlTypeSystem.convert(
        SqlValue.varchar('2026-11-03T10:15:30.002'),
        SqlTypeSpec.dateTime(),
      ) as SqlDateTime;
      expect(converted.toSqlLiteral(), "'2026-11-03T10:15:30.003'");
    });

    test('DATETIME rejects an input that rounds outside its maximum', () {
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.varchar('9999-12-31T23:59:59.999'),
          SqlTypeSpec.dateTime(),
        ),
        throwsA(isA<SqlTypeException>()),
      );
    });

    test('DATETIME2 rounds to the declared scale and retains scale metadata', () {
      final converted = SqlTypeSystem.convert(
        SqlValue.varchar('2026-11-03T10:15:30.1236'),
        SqlTypeSpec.dateTime2(scale: 3),
      ) as SqlDateTime2;
      expect(converted.scale, 3);
      expect(converted.toSqlLiteral(), "'2026-11-03T10:15:30.124'");
    });

    test('DATETIMEOFFSET preserves the written numeric offset', () {
      final converted = SqlTypeSystem.convert(
        SqlValue.varchar('2026-11-03T10:15:30.123456+05:30'),
        SqlTypeSpec.dateTimeOffset(scale: 6),
      ) as SqlDateTimeOffset;
      expect(converted.offsetMinutes, 330);
      expect(
        converted.toSqlLiteral(),
        "'2026-11-03T10:15:30.123456+05:30'",
      );
    });

    test('DATETIMEOFFSET rejects offsets outside the supported range', () {
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.varchar('2026-11-03T10:15:30+14:01'),
          SqlTypeSpec.dateTimeOffset(),
        ),
        throwsA(isA<SqlTypeException>()),
      );
    });

    test('UNIQUEIDENTIFIER validates canonical GUID syntax', () {
      expect(
        SqlTypeSystem.convert(
          SqlValue.varchar('A0B1C2D3-E4F5-4678-9012-3456789ABCDE'),
          SqlTypeSpec.uniqueIdentifier(),
        ),
        SqlValue.uniqueIdentifier('a0b1c2d3-e4f5-4678-9012-3456789abcde'),
      );
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.varchar('not-a-guid'),
          SqlTypeSpec.uniqueIdentifier(),
        ),
        throwsA(isA<SqlTypeException>()),
      );
    });

    test('ROWVERSION cannot be assigned from a user value', () {
      expect(
        () => SqlTypeSystem.convert(
          SqlValue.binary(List<int>.filled(8, 0)),
          SqlTypeSpec.rowVersion(),
        ),
        throwsA(isA<SqlTypeException>()),
      );
    });
  });

  group('Implicit conversion policy', () {
    test('numeric widening is conservative and directional', () {
      expect(
        SqlTypeSystem.canImplicitlyConvert(
          SqlTypeKind.tinyIntType,
          SqlTypeKind.bigIntType,
        ),
        isTrue,
      );
      expect(
        SqlTypeSystem.canImplicitlyConvert(
          SqlTypeKind.floatType,
          SqlTypeKind.intType,
        ),
        isFalse,
      );
    });
  });
}
