# Supported SQL / T-SQL Feature Specification

## Overview
Status definitions used across SQL Student Studio documentation:

| Status Code | Meaning |
|---|---|
| 🟢 **Implemented** | Feature is fully implemented and covered by unit/integration tests in code. |
| 🟡 **Planned** | Feature specified and scheduled for upcoming development phases. |
| 🔵 **Partial** | Partial capability currently supported in engine. |
| 🔴 **Unsupported** | Out of scope for current releases. |

---

## T-SQL Feature Matrix

| Category | Command / Feature | Status | Notes |
|---|---|---|---|
| **Database DDL** | `CREATE DATABASE` | 🟡 Planned (MVP) | Database creation |
| | `DROP DATABASE` | 🟡 Planned (MVP) | Database deletion |
| | `USE <database>` | 🟡 Planned (MVP) | Switches active database context |
| **Table DDL** | `CREATE TABLE` | 🟡 Planned (MVP) | Column definitions, constraints, default schema (`dbo`) |
| | `DROP TABLE` | 🟡 Planned (MVP) | Table deletion |
| | `ALTER TABLE` | 🟡 Planned (Phase 3) | Add/Drop column support in Phase 3 |
| **DML** | `INSERT INTO` | 🟡 Planned (MVP) | Single and multi-row insertions |
| | `SELECT` | 🟡 Planned (MVP) | Projection, filtering, sorting, distinct, top |
| | `UPDATE` | 🟡 Planned (MVP) | Row updates with WHERE filtering |
| | `DELETE` | 🟡 Planned (MVP) | Row deletions with WHERE filtering |
| **Filtering & Operators** | `=, <>, !=, >, <, >=, <=` | 🟡 Planned (MVP) | Comparison operators |
| | `AND, OR, NOT` | 🟡 Planned (MVP) | Logical operators |
| | `LIKE, IN, BETWEEN` | 🟡 Planned (MVP) | Pattern matching & range filtering |
| | `IS NULL / IS NOT NULL` | 🟡 Planned (MVP) | Nullability evaluation |
| **Result Controls** | `TOP (N)` | 🟡 Planned (MVP) | Row limit (T-SQL syntax) |
| | `DISTINCT` | 🟡 Planned (MVP) | Duplicate suppression |
| | `ORDER BY (ASC / DESC)` | 🟡 Planned (MVP) | Result sorting |
| **Batch Separator** | `GO` | 🟡 Planned (MVP) | Batch separator pre-processor |
| **Constraints** | `PRIMARY KEY` | 🟡 Planned (MVP) | Single & composite primary keys |
| | `FOREIGN KEY` | 🟡 Planned (MVP) | Referential integrity constraints |
| | `NOT NULL` | 🟡 Planned (MVP) | Nullability constraint |
| | `DEFAULT` | 🟡 Planned (MVP) | Default value expression |
| | `UNIQUE` | 🟡 Planned (MVP) | Unique constraint |
| | `CHECK` | 🟡 Planned (Phase 3) | Expression constraint check |
| **Joins & Aggregates** | `INNER JOIN`, `LEFT JOIN` | 🟡 Planned (Phase 2) | Joins planned for post-MVP |
| | `GROUP BY / HAVING` | 🟡 Planned (Phase 2) | Grouping and aggregate filtering |
| | `COUNT, SUM, AVG, MIN, MAX` | 🟡 Planned (Phase 2) | Standard aggregate functions |
| **Programmability** | `VIEWS` | 🟡 Planned (Phase 3) | Views support |
| | `STORED PROCEDURES` | 🔴 Unsupported | Outside current scope |
| | `TRIGGERS` | 🔴 Unsupported | Outside current scope |

---

## SQL Data Types (MVP Baseline)
1. **Integer Types**: `INT`, `BIGINT`, `SMALLINT`, `TINYINT`
2. **Decimal / Numeric**: `DECIMAL(p,s)`, `FLOAT`
3. **Character / String**: `VARCHAR(n)`, `NVARCHAR(n)`, `CHAR(n)`, `NCHAR(n)`
4. **DateTime Types**: `DATE`, `DATETIME`, `TIME`
5. **Bit / Boolean**: `BIT`
