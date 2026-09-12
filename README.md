# SQL Student Studio

> **SQL Server Learning Environment on Android**
> An offline-first database development environment designed for IT and Computer Science students without a PC.

---

## 📱 About The Project

**SQL Student Studio** provides an experience similar to Microsoft SQL Server Management Studio (SSMS) directly on Android smartphones and tablets. It is built specifically for educational purposes to enable students to write, practice, and learn **T-SQL** and database design offline.

> **Note**: This application is an educational simulation environment for Android. It does NOT attempt to run Microsoft SQL Server natively on mobile devices.

---

## ✨ Key Features

- 📁 **Database Explorer**: Tree view navigation for Databases, Tables, Views, and Relationships (`dbo` schema).
- 📝 **Query Editor**: Multi-tab SQL editor with syntax highlighting, line numbers, and auto-formatting.
- 💡 **IntelliSense Autocomplete**: Real-time schema suggestions for database objects, tables, and columns (offline).
- ⚡ **Execution Engine**: Support for T-SQL statements, `GO` batch separators, filtering (`WHERE`, `LIKE`, `IN`, `BETWEEN`), sorting (`ORDER BY`), joins (`INNER`, `LEFT`), grouping (`GROUP BY`, `HAVING`), and constraints (`PRIMARY KEY`, `FOREIGN KEY`).
- 📊 **Results & Messages**: Tabbed view displaying result grids, affected row counts, execution durations, and syntax diagnostics.
- 🛠️ **Visual Table Designer**: Drag-and-drop table creation interface generating standard `CREATE TABLE` scripts.
- 🕸️ **ER Diagram Viewer**: Visual rendering of entity relationship diagrams built from primary/foreign key definitions.
- 📦 **Offline & Project Backup**: Save scripts, export query results to CSV/JSON, and package whole projects into `.zip` archives.

---

## 🏗️ Architecture & Technology Stack

- **Primary Language**: Kotlin (100% Android native)
- **UI Toolkit**: Jetpack Compose (Modern declarative UI)
- **App Storage / Metadata**: Room DB (SQLite foundation for application metadata, projects, saved scripts, history)
- **SQL Execution Engine**: Pure Kotlin standalone engine (`Lexer` -> `Parser` -> `AST` -> `Validator` -> `Executor` -> `Local Storage`)

```
                  SQL STUDENT STUDIO
                          │
                          ▼
                 Android Native App
                          │
                      Kotlin
                          │
                   Jetpack Compose
                          │
               ┌──────────┴──────────┐
               │                     │
         Application Layer       SQL Engine
               │                     │
             Room              Lexer / Parser
               │                     │
            SQLite             Validator
               │                     │
               │                 Executor
               │                     │
               └──────────┬──────────┘
                          │
                    Local Storage
```

---

## 📂 Project Structure & Documentation

Detailed architecture and design specifications are located in the [`docs/`](./docs) directory:

- 📑 [`docs/architecture.md`](./docs/architecture.md) — Architectural principles & module decoupling.
- 📑 [`docs/sql-supported.md`](./docs/sql-supported.md) — Supported T-SQL syntax & data types support matrix.
- 📑 [`docs/database-model.md`](./docs/database-model.md) — Room metadata models & student database engine structures.
- 📑 [`docs/ui.md`](./docs/ui.md) — Jetpack Compose UI layout, components & screens specification.
- 📑 [`docs/parser.md`](./docs/parser.md) — Lexer, parser, AST, `GO` batch processing & validator pipeline.
- 📑 [`docs/testing.md`](./docs/testing.md) — Unit, integration, error diagnosis, and UI testing guidelines.
- 📑 [`docs/roadmap.md`](./docs/roadmap.md) — MVP, v1.5, and v2.0 milestone plan.

---

## 🚀 Execution Example

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

Designed & Developed for IT and Computer Science Students.
