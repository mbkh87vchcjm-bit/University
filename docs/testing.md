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
4. `INSERT INTO` creates 2 records (`2 rows affected`). Duplicate primary key insertion throws `CONSTRAINT_ERROR`.
5. `SELECT` returns filtered rows sorted by `Name` (`Returned rows: 2`).

---

## Error Diagnostic Test Suite
Must verify precise line/column reporting and error suggestion for:
- Invalid Syntax (`SELECT * FORM Students;`) -> Suggests `FROM` at line 1, col 10.
- Missing Object (`SELECT * FROM UnknownTable;`) -> Throws `SEMANTIC_ERROR`.
- Type Mismatch (`INSERT INTO Students (ID, Name, Age) VALUES ('invalid', 'Ahmed', 20);`) -> Throws `TYPE_ERROR`.
- Foreign Key Violation -> Rejects non-existent referenced primary key.

---

## Specific Parser & Lexer Edge-Case Tests
- **String Escaping**: `'Ali''s'` tokenizes to string literal value `Ali's`.
- **Bracket Identifiers**: `[Student Name]` tokenizes to identifier `Student Name`.
- **Case-Insensitivity**: `students`, `Students`, `STUDENTS` resolve to the same table.
- **GO Delimiters**: `GO` inside strings (`'SELECT ''GO'';'`) or comments (`-- GO`) is ignored by `BatchProcessor`.
- **Golden AST Verification**: Serialized AST output compared against expected Golden AST structures.
