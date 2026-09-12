# Supported SQL / T-SQL Feature Specification

## Overview
Status definitions used across SQL Student Studio documentation:

| Status Code | Meaning |
|---|---|
| 🟢 **Implemented** | Feature or foundation component is fully implemented and covered by unit tests. |
| 🟡 **Planned** | Feature specified and scheduled for upcoming development phases. |
| 🔵 **Partial** | Partial foundation capability currently supported in engine. |
| 🔴 **Unsupported** | Out of scope for current releases. |

---

## T-SQL Feature Matrix

| Category | Command / Feature | Status | Notes |
|---|---|---|---|
| **Foundation** | Architecture & Pure Dart Engine Setup | 🟢 Implemented (PR #5) | Standalone Dart engine layout, `SqlValue`, `BatchProcessor`, `DatabaseStorage` |
| **Database DDL** | `CREATE DATABASE` | 🟡 Planned (MVP) | Database creation (PR #9) |
| | `DROP DATABASE` | 🟡 Planned (MVP) | Database deletion (PR #9) |
| | `USE <database>` | 🟡 Planned (MVP) | Switches active database context (PR #9) |
| **Table DDL** | `CREATE TABLE` | 🟡 Planned (MVP) | Column definitions, constraints, default schema (`dbo`) (PR #9) |
| | `DROP TABLE` | 🟡 Planned (MVP) | Table deletion (PR #9) |
| | `ALTER TABLE` | 🟡 Planned (PR #20 / Phase 3) | Add/Drop column support in PR #20 / Phase 3 |
| **DML** | `INSERT INTO` | 🟡 Planned (MVP) | Single and multi-row insertions (PR #10) |
| | `SELECT` | 🟡 Planned (MVP) | Projection, filtering, sorting, distinct, top (PR #10) |
| | `UPDATE` | 🟡 Planned (MVP) | Row updates with WHERE filtering (PR #11) |
| | `DELETE` | 🟡 Planned (MVP) | Row deletions with WHERE filtering (PR #11) |
| **Filtering & Operators** | `=, <>, !=, >, <, >=, <=` | 🟡 Planned (MVP) | Comparison operators (PR #11) |
| | `AND, OR, NOT` | 🟡 Planned (MVP) | Logical operators (PR #11) |
| | `LIKE` | 🟡 Planned (MVP) | Pattern matching (`%` matches zero or more chars, `_` matches exactly one char) (PR #11) |
| | `IN, BETWEEN` | 🟡 Planned (MVP) | Set membership and range filtering (PR #11) |
| | `IS NULL / IS NOT NULL` | 🟡 Planned (MVP) | Nullability evaluation (PR #11) |
| **Result Controls** | `TOP (N)` | 🟡 Planned (MVP) | Row limit (T-SQL syntax) (PR #13) |
| | `DISTINCT` | 🟡 Planned (MVP) | Duplicate suppression (PR #13) |
| | `ORDER BY (ASC / DESC)` | 🟡 Planned (MVP) | Result sorting (PR #13) |
| **Batch Separator** | `GO` | 🟢 Implemented (PR #5) | Pre-lexer GO batch delimiter processor |
| **Constraints** | `PRIMARY KEY` | 🟡 Planned (MVP) | Single & composite primary keys (PR #12) |
| | `FOREIGN KEY` | 🟡 Planned (MVP) | Referential integrity constraints (PR #12) |
| | `NOT NULL` | 🟡 Planned (MVP) | Nullability constraint (PR #12) |
| | `DEFAULT` | 🟡 Planned (MVP) | Default value expression (PR #12) |
| | `UNIQUE` | 🟡 Planned (MVP) | Unique constraint (PR #12) |
| | `CHECK` | 🟡 Planned (Phase 3) | Expression constraint check |
| **Joins & Aggregates** | `INNER JOIN`, `LEFT JOIN` | 🟡 Planned (Phase 2) | Joins planned for post-MVP (PR #14) |
| | `GROUP BY / HAVING` | 🟡 Planned (Phase 2) | Grouping and aggregate filtering (PR #14) |
| | `COUNT, SUM, AVG, MIN, MAX` | 🟡 Planned (Phase 2) | Standard aggregate functions (PR #14) |
| **Programmability** | `VIEWS` | 🟡 Planned (Phase 3) | Views support |
| | `STORED PROCEDURES` | 🔴 Unsupported | Outside current scope |
| | `TRIGGERS` | 🔴 Unsupported | Outside current scope |

---

## SQL Data Types (MVP Baseline)
1. **Integer Types**: `INT`, `BIGINT`, `SMALLINT`, `TINYINT`
2. **Decimal / Numeric**: `DECIMAL(p,s)`, `FLOAT`
3. **Character / String**: `VARCHAR(n)`, `NVARCHAR(n)`, `CHAR(n)`, `NCHAR(n)`
4. **DateTime / Temporal**: `DATE`, `DATETIME`, `TIME`
5. **Bit / Boolean**: `BIT`
