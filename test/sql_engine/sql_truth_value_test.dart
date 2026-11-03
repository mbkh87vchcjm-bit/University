import 'package:flutter_test/flutter_test.dart';
import 'package:sql_student_studio/sql_engine/types/sql_truth_value.dart';

void main() {
  group('SQL three-valued logic', () {
    test('NOT preserves UNKNOWN', () {
      expect(
        SqlTruthValue.unknown.not(),
        SqlTruthValue.unknown,
      );
      expect(
        SqlTruthValue.trueValue.not(),
        SqlTruthValue.falseValue,
      );
    });

    test('AND follows SQL truth table', () {
      const values = SqlTruthValue.values;
      final expected = [
        [
          SqlTruthValue.trueValue,
          SqlTruthValue.falseValue,
          SqlTruthValue.unknown,
        ],
        [
          SqlTruthValue.falseValue,
          SqlTruthValue.falseValue,
          SqlTruthValue.falseValue,
        ],
        [
          SqlTruthValue.unknown,
          SqlTruthValue.falseValue,
          SqlTruthValue.unknown,
        ],
      ];

      for (var row = 0; row < values.length; row++) {
        for (var column = 0; column < values.length; column++) {
          expect(values[row].and(values[column]), expected[row][column]);
        }
      }
    });

    test('OR follows SQL truth table', () {
      const values = SqlTruthValue.values;
      final expected = [
        [
          SqlTruthValue.trueValue,
          SqlTruthValue.trueValue,
          SqlTruthValue.trueValue,
        ],
        [
          SqlTruthValue.trueValue,
          SqlTruthValue.falseValue,
          SqlTruthValue.unknown,
        ],
        [
          SqlTruthValue.trueValue,
          SqlTruthValue.unknown,
          SqlTruthValue.unknown,
        ],
      ];

      for (var row = 0; row < values.length; row++) {
        for (var column = 0; column < values.length; column++) {
          expect(values[row].or(values[column]), expected[row][column]);
        }
      }
    });

    test('WHERE accepts TRUE only', () {
      expect(SqlTruthValue.trueValue.passesWhere(), isTrue);
      expect(SqlTruthValue.falseValue.passesWhere(), isFalse);
      expect(SqlTruthValue.unknown.passesWhere(), isFalse);
    });

    test('nullable boolean maps null to UNKNOWN', () {
      expect(
        SqlTruthValue.fromNullableBool(null),
        SqlTruthValue.unknown,
      );
      expect(
        SqlTruthValue.fromNullableBool(false),
        SqlTruthValue.falseValue,
      );
    });
  });
}
