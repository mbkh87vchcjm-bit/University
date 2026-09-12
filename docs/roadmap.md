# Multi-PR Development Roadmap

## Strategy Overview
Development proceeds incrementally across isolated Pull Requests. PR #5 is the final documentation and specification PR; PR #6 initiates physical code implementation.

---

## PR Sequence Plan

### 📑 PR #5 (Final Spec) — Documentation Correction & Final Specification
- [x] Update `README.md` with official description, status legend, and project architecture.
- [x] Align `docs/architecture.md` to standalone `sqlengine` module layout & dual DB strategy.
- [x] Align `docs/sql-supported.md` with explicit status codes (🟢 Implemented, 🟡 Planned, 🔴 Unsupported).
- [x] Update `docs/database-model.md` (`SqlValue`, `DatabaseStorage` abstraction, `ConstraintModel`, composite PK/FK).
- [x] Update `docs/parser.md` (Batch Processor `GO`, Recursive Descent + Pratt Parser, complete AST nodes, `SqlError`).
- [x] Categorize UI features in `docs/ui.md` (MVP vs Phase 2 vs Future).
- [x] Define benchmark tests in `docs/testing.md` and detailed multi-PR roadmap in `docs/roadmap.md`.

---

### 🧱 PR #6 — Android Project & Standalone SQL Engine Setup
- Create root Gradle project structure with `app` (Android) and `sqlengine` (Pure Kotlin) modules.
- Ensure `sqlengine` compiles and executes unit tests independently on JVM without Android dependencies.
- Configure Kotlin, Jetpack Compose, Navigation, ViewModel, and Room setup in `app`.
- Implement `SqlEngine` package interfaces, `SqlError` diagnostics, and initial `BatchProcessor` skeleton.
- Basic Home screen UI scaffold.
- Verify first installable APK build.

---

### 🔤 PR #7 — Complete Lexer & Batch Processor
- Complete Lexer implementation for T-SQL keywords, operators, identifiers, and literals.
- String escaping support (`'Ali''s'`) and bracket identifiers (`[Name]`).
- `BatchProcessor` comment, string delimiter, and empty batch handling.
- `BatchProcessorTest` & `LexerTest` suite.

---

### 🌳 PR #8 — Parser & AST Nodes
- Recursive Descent Parser for DDL/DML statements.
- Pratt Parser for expression evaluation (`LIKE` pattern matching `%` and `_`).
- AST statement nodes (`InsertStatement`, `UpdateStatement`, `DeleteStatement`, `DropTableStatement`).
- `ParserTest` & Golden AST test suite.

---

### 💾 PR #9 — Database & Table DDL Execution
- `DatabaseStorage` engine implementation and `Persistent Engine Store` (`context.filesDir/student_db/`).
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
- `UPDATE` and `DELETE` execution logic.
- Comparison and logical operators (`LIKE`, `IN`, `BETWEEN`, `IS NULL`).

---

### 🔒 PR #12 — Integrity Constraints Engine
- Primary Key uniqueness enforcement (Single & Composite PK).
- Foreign Key referential integrity (Single & Composite FK with column count checks).
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

---

### 🛠️ PR #20 — Advanced DDL & Schema Evolution (Phase 3)
- `ALTER TABLE` execution engine (ADD column, DROP column).
- Schema evolution and migration support for student databases.
