# Multi-PR Development Roadmap

## Strategy Overview
Development proceeds incrementally across isolated Pull Requests. No PR should attempt to implement the entire application at once.

---

## PR Sequence Plan

### 📑 PR #5 (Current) — Documentation Correction & Alignment
- [x] Update `README.md` with official description, status legend, and project architecture.
- [x] Align `docs/architecture.md` to single-module directory layout & dual DB strategy.
- [x] Align `docs/sql-supported.md` with explicit status codes (🟢 Implemented, 🟡 Planned, 🔴 Unsupported).
- [x] Update `docs/database-model.md` (`DatabaseStorage` abstraction, `ConstraintModel`, composite FK).
- [x] Update `docs/parser.md` (Batch Processor `GO`, Recursive Descent + Pratt Parser, `SqlError`).
- [x] Categorize UI features in `docs/ui.md` (MVP vs Phase 2 vs Future).
- [x] Define benchmark tests in `docs/testing.md` and detailed multi-PR roadmap in `docs/roadmap.md`.

---

### 🧱 PR #6 — Android Kotlin Project & SQL Engine Foundation
- Setup native Android project structure (`app/src/main/java/com/sqlstudentstudio/...`).
- Configure Kotlin, Jetpack Compose, Navigation, ViewModel, and Room setup.
- Implement core `SqlEngine` package interfaces, `SqlError` diagnostics, and initial `BatchProcessor`.
- Basic Home screen UI scaffold.

---

### 🔤 PR #7 — Lexer & Batch Processor
- Complete Lexer implementation for T-SQL keywords, operators, identifiers, and literals.
- String escaping support (`'Ali''s'`).
- `BatchProcessorTest` & `LexerTest` suite.

---

### 🌳 PR #8 — Parser & AST Nodes
- Recursive Descent Parser for statements.
- Pratt Parser for expression evaluation.
- AST node representations (`TableReference`, `ColumnReference`, `Expression`).
- `ParserTest` suite.

---

### 💾 PR #9 — Database & Table DDL Execution
- `DatabaseStorage` engine implementation.
- `CREATE DATABASE`, `DROP DATABASE`, `USE`.
- `CREATE TABLE`, `DROP TABLE`.
- `DDLTest` suite.

---

### 📥 PR #10 — Data Manipulation (INSERT & SELECT Engine)
- `INSERT INTO` engine logic.
- Basic `SELECT` projection & execution.
- Baseline benchmark integration test pass.

---

### 🔍 PR #11 — Filtering & Modifications (WHERE, UPDATE, DELETE)
- Expression evaluation in `WHERE` clauses.
- `UPDATE` and `DELETE` execution logic.
- Comparison and logical operators (`LIKE`, `IN`, `BETWEEN`, `IS NULL`).

---

### 🔒 PR #12 — Integrity Constraints Engine
- Primary Key uniqueness enforcement.
- Foreign Key referential integrity.
- `NOT NULL`, `DEFAULT`, and `UNIQUE` checks.

---

### 📊 PR #13 — Result Sorting & Manipulation
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
- Jetpack Compose Table Designer grid generating `CREATE TABLE` DDL.

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
