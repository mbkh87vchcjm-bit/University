# Testing Strategy & Guidelines

## Overview
Comprehensive test suites ensure that the custom SQL Engine accurately mirrors expected T-SQL behaviors and syntax rules.

## Test Categories

### 1. Unit Tests (`tests/unit`)
- **Lexer Tests (`LexerTest`)**: Validates tokenization of keywords, strings, numbers, identifiers, operators, and comments.
- **Parser Tests (`ParserTest`)**: Validates AST construction for `CREATE DATABASE`, `CREATE TABLE`, `INSERT`, `SELECT`, `UPDATE`, `DELETE`, `JOIN`, `GROUP BY`, and `GO` batch splits.
- **Validator Tests (`ValidatorTest`)**: Ensures schema validations catch non-existent tables, duplicate primary keys, foreign key violations, and column type mismatches.
- **Executor Tests (`ExecutorTest`)**: Validates execution results against expected row sets.

### 2. Integration Tests (`tests/integration`)
Flow tests verifying complete end-to-end database interactions:
```sql
CREATE DATABASE University;
GO
USE University;
GO
CREATE TABLE Students (ID INT PRIMARY KEY, Name NVARCHAR(100) NOT NULL, Age INT);
GO
INSERT INTO Students VALUES (1, 'Ahmed', 20), (2, 'Ali', 21);
GO
SELECT * FROM Students WHERE Age >= 20 ORDER BY Name;
GO
```

### 3. Error Case Tests (`tests/error`)
Verify friendly error messages and diagnostic positions for:
- Invalid SQL syntax (`SELECT * FORM Students;`)
- Non-existent objects (`Invalid object name 'Doctors'`)
- Non-existent columns (`Invalid column name 'Address'`)
- Constraint violations (Duplicate primary key insertion, FK nullability violations).

### 4. UI & ViewModel Tests (`tests/ui`)
- State management verification for ViewModels (`QueryEditorViewModel`, `DatabaseExplorerViewModel`).
- Auto-save debounce and crash recovery state tests.
