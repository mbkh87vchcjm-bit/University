# T-SQL Parser and AST

## Pipeline

SQL script
  -> lexer-aware GO batch processor
  -> SQL lexer
  -> recursive-descent statement parser
  -> Pratt expression parser
  -> AST
  -> later phases: binder, validator, executor, storage

GO splitting is performed by the existing batch processor. TsqlParser accepts the text of one batch; it does not interpret GO itself. The parser uses SqlLexer with comments omitted and retains the source coordinates supplied by tokens.

## Parser contract

- Pure Dart. No Flutter dependency, storage access, database mutation, or SQL execution.
- Returns an immutable list of syntax-tree statements.
- AST nodes retain source spans: zero-based UTF-16 offsets, one-based line/column positions, and the source batch number.
- Syntax diagnostics use SSS-PARSE-SYNTAX and ErrorCategory.parserError.
- Lexical failures remain SqlLexException; they are not reclassified as parser errors.
- The parser accepts semicolon-separated statements and an optional final semicolon.

## Implemented grammar subset

### Statements

- CREATE DATABASE identifier
- DROP DATABASE identifier
- USE identifier
- CREATE TABLE [schema.]table (column type [(parameters)] [NULL | NOT NULL] [IDENTITY [(seed, increment)]] [PRIMARY KEY], ...)
- DROP TABLE [schema.]table
- INSERT [INTO] [schema.]table [(column, ...)] VALUES (expression, ...), ...
- SELECT [DISTINCT] [TOP (integer)] select_item, ... [FROM [schema.]table [AS alias]] [WHERE expression] [ORDER BY expression [ASC|DESC], ...]

Identifiers may be regular, bracketed, or quoted identifiers as emitted by the lexer. Two-part schema-qualified names are supported. Three-part database.schema.table names are rejected for now.

### Expressions

The Pratt parser supports:
- Integer, decimal, approximate numeric, binary, string, Unicode string, and NULL literals.
- Identifiers, qualified identifiers, local variables, wildcard *, and function calls.
- Parentheses and unary +, - and NOT.
- Multiplication, division, modulo, addition, subtraction.
- Equality and relational comparisons.
- LIKE, NOT LIKE, IN, NOT IN, IS NULL, and IS NOT NULL.
- Boolean AND and OR.

The implemented precedence, from lowest to highest, is:

1. OR
2. AND
3. Comparisons, LIKE, IN, and IS [NOT] NULL
4. + and -
5. *, /, and %
6. Unary +, - and NOT. NOT binds to a comparison expression, as required for SQL boolean predicates.

## AST model

The AST is defined in lib/sql_engine/ast/sql_ast.dart; parsing is implemented in lib/sql_engine/parser/tsql_parser.dart.

Statement nodes currently cover database context statements, table DDL syntax, INSERT syntax, and SELECT syntax. Expression nodes are separate from statements and preserve original literal spelling while storing decoded string content.

SqlColumnDefinition retains parsed type name and raw type parameters. Mapping those values to validated SQL type descriptors is a semantic-binding responsibility and is not performed by the parser.

## Deliberate exclusions in this parser increment

The following are not yet accepted: UPDATE, DELETE, ALTER TABLE, joins, GROUP BY, HAVING, UNION, subqueries, CASE, CAST/CONVERT, BETWEEN, transaction statements, table-level constraints, DEFAULT/CHECK/FOREIGN KEY constraints, three-part object names, and function/type semantic validation.

A successfully parsed statement is only a syntactically structured AST. It is not proof that object names or data types exist, and it cannot be run against a student database yet.
