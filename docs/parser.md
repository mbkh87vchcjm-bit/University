# Lexer, Parser & AST Pipeline Specification

## Overview
The SQL Engine parses T-SQL code through a multi-stage execution pipeline:

```
Raw SQL Script String
       │
       ▼
Batch Processor (Pre-lexer split by isolated GO directives)
       │
       ▼
Lexer / Tokenizer (Tokens, Literals, Identifiers, Escaped Strings)
       │
       ▼
Parser (Recursive Descent Parser + Pratt Expression Parser)
       │
       ▼
Abstract Syntax Tree (AST)
       │
       ▼
Semantic Validator & Schema Verification
       │
       ▼
Executor & Storage Abstraction Engine
```

---

## 1. Batch Processor (`GO` Separator)
The Batch Processor operates before the Lexer:
- Case-insensitive matching for isolated `GO` tokens (`GO`, `go`, `Go`).
- Strips leading/trailing whitespace around batch delimiters.
- **Strict String & Comment Exclusion**: `GO` appearing inside string literals (`SELECT 'GO';`) or inside line/block comments (`-- GO` or `/* GO */`) is treated as literal content and is **never** used as a batch separator.
- Handles empty batches and multiple consecutive `GO` statements gracefully without crashing or generating illegal AST nodes.
- Returns an ordered list of executable SQL batch strings.

---

## 2. Lexer & Identifiers (`lib/sql_engine/lexer/`)

### Case Insensitivity Rules
- All SQL keywords, functions, and object identifiers (`Students`, `students`, `STUDENTS`) are **case-insensitive** during resolution, while preserving original casing for display purposes.

### Identifier Resolution Rules
- Supports single-part identifiers (`Students`) resolving to default schema `dbo` (`dbo.Students`).
- Supports two-part schema identifiers (`dbo.Students`).
- Supports bracketed identifiers (`[Student Name]`).
- Three-part database identifiers (`University.dbo.Students`) are deferred to post-v1.0.

### String Escaping & Literals
- T-SQL single quote escaping (`'Ali''s'`) resolves to string value `Ali's`.
- Keyword `NULL` tokenizes to `SqlValue.nullValue()`.

---

## 3. Parser Architecture (`lib/sql_engine/parser/`)
- **Statements**: Parsed using **Recursive Descent Parser**.
- **Expressions**: Parsed using **Pratt Expression Parser** to handle operator precedence (`()`, `NOT`, `*`, `/`, `+`, `-`, comparison, `LIKE`, `IN`, `BETWEEN`, `IS NULL`, `AND`, `OR`).

### LIKE Pattern Semantics
- `%`: Matches zero or more arbitrary characters.
- `_`: Matches exactly one single character.

### Table & Column References
```dart
class TableReference {
  final String schema;
  final String table;
  final String? alias;

  const TableReference({
    this.schema = 'dbo',
    required this.table,
    this.alias,
  });
}

class ColumnReference {
  final String? schema;
  final String? table;
  final String columnName;

  const ColumnReference({
    this.schema,
    this.table,
    required this.columnName,
  });
}
```

### Complete AST Statement Nodes (Dart)
```dart
sealed class SqlStatement {
  const SqlStatement();
}

class CreateDatabaseStatement extends SqlStatement {
  final String dbName;
  const CreateDatabaseStatement(this.dbName);
}

class UseDatabaseStatement extends SqlStatement {
  final String dbName;
  const UseDatabaseStatement(this.dbName);
}

class DropDatabaseStatement extends SqlStatement {
  final String dbName;
  const DropDatabaseStatement(this.dbName);
}

class CreateTableStatement extends SqlStatement {
  final TableReference tableRef;
  final List<ColumnModel> columns;
  final List<ConstraintModel> constraints;

  const CreateTableStatement({
    required this.tableRef,
    required this.columns,
    this.constraints = const [],
  });
}

class DropTableStatement extends SqlStatement {
  final TableReference tableRef;
  const DropTableStatement(this.tableRef);
}

class InsertStatement extends SqlStatement {
  final TableReference tableRef;
  final List<String> columns;
  final List<List<Expression>> valuesList;

  const InsertStatement({
    required this.tableRef,
    this.columns = const [],
    required this.valuesList,
  });
}

class SelectStatement extends SqlStatement {
  final bool isDistinct;
  final int? top;
  final List<SelectColumn> columns;
  final TableReference? fromTable;
  final List<JoinClause> joins;
  final Expression? whereClause;
  final List<Expression> groupBy;
  final Expression? having;
  final List<OrderByClause> orderBy;

  const SelectStatement({
    this.isDistinct = false,
    this.top,
    required this.columns,
    this.fromTable,
    this.joins = const [],
    this.whereClause,
    this.groupBy = const [],
    this.having,
    this.orderBy = const [],
  });
}

class UpdateStatement extends SqlStatement {
  final TableReference tableRef;
  final Map<String, Expression> assignments;
  final Expression? whereClause;

  const UpdateStatement({
    required this.tableRef,
    required this.assignments,
    this.whereClause,
  });
}

class DeleteStatement extends SqlStatement {
  final TableReference tableRef;
  final Expression? whereClause;

  const DeleteStatement({
    required this.tableRef,
    this.whereClause,
  });
}
```

---

## 4. Specific Syntax Rules

### `DECIMAL(p, s)` Semantics
- In MVP, precision `p` and scale `s` must be specified explicitly (e.g., `DECIMAL(10, 2)`). Omitting parameters is rejected by the Parser in initial phases.

### `TOP (N)` Syntax
- MVP supports explicit parenthesized `TOP (N)` syntax (e.g., `SELECT TOP (5) * FROM Students`).

---

## 5. Error Diagnostic System (`SqlError`)
Structured diagnostic errors provide exact positioning and actionable feedback:

```dart
enum ErrorCategory {
  lexerError,
  parserError,
  semanticError,
  typeError,
  constraintError,
  executionError,
  storageError,
}

class SqlError implements Exception {
  final String code;
  final ErrorCategory category;
  final String message;
  final int line;
  final int column;
  final String? suggestion;

  const SqlError({
    required this.code,
    required this.category,
    required this.message,
    required this.line,
    required this.column,
    this.suggestion,
  });
}
```

Example Output:
```
❌ SQL001: PARSERERROR
Line 1, Column 10: Incorrect syntax near 'FORM'.
Suggestion: Did you mean 'FROM'?
```
