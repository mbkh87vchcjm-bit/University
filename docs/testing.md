# Testing Strategy & Validation Benchmark

## Overview
SQL Student Studio categorizes tests into distinct tiers:
1. **Foundation Tests (Implemented in PR #5)**: Validates `SqlValue` types, literal formatting, `BatchProcessor` GO pre-lexer splitting, and `TableModel` row ID allocation.
2. **Core Engine Tests (Planned PR #6–#12)**: Validates Lexer tokenization, Parser AST generation, Semantic Validation, Expression Evaluation, and Constraint checking.
3. **MVP Integration & Benchmark Tests (Planned PR #10–#13)**: End-to-end execution of T-SQL scripts.

---

## Test Suites Layout (Dart)

```
test/
├── sql_engine/
│   ├── batch_processor_test.dart   # GO batch delimiter, string, comment & empty batch tests (Implemented)
│   ├── sql_value_test.dart         # SqlValue formatting & quote escaping tests (Implemented)
│   ├── table_model_test.dart       # TableModel rowId allocation & FK validation tests (Implemented)
│   ├── lexer_test.dart             # Tokenization, string escaping ('Ali''s'), bracket identifiers (Planned PR #7)
│   ├── parser_test.dart            # AST parsing & Golden AST verification (Planned PR #8)
│   ├── validator_test.dart         # Semantic, schema & case-insensitivity validation (Planned PR #9)
│   ├── executor_test.dart          # Engine execution & result verification (Planned PR #10)
│   └── constraint_test.dart        # Single/Composite PK, FK, Unique, Default, Nullability tests (Planned PR #12)
│
└── widget_test.dart                # HomeScreen and App UI widget tests (Implemented)
```

---

## Foundation Test Coverage (PR #5 Implemented)
- **`BatchProcessor` Tests**: Validates mixed-case `GO` delimiters, empty/consecutive `GO`s, CRLF line endings, and string/comment exclusion (`SELECT 'GO';` or `-- GO`).
- **`SqlValue` Tests**: Validates canonical string decimals, number ranges (`SqlInt`, `SqlBigInt`, `SqlSmallInt`, `SqlTinyInt`), quote escaping (`'Ali''s'`), and `SqlDate` formatting.
- **`TableModel` Tests**: Validates `allocateRowId()` sequence incrementing and `ForeignKeyConstraint` column count mismatch exceptions.

---

## Essential Benchmark Test Flow (Planned MVP PR #10)

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
3. `CREATE TABLE` registers `NOT NULL` and `PRIMARY KEY` constraints.
4. `INSERT INTO` creates 2 records (`Affected rows: 2`).
5. `SELECT` returns filtered rows sorted by `Name` (`Returned rows: 2`).

---

## Type Mismatch & Statement Atomicity Test Specification

```sql
INSERT INTO Students (ID, Name, Age)
VALUES ('invalid', 'Ahmed', 20);
```
- **Atomicity Assertion**: A failed `INSERT` statement must abort immediately with a `typeError` category `SqlError` and leave zero partial row mutations in `DatabaseStorage`.
