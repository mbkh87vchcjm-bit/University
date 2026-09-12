# Lexer, Parser & AST Pipeline Specification

## Overview
The SQL Engine parses T-SQL code through a multi-stage execution pipeline:

```
Raw SQL Script String
       │
       ▼
Batch Processor (Pre-lexer split by GO directive)
       │
       ▼
Lexer / Tokenizer (Tokens & Escaped Strings)
       │
       ▼
Parser (Recursive Descent + Pratt Expression Parser)
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
- Ignores `GO` inside string literals (`'SELECT ''GO'';'`) or line comments.
- Returns an ordered list of executable SQL batch strings.

---

## 2. Lexer & String Escaping (`sqlengine/lexer`)
Converts batch text into tokens:
- **Keywords**: `SELECT`, `FROM`, `WHERE`, `INSERT`, `INTO`, `VALUES`, `UPDATE`, `SET`, `DELETE`, `CREATE`, `DATABASE`, `TABLE`, `DROP`, `ALTER`, `USE`, `DISTINCT`, `TOP`, `ORDER`, `BY`, `ASC`, `DESC`, `GROUP`, `HAVING`, `JOIN`, `INNER`, `LEFT`, `ON`, `AND`, `OR`, `NOT`, `LIKE`, `IN`, `BETWEEN`, `IS`, `NULL`, `PRIMARY`, `KEY`, `FOREIGN`, `REFERENCES`, `UNIQUE`, `DEFAULT`, `CHECK`, `AS`.
- **Operators**: `=`, `<>`, `!=`, `>`, `<`, `>=`, `<=`, `+`, `-`, `*`, `/`, `%`.
- **Symbols**: `(`, `)`, `,`, `;`, `.`, `[`, `]`.
- **Identifiers**: Standard identifiers (`Students`, `dbo.Students`) and bracketed identifiers (`[Student Name]`).
- **String Escaping**: T-SQL single quote escaping (`'Ali''s'`) resolves to the string value `Ali's`.

---

## 3. Parser Architecture (`sqlengine/parser`)
- **Top-Level Statements**: Parsed using **Recursive Descent Parser**.
- **Expressions (WHERE, HAVING, COMPUTED)**: Parsed using **Pratt Expression Parser** to handle operator precedence (`AND`, `OR`, `=`, `>=`, `LIKE`, arithmetic).

### Table & Column References
```kotlin
data class TableReference(
    val schema: String?,
    val table: String,
    val alias: String?
)

data class ColumnReference(
    val schema: String? = null,
    val table: String? = null,
    val columnName: String
)
```

### Abstract Syntax Tree (AST)
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

data class SelectStatement(
    val isDistinct: Boolean = false,
    val top: Int? = null,
    val columns: List<SelectColumn>,
    val fromTable: TableReference?,
    val whereClause: Expression? = null,
    val orderBy: List<OrderByClause> = emptyList()
) : SqlStatement
```

---

## 4. Error Diagnostic System (`SqlError`)
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
