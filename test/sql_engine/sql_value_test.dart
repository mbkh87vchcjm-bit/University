import 'package:flutter_test/flutter_test.dart';
import 'package:sql_student_studio/sql_engine/types/sql_value.dart';

void main() {
  group('SqlValue Types & Literal Formatting Tests', () {
    test('SqlNull equality and string representation', () {
      final null1 = SqlValue.nullValue();
      final null2 = SqlValue.nullValue();

      expect(null1, equals(null2));
      expect(null1.toSqlLiteral(), equals('NULL'));
    });

    test('SqlInt, SqlBigInt, SqlSmallInt, SqlTinyInt equality and literal formatting', () {
      final intVal = SqlValue.integer(-2147483648);
      final bigIntVal = SqlValue.bigInt(9223372036854775807);
      final smallIntVal = SqlValue.smallInt(-32768);
      final tinyIntVal = SqlValue.tinyInt(255);

      expect(intVal.toSqlLiteral(), equals('-2147483648'));
      expect(bigIntVal.toSqlLiteral(), equals('9223372036854775807'));
      expect(smallIntVal.toSqlLiteral(), equals('-32768'));
      expect(tinyIntVal.toSqlLiteral(), equals('255'));
    });

    test('SqlDecimal canonical string equality and literal representation', () {
      final dec1 = SqlValue.decimal('123.456');
      final dec2 = SqlValue.decimal('123.456');

      expect(dec1, equals(dec2));
      expect(dec1.toSqlLiteral(), equals('123.456'));
    });

    test('SqlVarchar, SqlNVarchar, SqlChar, and SqlNChar escaping', () {
      final varchar = SqlValue.varchar("Ali's");
      final nvarchar = SqlValue.nvarchar("Ali's");
      final charVal = SqlValue.char("Ali's");
      final ncharVal = SqlValue.nchar("Ali's");

      expect(varchar.toSqlLiteral(), equals("'Ali''s'"));
      expect(nvarchar.toSqlLiteral(), equals("N'Ali''s'"));
      expect(charVal.toSqlLiteral(), equals("'Ali''s'"));
      expect(ncharVal.toSqlLiteral(), equals("N'Ali''s'"));
    });

    test('SqlBit formatting', () {
      final bitTrue = SqlValue.bit(true);
      final bitFalse = SqlValue.bit(false);

      expect(bitTrue.toSqlLiteral(), equals('1'));
      expect(bitFalse.toSqlLiteral(), equals('0'));
    });

    test('SqlDate, SqlTime, SqlDateTime formatting', () {
      final dateVal = SqlValue.date(DateTime(2026, 9, 12));
      final timeVal = SqlValue.time('15:30:00');
      final dateTimeVal = SqlValue.dateTime(DateTime(2026, 9, 12, 15, 30, 0));

      expect(dateVal.toSqlLiteral(), equals("'2026-09-12'"));
      expect(timeVal.toSqlLiteral(), equals("'15:30:00'"));
      expect(dateTimeVal.toSqlLiteral(), contains('2026-09-12'));
    });
  });
}
