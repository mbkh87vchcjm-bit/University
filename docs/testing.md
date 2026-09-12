# Testing Strategy & Validation Benchmark

## Overview
SQL Student Studio emphasizes rigorous testing of the SQL Engine separately from Android UI components.

---

## Test Suites Layout

```
app/src/test/java/com/sqlstudentstudio/
├── sqlengine/
│   ├── BatchProcessorTest.kt   # GO batch delimiter tests
│   ├── LexerTest.kt            # Tokenization & string escaping tests
│   ├── ParserTest.kt           # AST parsing (Recursive Descent + Pratt Parser)
│   ├── AstTest.kt              # AST node structure & mapping
│   ├── ValidatorTest.kt        # Semantic & schema validation
│   ├── ExecutorTest.kt         # Engine execution & result verification
│   ├── ConstraintTest.kt       # PK, FK, Unique, Default, Nullability tests
│   ├── StorageTest.kt          # DatabaseStorage implementation tests
│   └── ErrorTest.kt            # SqlError positioning & suggestion tests
│
└── viewmodel/
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
2. `USE` changes engine context to `University`.
3. `CREATE TABLE` enforces non-null constraints and primary key index.
4. `INSERT INTO` creates 2 records; duplicate primary key insertion throws `CONSTRAINT_ERROR`.
5. `SELECT` returns filtered rows sorted by `Name` with accurate row count (`2 rows affected`).

---

## Error Diagnostic Test Suite
Must verify precise line/column reporting and error suggestion for:
- Invalid Syntax (`SELECT * FORM Students;`) -> Suggests `FROM` at line 1, col 10.
- Missing Object (`SELECT * FROM UnknownTable;`) -> Throws `SEMANTIC_ERROR`.
- Type Mismatch (`INSERT INTO Students VALUES ('invalid', 'Ahmed', 20);`) -> Throws `TYPE_ERROR`.
- Foreign Key Violation -> Rejects non-existent referenced primary key.
