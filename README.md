# SQL Student Studio

> **T-SQL Educational Environment for Android**
> An offline-first database development environment with an SSMS-inspired interface designed for IT and Computer Science students without a PC.

---

## 📱 About The Project

**SQL Student Studio** provides an experience similar to Microsoft SQL Server Management Studio (SSMS) directly on Android smartphones and tablets. It is built specifically for educational purposes to enable students to write, practice, and learn **T-SQL** and database design offline.

> **Note**: This application is an educational simulation environment for Android built with Flutter & Dart. It does NOT attempt to run Microsoft SQL Server natively on mobile devices. Project implementation proceeds incrementally across isolated PRs according to [`docs/roadmap.md`](./docs/roadmap.md).

---

## ✨ Feature Specification Scope

### 🟢 MVP Target Scope
*Note: These are overall MVP goals, not necessarily implemented in the initial foundation PR.*

- 📁 **Database Explorer**: Tree view navigation for Databases and Tables (`dbo` schema).
- 📝 **Query Editor**: Monospace SQL editor with line numbers, basic syntax highlighting, and execution controls.
- ⚡ **Execution Engine**: Standalone T-SQL execution (`CREATE DATABASE`, `USE`, `CREATE TABLE`, `INSERT`, `SELECT`, `UPDATE`, `DELETE`, `WHERE`, `ORDER BY`, `DISTINCT`, `TOP`, `GO` batch separator).
- 🔒 **Integrity Constraints**: Single & Composite `PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`, `DEFAULT`, `UNIQUE`.
- 📊 **Results & Messages**: Tabbed view displaying result grids, affected row counts (`INSERT`/`UPDATE`/`DELETE`), returned rows (`SELECT`), execution durations, and syntax diagnostics (`SqlError`).

### 🟡 Phase 2 & 3 Planned Features
- 📁 **Views Support**: Database Explorer tree view for Views (`CREATE VIEW` in Phase 3).
- 💡 **IntelliSense Autocomplete**: Real-time schema suggestions for database objects, tables, and columns (offline).
- 🛠️ **Visual Table Designer**: Visual table creation interface generating standard `CREATE TABLE` scripts.
- 🕸️ **ER Diagram Viewer**: Visual rendering of entity relationship diagrams built from primary/foreign key definitions.
- 📦 **Offline & Project Backup**: Save scripts, export query results to CSV/JSON, and package whole projects into `.zip` archives.

---

## 🏗️ Architecture & Technology Stack

- **Primary Language & Framework**: Dart & Flutter (Cross-platform mobile application)
- **UI Architecture**: Material 3 & Decoupled Features layout (`lib/features/`, `lib/app/`)
- **App Metadata Storage**: SQLite / Local storage for projects, saved scripts, history, settings.
- **SQL Execution Engine**: Pure Dart standalone engine (`lib/sql_engine/` containing `lexer/`, `parser/`, `ast/`, `validator/`, `executor/`, `storage/`, `types/`, `models/`, `errors/`)

```
Flutter Application Layer
│
├── App Layout (lib/app/, lib/core/, lib/features/)
│   ├── Navigation & Theme
│   ├── Home, Projects, Explorer, Editor, Results
│   └── App Storage (SQLite Metadata)
│
└── SQL Student Engine (Standalone Pure Dart - lib/sql_engine/)
    ├── Batch Processor (GO)
    ├── Lexer
    ├── Parser (Recursive Descent + Pratt)
    ├── AST Statement & Expression Nodes
    ├── Semantic Validator
    ├── Execution Engine
    ├── DatabaseStorage Abstraction
    └── Persistent Engine Store (Student DB State)
```

---

## 📂 Project Structure & Documentation

Detailed architecture and design specifications are located in the [`docs/`](./docs) directory:

- 📑 [`docs/architecture.md`](./docs/architecture.md) — Architectural principles & standalone `lib/sql_engine/` structure.
- 📑 [`docs/sql-supported.md`](./docs/sql-supported.md) — T-SQL feature matrix & data types specification.
- 📑 [`docs/database-model.md`](./docs/database-model.md) — App metadata models, `SqlValue` types, and `DatabaseStorage` engine structures.
- 📑 [`docs/ui.md`](./docs/ui.md) — Flutter UI layout, components & feature categorization.
- 📑 [`docs/parser.md`](./docs/parser.md) — Lexer, Pratt & Recursive Descent parser, AST, `GO` batch processing & validator pipeline.
- 📑 [`docs/testing.md`](./docs/testing.md) — Unit, integration, error diagnosis, and benchmark test suite.
- 📑 [`docs/roadmap.md`](./docs/roadmap.md) — Multi-PR implementation roadmap (PR #5 through PR #20).

---

## 🚀 Execution Benchmark Example

```sql
CREATE DATABASE University;
GO

USE University;
GO

CREATE TABLE Students
(
    ID INT PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Age INT
);
GO

INSERT INTO Students
VALUES
(1, 'Ahmed', 20),
(2, 'Ali', 21);
GO

SELECT *
FROM Students
WHERE Age >= 20
ORDER BY Name;
GO
```

---

## 📜 License

License not yet selected.
