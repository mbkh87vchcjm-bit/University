# Supported SQL / T-SQL Feature Specification

## Overview
SQL Student Studio focuses on educational T-SQL features commonly taught in introductory and intermediate university database courses.

## T-SQL Support Matrix

| Category | Command / Feature | Status | Notes |
|---|---|---|---|
| **Database DDL** | `CREATE DATABASE` | ✅ Supported | Creates a database workspace |
| | `DROP DATABASE` | ✅ Supported | Deletes a database workspace |
| | `USE <database>` | ✅ Supported | Switches active context |
| **Table DDL** | `CREATE TABLE` | ✅ Supported | Column types, NULL/NOT NULL, PK/FK |
| | `ALTER TABLE` | ✅ Supported | Add/Drop column |
| | `DROP TABLE` | ✅ Supported | Drops table from schema |
| **DML** | `INSERT INTO` | ✅ Supported | Single & Multi-row inserts |
| | `SELECT` | ✅ Supported | Projection, Filtering, Aggregation |
| | `UPDATE` | ✅ Supported | Value updates with WHERE clause |
| | `DELETE` | ✅ Supported | Row deletions with WHERE clause |
| **Filtering & Operators** | `=, <>, >, <, >=, <=` | ✅ Supported | Comparison operators |
| | `AND, OR, NOT` | ✅ Supported | Logical operators |
| | `LIKE, IN, BETWEEN` | ✅ Supported | Pattern matching & range filtering |
| | `IS NULL / IS NOT NULL` | ✅ Supported | Nullability checks |
| **Query Clauses** | `TOP (N)` | ✅ Supported | Row limiting (T-SQL syntax) |
| | `DISTINCT` | ✅ Supported | Duplicate suppression |
| | `ORDER BY (ASC / DESC)` | ✅ Supported | Sorting results |
| | `GROUP BY / HAVING` | ✅ Supported | Grouping & post-aggregation filtering |
| **Joins** | `INNER JOIN` | ✅ Supported | Basic multi-table joining |
| | `LEFT JOIN` | ✅ Supported | Outer joining |
| | `RIGHT JOIN / FULL JOIN` | 🟡 Planned (V1.5) | Advanced outer joins |
| **Batch Separator** | `GO` | ✅ Supported | Script batch splitting |
| **Constraints** | `PRIMARY KEY` | ✅ Supported | Uniqueness & non-null enforcement |
| | `FOREIGN KEY` | ✅ Supported | Referential integrity |
| | `NOT NULL`, `DEFAULT`, `UNIQUE` | ✅ Supported | Data integrity checks |
| | `CHECK` | 🟡 Partial | Basic evaluation |
| **Data Types** | `INT`, `BIGINT`, `SMALLINT` | ✅ Supported | Numeric types |
| | `DECIMAL`, `FLOAT` | ✅ Supported | Floating point / exact numeric |
| | `VARCHAR`, `NVARCHAR`, `CHAR` | ✅ Supported | String types |
| | `DATE`, `DATETIME`, `TIME` | ✅ Supported | Temporal types |
| | `BIT` | ✅ Supported | Boolean representation |
| **Programmability** | `VIEWS` | 🟡 Phase 2 | Basic View creation |
| | `STORED PROCEDURES` | 🟡 Phase 2 | Parameterized scripts |
| | `TRIGGERS` | ❌ Not Supported | Out of initial scope |

## Data Types Supported in Engine
1. **Integer Types**: `INT`, `BIGINT`, `SMALLINT`, `TINYINT`
2. **Decimal Types**: `DECIMAL(p, s)`, `FLOAT`
3. **String Types**: `VARCHAR(n)`, `NVARCHAR(n)`, `CHAR(n)`, `NCHAR(n)`
4. **DateTime Types**: `DATE`, `DATETIME`, `TIME`
5. **Boolean/Bit**: `BIT`
