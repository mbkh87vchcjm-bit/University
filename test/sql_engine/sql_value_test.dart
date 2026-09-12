import 'package:flutter_test/flutter_test.dart';
import 'package:sql_student_studio/sql_engine/types/sql_value.dart';

void main() {
  group('SqlValue Tests', () {
    test('SqlNull equality and string representation', () {
      final null1 = SqlValue.nullValue();
      final null2 = SqlValue.nullValue();

      expect(null1, equals(null2));
      expect(null1.toSqlLiteral(), equals('NULL'));
    });

    test('SqlInt equality and string representation', () {
      final val1 = SqlValue.integer(42);
      final val2 = SqlValue.integer(42);
      final val3 = SqlValue.integer(100);

      expect(val1, equals(val2));
      expect(val1, isNot(equals(val3)));
      expect(val1.toSqlLiteral(), equals('42'));
    });

    test('SqlDecimal canonical string equality and literal representation', () {
      final dec1 = SqlValue.decimal('123.456');
      final dec2 = SqlValue.decimal('123.456');

      expect(dec1, equals(dec2));
      expect(dec1.toSqlLiteral(), equals('123.456'));
    });

    test('SqlVarchar and SqlNVarchar escaping in toSqlLiteral', () {
      final strVarchar = SqlValue.varchar("Ali's");
      final strNVarchar = SqlValue.nvarchar("Ali's");

      expect(strVarchar.toSqlLiteral(), equals("'Ali''s'"));
      expect(strNVarchar.toSqlLiteral(), equals("N'Ali''s'"));
    });
  });
}
