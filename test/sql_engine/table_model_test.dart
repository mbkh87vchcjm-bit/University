import 'package:flutter_test/flutter_test.dart';
import 'package:sql_student_studio/sql_engine/models/table_model.dart';
import 'package:sql_student_studio/sql_engine/types/sql_value.dart';

void main() {
  group('TableModel and ConstraintModel Tests', () {
    test('allocateRowId increments correctly', () {
      final table = TableModel(
        name: 'Students',
        columns: const [
          ColumnModel(name: 'ID', dataType: SqlDataType.intType, isNullable: false),
          ColumnModel(name: 'Name', dataType: SqlDataType.nvarcharType),
        ],
      );

      expect(table.allocateRowId(), equals(1));
      expect(table.allocateRowId(), equals(2));
      expect(table.allocateRowId(), equals(3));
    });

    test('ForeignKeyConstraint validates matching column counts', () {
      expect(
        () => ForeignKeyConstraint(
          columns: const ['StudentID', 'CourseID'],
          referencedTable: 'Enrollments',
          referencedColumns: const ['ID'],
        ),
        throwsArgumentError,
      );

      final validFk = ForeignKeyConstraint(
        columns: const ['StudentID'],
        referencedTable: 'Students',
        referencedColumns: const ['ID'],
      );
      expect(validFk.columns.length, equals(validFk.referencedColumns.length));
    });

    test('StoredRow holds rowId and SqlRow map', () {
      final row = StoredRow(
        rowId: 10,
        values: {
          'ID': SqlValue.integer(1),
          'Name': SqlValue.nvarchar('Ahmed'),
        },
      );

      expect(row.rowId, equals(10));
      expect(row.values['ID'], equals(SqlValue.integer(1)));
      expect(row.values['Name'], equals(SqlValue.nvarchar('Ahmed')));
    });
  });
}
