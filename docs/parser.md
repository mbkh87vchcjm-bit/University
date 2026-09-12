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

## 2. Lexer & Identifiers (`sqlengine/lexer`)

### Case Insensitivity Rules
- All SQL keywords, functions, and object identifiers (`Students`, `students`, `STUDENTS`) are **case-insensitive** during resolution, while preserving original casing for display purposes.

### Identifier Resolution Rules
- Supports single-part identifiers (`Students`) resolving to default schema `dbo` (`dbo.Students`).
- Supports two-part schema identifiers (`dbo.Students`).
- Supports bracketed identifiers (`[Student Name]`).
- Three-part database identifiers (`University.dbo.Students`) are deferred to post-v1.0.

### String Escaping & Literals
- T-SQL single quote escaping (`'Ali''s'`) resolves to string value `Ali's`.
- Keyword `NULL` tokenizes to `SqlValue.Null`.

---

## 3. Parser Architecture (`sqlengine/parser`)
- **Statements**: Parsed using **Recursive Descent Parser**.
- **Expressions**: Parsed using **Pratt Expression Parser** to handle operator precedence (`AND`, `OR`, `NOT`, `=`, `<>`, `>`, `<`, `>=`, `<=`, `LIKE`, `IN`, `BETWEEN`, `+`, `-`, `*`, `/`).

### LIKE Pattern Semantics
- `%`: Matches zero or more arbitrary characters.
- `_`: Matches exactly one single character.

### Table & Column References
```kotlin
data class TableReference(
    val schema: String? = "dbo",
    val table: String,
    val alias: String? = null
)

data class ColumnReference(
    val schema: String? = null,
    val table: String? = null,
    val columnName: String
)
```

### Complete AST Statement Nodes
```kotlin
sealed interface SqlStatement

data class CreateDatabaseStatement(val dbName: String) : SqlStatement
data class UseDatabaseStatement(val dbName: String) : SqlStatement
data class DropDatabaseStatement(val dbName: String) : SqlStatement

data class CreateTableStatement(
    val tableRef: TableReference,
    val columns: List<ColumnDefinition>,
    val constraints: List<ConstraintModel>
) : SqlStatement

data class DropTableStatement(val tableRef: TableReference) : SqlStatement

data class InsertStatement(
    val tableRef: TableReference,
    val columns: List<String> = emptyList(),
    val valuesList: List<List<Expression>>
) : SqlStatement

data class SelectStatement(
    val isDistinct: Boolean = false,
    val top: Int? = null,
    val columns: List<SelectColumn>,
    val fromTable: TableReference?,
    val joins: List<JoinClause> = emptyList(),
    val whereClause: Expression? = null,
    val groupBy: List<Expression> = emptyList(),
    val having: Expression? = null,
    val orderBy: List<OrderByClause> = emptyList()
) : SqlStatement

data class UpdateStatement(
    val tableRef: TableReference,
    val assignments: Map<String, Expression>,
    val whereClause: Expression? = null
) : SqlStatement

data class DeleteStatement(
    val tableRef: TableReference,
    val whereClause: Expression? = null
) : SqlStatement
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

```kotlin
data class SqlError(
    val code: String,
    val category: ErrorCategory,
    val message: String,
    val line: Int,
    val column: Int,
    val suggestion: String? = null
)

enum class ErrorCategory {
    LEXER_ERROR,
    PARSER_ERROR,
    SEMANTIC_ERROR,
    TYPE_ERROR,
    CONSTRAINT_ERROR,
    EXECUTION_ERROR,
    STORAGE_ERROR
}
```

Example Output:
```
❌ SQL001: Syntax Error
Line 1, Column 10: Incorrect syntax near 'FORM'.
Suggestion: Did you mean 'FROM'?
```
