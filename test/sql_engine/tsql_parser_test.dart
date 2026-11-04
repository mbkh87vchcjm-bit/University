import 'package:flutter_test/flutter_test.dart';
import 'package:sql_student_studio/sql_engine/ast/sql_ast.dart';
import 'package:sql_student_studio/sql_engine/errors/sql_error.dart';
import 'package:sql_student_studio/sql_engine/parser/tsql_parser.dart';

void main() {
  group('T-SQL statement parser', () {
    test('parses database statements and preserves source spans', () {
      final statements = TsqlParser(
        'CREATE DATABASE School; USE School; DROP DATABASE School;',
      ).parse();
      expect(statements, hasLength(3));
      expect(statements[0], isA<CreateDatabaseStatement>());
      expect((statements[0] as CreateDatabaseStatement).databaseName, 'School');
      expect(statements[1], isA<UseDatabaseStatement>());
      expect(statements[2], isA<DropDatabaseStatement>());
      expect(statements.first.span!.startLine, 1);
      expect(statements.first.span!.startColumn, 1);
    });

    test('parses CREATE TABLE type parameters and column modifiers', () {
      final statement = TsqlParser(
        'CREATE TABLE dbo.Students ('
        'Id INT IDENTITY(1,1) PRIMARY KEY, '
        'Name NVARCHAR(80) NOT NULL, '
        'Gpa DECIMAL(5,2) NULL'
        ');',
      ).parse().single as CreateTableStatement;
      expect(statement.table.schema, 'dbo');
      expect(statement.table.name, 'Students');
      expect(statement.columns, hasLength(3));
      expect(statement.columns[0].isIdentity, isTrue);
      expect(statement.columns[0].isPrimaryKey, isTrue);
      expect(statement.columns[0].isNullable, isFalse);
      expect(statement.columns[1].typeName, 'NVARCHAR');
      expect(statement.columns[1].typeArguments, ['80']);
      expect(statement.columns[1].isNullable, isFalse);
      expect(statement.columns[2].typeArguments, ['5', '2']);
      expect(statement.columns[2].isNullable, isTrue);
    });

    test('parses INSERT rows and Unicode Arabic string values', () {
      final statement = TsqlParser(
        "INSERT INTO Students (Id, Name) VALUES (1, N'محمد'), (2, N'علي');",
      ).parse().single as InsertStatement;
      expect(statement.table.name, 'Students');
      expect(statement.columns, ['Id', 'Name']);
      expect(statement.valueRows, hasLength(2));
      final name = statement.valueRows.first[1] as SqlLiteralExpression;
      expect(name.kind, SqlLiteralKind.unicodeString);
      expect(name.value, 'محمد');
    });

    test('parses SELECT TOP, DISTINCT, aliases, WHERE and ORDER BY', () {
      final statement = TsqlParser(
        "SELECT DISTINCT TOP (5) Name AS Student "
        "FROM dbo.Students AS s "
        "WHERE (Age >= 18 AND Active = 1) OR Name LIKE N'Ali%' "
        'ORDER BY Name DESC, Age ASC;',
      ).parse().single as SelectStatement;
      expect(statement.distinct, isTrue);
      expect(statement.top, 5);
      expect(statement.items.single.alias, 'Student');
      expect(statement.from!.schema, 'dbo');
      expect(statement.from!.alias, 's');
      expect(statement.where, isA<SqlBinaryExpression>());
      expect(statement.orderBy, hasLength(2));
      expect(statement.orderBy.first.ascending, isFalse);
      expect(statement.orderBy.last.ascending, isTrue);
    });

    test('applies arithmetic and boolean operator precedence', () {
      final statement = TsqlParser(
        'SELECT 2 + 3 * 4 FROM ValuesTable '
        'WHERE A = 1 OR B = 2 AND C = 3;',
      ).parse().single as SelectStatement;
      final projection = statement.items.single.expression as SqlBinaryExpression;
      expect(projection.operator, '+');
      expect((projection.right as SqlBinaryExpression).operator, '*');
      final predicate = statement.where! as SqlBinaryExpression;
      expect(predicate.operator, 'OR');
      expect((predicate.right as SqlBinaryExpression).operator, 'AND');
    });

    test('binds NOT less tightly than comparison operators', () {
      final statement = TsqlParser(
        'SELECT Id FROM Students WHERE NOT Active = 1 AND Age > 18;',
      ).parse().single as SelectStatement;
      final where = statement.where as SqlBinaryExpression;
      expect(where.operator, 'AND');
      expect(where.left, isA<SqlUnaryExpression>());
      final notExpression = where.left as SqlUnaryExpression;
      expect(notExpression.operator, 'NOT');
      expect(notExpression.operand, isA<SqlBinaryExpression>());
    });

    test('parses UPDATE and DELETE syntax without execution', () {
      final statements = TsqlParser(
        "UPDATE dbo.Students SET Name = N'محمد', Age = Age + 1 WHERE Id = 4; "
        "DELETE FROM dbo.Students WHERE Age < 18;",
      ).parse();
      final update = statements[0] as UpdateStatement;
      expect(update.table.schema, 'dbo');
      expect(update.assignments, hasLength(2));
      expect(update.assignments.first.column, 'Name');
      expect(update.where, isA<SqlBinaryExpression>());
      final delete = statements[1] as DeleteStatement;
      expect(delete.table.name, 'Students');
      expect(delete.where, isA<SqlBinaryExpression>());
    });

    test('parses INNER and LEFT JOIN with GROUP BY, HAVING and ORDER BY', () {
      final statement = TsqlParser(
        'SELECT s.DepartmentId, COUNT(*) AS Total '
        'FROM dbo.Students AS s '
        'INNER JOIN dbo.Departments AS d ON s.DepartmentId = d.Id '
        'LEFT OUTER JOIN dbo.Courses AS c ON c.DepartmentId = d.Id '
        'WHERE s.Active = 1 '
        'GROUP BY s.DepartmentId '
        'HAVING COUNT(*) > 2 '
        'ORDER BY s.DepartmentId;',
      ).parse().single as SelectStatement;
      expect(statement.joins, hasLength(2));
      expect(statement.joins[0].type, SqlJoinType.inner);
      expect(statement.joins[0].condition, isA<SqlBinaryExpression>());
      expect(statement.joins[1].type, SqlJoinType.left);
      expect(statement.groupBy, hasLength(1));
      expect(statement.having, isA<SqlBinaryExpression>());
      expect(statement.orderBy, hasLength(1));
    });

    test('parses BETWEEN and NOT BETWEEN with boolean precedence', () {
      final statement = TsqlParser(
        'SELECT Id FROM Students '
        'WHERE Age BETWEEN 18 AND 30 AND Score NOT BETWEEN 0 AND 49;',
      ).parse().single as SelectStatement;
      final where = statement.where as SqlBinaryExpression;
      expect(where.operator, 'AND');
      expect(where.left, isA<SqlBetweenExpression>());
      expect(where.right, isA<SqlBetweenExpression>());
      expect((where.right as SqlBetweenExpression).negated, isTrue);
    });

    test('parses named table constraints and column UNIQUE', () {
      final statement = TsqlParser(
        'CREATE TABLE Enrollments ('
        'StudentId INT NOT NULL, CourseId INT NOT NULL, '
        'Code VARCHAR(12) UNIQUE, '
        'CONSTRAINT PK_Enrollments PRIMARY KEY (StudentId, CourseId), '
        'CONSTRAINT FK_Student FOREIGN KEY (StudentId) '
        'REFERENCES Students (Id), '
        'CONSTRAINT UQ_Code UNIQUE (Code));',
      ).parse().single as CreateTableStatement;
      expect(statement.columns, hasLength(3));
      expect(statement.columns[2].isUnique, isTrue);
      expect(statement.constraints, hasLength(3));
      expect(statement.constraints[0].kind, SqlTableConstraintKind.primaryKey);
      expect(statement.constraints[0].columns, ['StudentId', 'CourseId']);
      expect(statement.constraints[1].referencedTable!.name, 'Students');
      expect(statement.constraints[1].referencedColumns, ['Id']);
      expect(statement.constraints[2].kind, SqlTableConstraintKind.unique);
    });

    test('parses transaction-control syntax and preserves batch coordinates', () {
      final statements = TsqlParser(
        'BEGIN TRANSACTION; SAVE TRANSACTION BeforeChange; '
        'ROLLBACK TRANSACTION BeforeChange; COMMIT TRANSACTION;',
        batchNumber: 4,
        startOffset: 200,
        startLine: 8,
      ).parse();
      expect(statements.map((s) => s is SqlTransactionStatement).every((v) => v), isTrue);
      final save = statements[1] as SqlTransactionStatement;
      expect(save.kind, SqlTransactionKind.save);
      expect(save.savepointName, 'BeforeChange');
      expect(statements.first.span!.batchNumber, 4);
      expect(statements.first.span!.startOffset, 200);
      expect(statements.first.span!.startLine, 8);
    });

    test('preserves variable prefixes in variable AST nodes', () {
      final statement = TsqlParser(
        'SELECT @studentId, @@ROWCOUNT;',
      ).parse().single as SelectStatement;
      expect(
        (statement.items[0].expression as SqlVariableExpression).name,
        '@studentId',
      );
      expect(
        (statement.items[1].expression as SqlVariableExpression).name,
        '@@ROWCOUNT',
      );
    });

    test('parses aggregate and reserved-word function names', () {
      final statement = TsqlParser(
        'SELECT COUNT(*), SUM(Age), AVG(Age), MIN(Age), MAX(Age), '
        'COALESCE(Score, 0) FROM Students;',
      ).parse().single as SelectStatement;
      expect(statement.items, hasLength(6));
      expect(
        (statement.items[1].expression as SqlFunctionCallExpression).name,
        'SUM',
      );
      expect(
        (statement.items[5].expression as SqlFunctionCallExpression).name,
        'COALESCE',
      );
    });

    test('parses RIGHT, FULL and CROSS JOIN forms', () {
      final right = TsqlParser(
        'SELECT A.Id FROM A RIGHT JOIN B ON A.Id = B.Id;',
      ).parse().single as SelectStatement;
      final full = TsqlParser(
        'SELECT A.Id FROM A FULL OUTER JOIN B ON A.Id = B.Id;',
      ).parse().single as SelectStatement;
      final cross = TsqlParser(
        'SELECT A.Id FROM A CROSS JOIN B;',
      ).parse().single as SelectStatement;
      expect(right.joins.single.type, SqlJoinType.right);
      expect(full.joins.single.type, SqlJoinType.full);
      expect(cross.joins.single.type, SqlJoinType.cross);
      expect(cross.joins.single.condition, isNull);
    });

    test('parses IS NULL, NOT IN, wildcard and function calls', () {
      final statement = TsqlParser(
        'SELECT COUNT(*) FROM Students '
        'WHERE Name IS NOT NULL AND Id NOT IN (2, 3);',
      ).parse().single as SelectStatement;
      expect(statement.items.single.expression, isA<SqlFunctionCallExpression>());
      final where = statement.where as SqlBinaryExpression;
      expect(where.operator, 'AND');
      expect(where.left, isA<SqlIsNullExpression>());
      expect((where.right as SqlInExpression).negated, isTrue);

      final wildcard = TsqlParser('SELECT * FROM Students;').parse().single as SelectStatement;
      expect(wildcard.items.single.expression, isA<SqlWildcardExpression>());
    });
  });

  group('T-SQL parser diagnostics', () {
    test('reports syntax errors with exact line and column', () {
      try {
        TsqlParser('SELECT 1\nFROM;').parse();
        fail('Expected a parser error.');
      } on SqlError catch (error) {
        expect(error.code, 'SSS-PARSE-SYNTAX');
        expect(error.category, ErrorCategory.parserError);
        expect(error.line, 2);
        expect(error.column, 5);
      }
    });

    test('rejects malformed JOIN and UPDATE syntax', () {
      expect(
        () => TsqlParser('SELECT * FROM A INNER B ON A.Id = B.Id;').parse(),
        throwsA(isA<SqlError>()),
      );
      expect(
        () => TsqlParser("UPDATE Students SET Name N'Ali';").parse(),
        throwsA(isA<SqlError>()),
      );
    });

    test('rejects statements that remain outside the parser subset', () {
      expect(
        () => TsqlParser('ALTER TABLE Students ADD Age INT;').parse(),
        throwsA(isA<SqlError>()),
      );
    });

    test('rejects unsupported three-part object names', () {
      expect(
        () => TsqlParser('SELECT Id FROM DbName.dbo.Students;').parse(),
        throwsA(isA<SqlError>()),
      );
    });

    test('rejects incomplete expressions and malformed column lists', () {
      expect(
        () => TsqlParser('SELECT 1 + FROM Students;').parse(),
        throwsA(isA<SqlError>()),
      );
      expect(
        () => TsqlParser('CREATE TABLE T (Id INT,);').parse(),
        throwsA(isA<SqlError>()),
      );
    });
  });
}
