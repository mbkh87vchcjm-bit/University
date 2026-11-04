# T-SQL Parser and AST

## Pipeline

SQL script
  -> lexer-aware GO batch processor
  -> SQL lexer
  -> recursive-descent statement parser
  -> Pratt expression parser
  -> AST
  -> later phases: binder, validator, executor, storage

GO splitting is handled by the batch processor. TsqlParser parses one batch and accepts batchNumber, startOffset, startLine, and startColumn so AST spans can refer to the original script. It does not split GO or execute repeated batches.

## Parser contract

- Pure Dart. No Flutter dependency, storage access, database mutation, or SQL execution.
- Returns an immutable list of syntax-tree statements.
- AST nodes retain source spans: zero-based UTF-16 offsets, one-based line/column positions, and the batch number.
- Syntax diagnostics use SSS-PARSE-SYNTAX and ErrorCategory.parserError.
- Lexical failures remain SqlLexException; they are not reclassified as parser errors.
- Supports semicolon-separated statements and an optional final semicolon.
- The parser is case-insensitive for keywords but retains identifier spelling in AST nodes.

## Implemented grammar subset

### Statements

- CREATE DATABASE identifier, DROP DATABASE identifier, USE identifier
- CREATE TABLE [schema.]table (...), DROP TABLE [schema.]table
- Column declarations with type parameters, NULL / NOT NULL, IDENTITY(seed, increment), inline PRIMARY KEY, and inline UNIQUE.
- Table-level named or unnamed PRIMARY KEY (...), UNIQUE (...), and FOREIGN KEY (...) REFERENCES [schema.]table (...) declarations.
- INSERT [INTO] [schema.]table [(column, ...)] VALUES (...), (...)
- UPDATE [schema.]table SET column = expression [, ...] [WHERE expression]
- DELETE [FROM] [schema.]table [WHERE expression]
- SELECT [DISTINCT] [TOP (integer)] select_item, ... [FROM table [AS alias] join_clause ...] [WHERE expression] [GROUP BY expression, ...] [HAVING expression] [ORDER BY expression [ASC|DESC], ...]
- BEGIN [TRANSACTION|TRAN], COMMIT [TRANSACTION|TRAN], ROLLBACK [TRANSACTION|TRAN] [savepoint], and SAVE [TRANSACTION|TRAN] savepoint.

Supported join forms: JOIN, INNER JOIN, LEFT [OUTER] JOIN, RIGHT [OUTER] JOIN, FULL [OUTER] JOIN, and CROSS JOIN. Non-cross joins require an ON expression; CROSS JOIN rejects ON.

Identifiers may be regular, bracketed, or quoted identifiers as emitted by the lexer. Two-part schema-qualified names are supported. Three-part database.schema.table names are rejected.

### Expressions

The Pratt parser supports:
- Integer, decimal, approximate numeric, binary, string, Unicode string, and NULL literals.
- Identifiers, qualified identifiers, local variables, wildcard *, and function-call syntax. Keyword tokens followed by ( are accepted as function names, including aggregate names such as SUM.
- Parentheses and unary +, - and NOT.
- Multiplication, division, modulo, addition, and subtraction.
- Equality and relational comparisons.
- LIKE, NOT LIKE, IN, NOT IN, BETWEEN, NOT BETWEEN, IS NULL, and IS NOT NULL.
- Boolean AND and OR.

Precedence, from lowest to highest:

1. OR
2. AND
3. Comparisons, LIKE, IN, BETWEEN, and IS [NOT] NULL
4. + and -
5. *, /, and %
6. Unary + and -. NOT is a predicate-prefix operator: it consumes the following comparison predicate and stops before AND or OR.

## AST and semantics boundary

The AST is defined in lib/sql_engine/ast/sql_ast.dart; parsing is implemented in lib/sql_engine/parser/tsql_parser.dart.

AST nodes cover syntax for database/table statements, INSERT/UPDATE/DELETE/SELECT, joins, group/having/order clauses, table constraints, transaction statements, literals, identifiers, variables, functions, and predicates.

A parsed table constraint or data type is only syntax. The parser does not check whether referenced tables or columns exist, whether foreign-key column counts match, whether precision/scale is legal, or whether values match declared data types. Those checks belong to Phase 5 semantic binding/validation.

Transaction nodes describe transaction statements only. They do not start, commit, or roll back an actual transaction.

## Deliberate exclusions

Not yet accepted: ALTER TABLE, DEFAULT and CHECK constraints, subqueries, EXISTS, UNION, CASE, CAST / CONVERT, OUTPUT, OFFSET/FETCH, table-valued functions, PIVOT, APPLY, stored procedures, and full SQL Server grammar. Expression functions are parsed by name only; function existence and argument signatures are not validated here.

A successfully parsed statement is a syntax tree only. It is not proof that object names, constraints, functions, or data types exist, and it cannot be run against a student database yet.
