# Lexer, Parser & Execution Pipeline

## Overview
The SQL Engine parses and executes T-SQL input without relying on external cloud servers or PC environments.

## Pipeline Architecture

```
SQL Script String
       │
       ▼
Batch Processor (Detects GO separators)
       │
       ▼  (List of Batch SQL Strings)
 Lexer / Tokenizer
       │
       ▼  (List of Tokens: Keywords, Identifiers, Literals, Symbols)
 Parser (Recursive Descent / Pratt Parser)
       │
       ▼  (Abstract Syntax Tree - AST)
 Semantic Validator (Schema Provider check)
       │
       ▼  (Validated AST)
 Execution Engine (Evaluates AST against Local Storage Context)
       │
       ▼
 Query Result (Rows, Affected Count, Messages, Errors)
```

## Batch Processor & `GO` Directive
SQL Server uses `GO` to delimit batches of SQL statements:
- The Batch Processor splits raw SQL script text by `GO` tokens (case-insensitive on isolated lines).
- Each batch is parsed and executed sequentially within the current transaction context.

## Lexer Tokens (`sqlengine/lexer`)
- **Keywords**: `SELECT`, `FROM`, `WHERE`, `INSERT`, `INTO`, `VALUES`, `UPDATE`, `SET`, `DELETE`, `CREATE`, `DATABASE`, `TABLE`, `GO`, `JOIN`, `ON`, `GROUP`, `BY`, `HAVING`, `ORDER`, `ASC`, `DESC`.
- **Identifiers**: `Students`, `dbo.Doctors`, `[Age]`
- **Literals**: `'Ahmed'`, `20`, `3.14`, `1` (Bit)
- **Operators & Delimiters**: `=`, `<>`, `>`, `<`, `>=`, `<=`, `,`, `;`, `(`, `)`

## AST Structure (`sqlengine/ast`)
```kotlin
sealed class SqlStatement

data class CreateDatabaseStatement(val dbName: String) : SqlStatement()

data class CreateTableStatement(
    val tableName: String,
    val columns: List<ColumnDefinition>,
    val constraints: List<TableConstraint>
) : SqlStatement()

data class SelectStatement(
    val isDistinct: Boolean = false,
    val top: Int? = null,
    val columns: List<SelectColumn>,
    val fromTable: String,
    val joins: List<JoinClause> = emptyList(),
    val whereClause: Expression? = null,
    val groupBy: List<String> = emptyList(),
    val having: Expression? = null,
    val orderBy: List<OrderByClause> = emptyList()
) : SqlStatement()
```

## Error Handling & Diagnosis
Detailed errors report precise location and helpful suggestions:
```
❌ Syntax Error: Incorrect syntax near 'FORM'.
Line 1, Column 10
Suggestion: Did you mean 'FROM'?
```
