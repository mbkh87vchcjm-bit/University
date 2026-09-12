# Testing Strategy & Validation Benchmark

## Overview
SQL Student Studio emphasizes rigorous testing of the SQL Engine separately from Android UI components inside the standalone `sqlengine` module.

---

## Test Suites Layout

```
sqlengine/src/test/kotlin/com/sqlstudentstudio/sqlengine/
├── BatchProcessorTest.kt   # GO batch delimiter, string & comment tests
├── LexerTest.kt            # Tokenization, string escaping ('Ali''s'), bracket identifiers
├── ParserTest.kt           # AST parsing & Golden AST verification
├── AstTest.kt              # AST node structure & mapping
├── ValidatorTest.kt        # Semantic, schema & case-insensitivity validation
├── ExecutorTest.kt         # Engine execution & result verification
├── ConstraintTest.kt       # Single/Composite PK, FK, Unique, Default, Nullability tests
├── StorageTest.kt          # DatabaseStorage & Persistent Engine Store tests
└── ErrorTest.kt            # SqlError positioning & suggestion tests

app/src/test/java/com/sqlstudentstudio/app/
├── QueryEditorViewModelTest.kt
└── DatabaseExplorerViewModelTest.kt
```

---

## Result Terminology Assertions

To distinguish row counts across query types:
- **`SELECT` Queries**: Assert `Returned rows: N` (e.g., `Returned rows: 2`).
- **`INSERT` Queries**: Assert `Affected rows: N` (e.g., `Affected rows: 2`).
- **`UPDATE` Queries**: Assert `Affected rows: N` (e.g., `Affected rows: 1`).
- **`DELETE` Queries**: Assert `Affected rows: N` (e.g., `Affected rows: 1`).

---

## Essential Benchmark Test Flow

Every build must pass the core end-to-end execution benchmark test flow:

```sql
CREATE DATABASE University;
GO

USE University;
GO

CREATE TABLE Students (
    ID INT PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Age INT
);
GO

INSERT INTO Students
VALUES
(1, 'Ahmed', 20),
(2, 'Ali', 21);
GO

SELECT *
FROM Students
WHERE Age >= 20
ORDER BY Name;
GO
```

### Required Test Assertions:
1. `CREATE DATABASE` successfully registers database in `DatabaseStorage`.
2. `USE` changes active engine context to `University`.
3. `CREATE TABLE` enforces non-null constraints and primary key index.
4. `INSERT INTO` creates 2 records (`Affected rows: 2`). Duplicate primary key insertion throws `CONSTRAINT_ERROR`.
5. `SELECT` returns filtered rows sorted by `Name` (`Returned rows: 2`).

---

## Golden AST Test Specification
Parser tests must include Golden AST verification comparing parsed output against explicit AST data structures:

```kotlin
@Test
fun testSelectStatementGoldenAst() {
    val sql = "SELECT ID, Name FROM Students WHERE Age >= 20;"
    val ast = Parser(Lexer(sql).tokenize()).parseStatement()

    val expectedAst = SelectStatement(
        columns = listOf(
            SelectColumn.Simple(ColumnReference(columnName = "ID")),
            SelectColumn.Simple(ColumnReference(columnName = "Name"))
        ),
        fromTable = TableReference(schema = "dbo", table = "Students"),
        whereClause = BinaryExpression(
            left = ColumnExpression("Age"),
            operator = BinaryOperator.GREATER_THAN_OR_EQUAL,
            right = LiteralExpression(SqlValue.IntValue(20))
        )
    )

    assertEquals(expectedAst, ast)
}
```

---

## Batch Processor & Lexer Edge-Case Tests
- **Literal GO**: `SELECT 'GO';` -> `BatchProcessor` outputs 1 single batch; `GO` is not treated as a delimiter.
- **Commented GO**: `-- GO` or `/* GO */` -> `BatchProcessor` ignores `GO` inside comments.
- **String Escaping**: `'Ali''s'` tokenizes to string literal value `Ali's`.
- **Bracket Identifiers**: `[Student Name]` tokenizes to identifier `Student Name`.
- **Case-Insensitivity**: `students`, `Students`, `STUDENTS` resolve to the same table object.
