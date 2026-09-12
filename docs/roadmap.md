# Multi-PR Development Roadmap

## Strategy Overview
Development proceeds incrementally across isolated Pull Requests. PR #5 is the Foundation & Architecture Correction PR establishing the pure Dart/Flutter engine structure; PR #6 builds the core SQL Engine.

---

## PR Sequence Plan

### 📑 PR #5 (Current) — Foundation & Architecture Correction
- [x] Update `README.md` with official description, status legend, and Flutter architecture.
- [x] Align `docs/architecture.md` to standalone `lib/sql_engine/` Dart structure & dual DB strategy.
- [x] Align `docs/sql-supported.md` with explicit status codes (🟢 Implemented, 🟡 Planned, 🔴 Unsupported).
- [x] Update `docs/database-model.md` (`SqlValue`, `DatabaseStorage` abstraction, `ConstraintModel`, `StoredRow`).
- [x] Update `docs/parser.md` (Batch Processor `GO`, Recursive Descent + Pratt Parser, AST nodes, `SqlError`).
- [x] Categorize UI features in `docs/ui.md` (MVP vs Phase 2 vs Future).
- [x] Define benchmark tests in `docs/testing.md` and detailed multi-PR roadmap in `docs/roadmap.md`.
- [x] Implement core Dart foundation (`SqlValue`, `BatchProcessor`, `SqlError`, `DatabaseStorage`, `TableModel`).

---

### 🧱 PR #6 — Core Dart SQL Engine Infrastructure
- Implement `ExecutionContext`, `EngineResult`, and core engine interfaces in `lib/sql_engine/`.
- Ensure `lib/sql_engine/` compiles and executes unit tests independently on Dart VM without Flutter dependencies.
- Setup core engine execution state and error handling pipelines.

---

### 🔤 PR #7 — Complete Lexer & Batch Processor
- Complete Lexer implementation for T-SQL keywords, operators, identifiers, and literals.
- String escaping support (`'Ali''s'`) and bracket identifiers (`[Name]`).
- Extended `BatchProcessor` comment, string delimiter, empty/consecutive batch handling.
- `BatchProcessorTest` & `LexerTest` suite.

---

### 🌳 PR #8 — Parser & AST Nodes
- Recursive Descent Parser for DDL/DML statements.
- Pratt Parser for expression evaluation (`LIKE` pattern matching `%` and `_`).
- AST statement nodes (`InsertStatement`, `UpdateStatement`, `DeleteStatement`, `DropTableStatement`).
- `ParserTest` & Golden AST test suite.

---

### 💾 PR #9 — Database & Table Storage Implementation
- `DatabaseStorage` engine implementation and local document persistent store.
- `CREATE DATABASE`, `DROP DATABASE`, `USE`.
- `CREATE TABLE`, `DROP TABLE`.
- `DDLTest` suite.

---

### 📥 PR #10 — Data Manipulation (INSERT & SELECT Engine)
- `INSERT INTO` engine logic with `SqlValue` mapping and atomic failure guarantees.
- Basic `SELECT` projection & execution (`Returned rows` count).
- Baseline benchmark integration test pass.

---

### 🔍 PR #11 — Filtering & Modifications (WHERE, UPDATE, DELETE)
- Expression evaluation in `WHERE` clauses via `ExpressionEvaluator`.
- `UPDATE` and `DELETE` execution logic operating on stable `rowId`s.
- Comparison and logical operators (`LIKE`, `IN`, `BETWEEN`, `IS NULL`).

---

### 🔒 PR #12 — Integrity Constraints Engine
- Primary Key uniqueness enforcement (Single & Composite PK).
- Foreign Key referential integrity (Single & Composite FK with column count checks).
- `NOT NULL`, `DEFAULT`, and `UNIQUE` checks.

---

### 📊 PR #13 — Result Sorting & Manipulation (MVP Complete)
- `ORDER BY (ASC / DESC)` implementation.
- `DISTINCT` row deduplication.
- `TOP (N)` limiting.

---

### 🤝 PR #14 — Joins & Aggregations (Phase 2)
- `INNER JOIN` and `LEFT JOIN` execution algorithms.
- `GROUP BY` and `HAVING` logic.
- Aggregate functions (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`).

---

### 💡 PR #15 — IntelliSense & Formatter
- Offline schema-aware autocomplete provider.
- SQL code formatter component.

---

### 🛠️ PR #16 — Visual Table Designer
- Flutter Table Designer grid generating `CREATE TABLE` DDL.

---

### 🕸️ PR #17 — ER Diagram Viewer
- Interactive PK/FK relationship diagram canvas.

---

### 📦 PR #18 — File Management & Export/Import
- Local `.sql` file manager.
- CSV / JSON grid export.
- Project ZIP backup and restore.

---

### 🚀 PR #19 — Polishing, Optimization & Release Candidate
- Performance testing (1,000 - 10,000 row benchmarks).
- Theme polish (Light/Dark mode, Monospace font).
- Arabic & English RTL/LTR localization.
- Version 1.0 Release Candidate.

---

### 🛠️ PR #20 — Advanced DDL & Schema Evolution (Phase 3)
- `ALTER TABLE` execution engine (ADD column, DROP column).
- Schema evolution and migration support for student databases.
