# SQL Student Studio — SQL / T-SQL Support Matrix

## Status definitions

| Status | Meaning |
|---|---|
| **Implemented** | Implemented and covered by the relevant automated tests. |
| **Partial** | A working foundation exists, but important SQL Server behavior or integration is not complete. |
| **Planned** | Specified in the roadmap but not implemented. |
| **Unsupported** | Deliberately outside the currently planned teaching subset. |

## Current product boundary

SQL Student Studio is an offline educational simulator written in Dart. It is not the Microsoft SQL Server Database Engine and does not provide a SQL Server service on Android.

The current application can manage local learning workspace projects. The SQL type and logic modules are domain foundations; they are not yet connected to a SQL parser, query executor, or persisted student database catalog.

## SQL language features

| Feature | Status | Current capability |
|---|---|---|
| GO batch separation | **Partial** | Basic batch splitting exists. It is not yet a complete lexer-aware T-SQL batch implementation. |
| Full T-SQL lexer | Planned | Tokens, source spans, quoted identifiers, and robust comments are a later phase. |
| Parser and AST | Planned | SQL statements are not parsed into executable syntax trees yet. |
| Semantic binding | Planned | Database, schema, table, column, type, and function name resolution is not implemented. |
| CREATE DATABASE, DROP DATABASE, USE | Planned | Not executable yet. |
| CREATE TABLE, ALTER TABLE, DROP TABLE | Planned | Not executable yet. |
| INSERT, SELECT, UPDATE, DELETE | Planned | Not executable yet. |
| WHERE, comparisons, AND, OR, NOT, LIKE, IN, BETWEEN | Planned | Logical value helpers exist, but SQL expressions are not parsed or evaluated. |
| ORDER BY, DISTINCT, TOP | Planned | Not executable yet. |
| PRIMARY KEY, FOREIGN KEY, UNIQUE, DEFAULT, CHECK enforcement | Planned | Model classes exist; constraint validation is not connected to execution. |
| Joins and aggregates | Planned | No join or aggregate executor exists yet. |
| Transactions | Planned | Atomic SQL statement execution and transaction state are future work. |
| Views, procedures, triggers | Planned / staged | These are not part of the current phase 2 implementation. |

## Type-system foundation

The following descriptors and conversion rules have been added to the phase 2 development branch. They are tested as isolated Dart components; they are not yet enforced by CREATE TABLE or INSERT statements because those SQL commands have not been implemented.

| SQL Server type family | Current foundation |
|---|---|
| BIT, TINYINT, SMALLINT, INT, BIGINT | **Partial** — bounded conversion and basic literal normalization. |
| DECIMAL(p,s), NUMERIC(p,s) | **Partial** — precision/scale descriptor, exact decimal parsing, rounding, and overflow checks for supported decimal literals. |
| MONEY, SMALLMONEY | **Partial** — four-decimal conversion and numeric range checks. |
| FLOAT(n), REAL | **Partial** — finite-value checks; 4-byte rounding for the supported float precision profile and 64-bit values for the higher profile. |
| CHAR(n), VARCHAR(n/MAX) | **Partial** — length validation, fixed-width padding, and explicit truncation policy. The current code-page choices are ASCII and a limited Latin-1 profile, not the complete SQL Server code-page system. |
| NCHAR(n), NVARCHAR(n/MAX) | **Partial** — Unicode preservation and UTF-16 code-unit length checks. |
| BINARY(n), VARBINARY(n/MAX) | **Partial** — hexadecimal input, fixed-width zero padding, and length validation. |
| DATE, TIME(scale) | **Partial** — strict ISO-oriented calendar validation, SQL DATE range checks, and TIME precision normalization. TIME retains up to seven fractional digits as text. |
| SMALLDATETIME, DATETIME | **Partial** — range checks and the documented rounding model within Dart's available precision. |
| DATETIME2(scale), DATETIMEOFFSET(scale) | **Partial** — scale normalization and offset preservation; the seventh 100-nanosecond digit cannot be stored losslessly by Dart DateTime. |
| UNIQUEIDENTIFIER | **Partial** — canonical hyphenated GUID validation. |
| ROWVERSION | **Partial** — type descriptor only; assigning a literal is rejected. A future storage engine must generate rowversion values. |

## NULL, logical evaluation, and collation

| Component | Status | Limitation |
|---|---|---|
| SQL TRUE, FALSE, UNKNOWN truth values | **Implemented as a standalone helper** | Not yet connected to a SQL expression evaluator or WHERE implementation. |
| NOT, AND, OR truth tables | **Implemented as a standalone helper** | SQL expression parsing is still planned. |
| WHERE truth filter helper | **Implemented as a standalone helper** | No SQL query executor calls it yet. |
| Case/accent profile descriptors | **Partial** | The simulator provides a documented educational subset. |
| String equality and ordering | **Partial** | Ordinal comparison after limited normalization is not equivalent to SQL Server's full Windows linguistic collation implementation. |
| Arabic Unicode handling | **Partial** | Unicode values are preserved in NCHAR/NVARCHAR; selected Arabic combining marks may be ignored only in the simulator's accent-insensitive profile. |

## Explicit compatibility limitations

- Target classroom baseline: SQL Server 2014, compatibility level 120.
- Type descriptors do not imply that a SQL statement can declare or use that type yet.
- VARCHAR/CHAR currently support only the explicitly selected ASCII or limited Latin-1 code-page profiles. Use NVARCHAR/NCHAR for Arabic text in this simulator.
- Collation behavior is educational and deterministic, not a complete reproduction of SQL Server collation tables.
- DATETIME2(7) and DATETIMEOFFSET(7) retain scale metadata but cannot preserve all seven fractional digits internally because Dart DateTime is microsecond-based.
- Date/time parsing is deliberately limited to strict ISO-oriented forms. Invalid calendar days and clock components are rejected, and DATE range bounds are checked; SQL Server's full language, style, regional date-conversion, and all temporal edge-case behavior are not implemented.
- Decimal input currently supports ordinary signed decimal literals, not every numeric expression or scientific-notation conversion.
- ROWVERSION must be generated by a future database engine and cannot be inserted as a manually supplied literal.
- No SQL statement execution, student database persistence, or administration command is claimed as implemented by this phase.

