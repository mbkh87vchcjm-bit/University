import 'package:flutter_test/flutter_test.dart';
import 'package:sql_student_studio/sql_engine/types/sql_value.dart';

void main() {
  group('SqlValue Tests', () {
    test('SqlNull equality and string representation', () {
      final null1 = SqlValue.nullValue();
      final null2 = SqlValue.nullValue();

      expect(null1, equals(null2));
      expect(null1.toString(), equals('NULL'));
    });

    test('SqlInt equality and string representation', () {
      final val1 = SqlValue.integer(42);
      final val2 = SqlValue.integer(42);
      final val3 = SqlValue.integer(100);

      expect(val1, equals(val2));
      expect(val1, isNot(equals(val3)));
      expect(val1.toString(), equals('42'));
    });

    test('SqlString equality and escaping representation', () {
      final str1 = SqlValue.string("Ali's");
      final str2 = SqlValue.string("Ali's");

      expect(str1, equals(str2));
      expect(str1.toString(), equals("'Ali's'"));
    });
  });
}
