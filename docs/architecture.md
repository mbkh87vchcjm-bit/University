# SQL Student Studio - System Architecture

## Overview
**SQL Student Studio** is an offline-first T-SQL learning environment designed for Android students studying IT and Computer Science who do not own a PC. It provides an SSMS-inspired experience on mobile devices without attempting to run Microsoft SQL Server natively on Android.

---

## 🏛️ Architectural Principles & Decoupling

### 1. Standalone Pure Dart SQL Engine
The SQL Engine is decoupled from Flutter UI, Widgets, BuildContext, and Flutter packages. It is located in `lib/sql_engine/` as a pure Dart package structure that compiles and executes unit tests independently without UI dependencies.

### 2. Dual Database Architecture
The application maintains two distinct database systems:
- **Application Database (App Storage / SQLite)**: Stores app metadata (projects, scripts, query history, app settings, workspace state).
- **Student SQL Engine (Custom Educational Engine)**: Implements T-SQL database concepts, schema management, data types, constraints, AST evaluation, and local engine storage abstraction via `DatabaseStorage` and `Persistent Engine Store` (decoupled from Flutter UI).

```
Flutter Application Layer (Implemented PR #5 Foundation)
│
├── App Layout (lib/app/, lib/core/, lib/features/)
│   ├── Navigation & Theme (Implemented Foundation)
│   ├── HomeScreen UI Scaffold (Implemented Foundation)
│   └── App Storage (SQLite Metadata)
│
└── SQL Student Engine (Pure Dart - lib/sql_engine/)
    ├── Batch Processor (GO) [🟢 Implemented PR #5]
    ├── SqlValue Types & SqlError [🟢 Implemented PR #5]
    ├── TableModel & ConstraintModel [🟢 Implemented PR #5]
    ├── DatabaseStorage Abstraction [🟢 Implemented PR #5]
    ├── Lexer [🟡 Planned PR #7]
    ├── Parser (Recursive Descent + Pratt) [🟡 Planned PR #8]
    ├── AST Statement & Expression Nodes [🟡 Planned PR #8]
    ├── Semantic Validator [🟡 Planned PR #9]
    ├── Execution Engine [🟡 Planned PR #10]
    └── Persistent Student DB Store [🟡 Planned PR #9]
```

---

## 📁 Repository Directory Layout

```
SQL-Student-Studio/
│
├── lib/
│   ├── main.dart                # Application entry point [Implemented PR #5]
│   │
│   ├── app/                     # App configuration [Implemented PR #5]
│   │   ├── app.dart
│   │   ├── router.dart
│   │   └── theme.dart
│   │
│   ├── core/                    # Core utilities & base storage [Implemented PR #5]
│   │
│   ├── features/                # Feature UI modules [Scaffolded PR #5]
│   │   ├── home/                # HomeScreen UI scaffold [Implemented PR #5]
│   │   ├── projects/
│   │   ├── explorer/
│   │   ├── editor/
│   │   └── results/
│   │
│   └── sql_engine/              # Standalone Pure Dart T-SQL Engine
│       ├── types/               # SqlValue hierarchy [🟢 Implemented PR #5]
│       ├── models/              # TableModel, ColumnModel, ConstraintModel, StoredRow [🟢 Implemented PR #5]
│       ├── storage/             # DatabaseStorage abstraction [🟢 Implemented PR #5]
│       ├── errors/              # SqlError diagnostic model [🟢 Implemented PR #5]
│       ├── lexer/               # GO Batch Processor [🟢 Implemented PR #5], Lexer [🟡 Planned PR #7]
│       ├── parser/              # Recursive Descent & Pratt Parser [🟡 Planned PR #8]
│       ├── ast/                 # Abstract Syntax Tree Nodes [🟡 Planned PR #8]
│       ├── validator/           # Semantic Validator [🟡 Planned PR #9]
│       └── executor/            # Execution Engine & Evaluator [🟡 Planned PR #10]
│
├── test/                        # Unit and Widget Tests
│   ├── sql_engine/              # SqlValue, TableModel, BatchProcessor unit tests [🟢 Implemented PR #5]
│   └── widget_test.dart         # HomeScreen widget test [🟢 Implemented PR #5]
│
├── docs/                        # Specifications & Architecture Documentation [🟢 Implemented PR #5]
├── pubspec.yaml                 # App identity & dependencies (`sql_student_studio`) [🟢 Implemented PR #5]
└── README.md
```

---

## ⚙️ SQL Engine Pipeline Execution Flow

```
Raw SQL Text
   │
   ▼
Batch Processor (Pre-lexer split by isolated GO directives) [🟢 Implemented PR #5]
   │
   ▼
Lexer (Tokenizes SQL keywords, operators, identifiers, literals, escaped strings) [🟡 Planned PR #7]
   │
   ▼
Parser (Recursive Descent Parser for DDL/DML + Pratt Expression Parser) [🟡 Planned PR #8]
   │
   ▼
Abstract Syntax Tree (AST) [🟡 Planned PR #8]
   │
   ▼
Semantic Validator (Type checking, schema verification, constraint rules) [🟡 Planned PR #9]
   │
   ▼
Executor (Evaluates AST expressions via ExpressionEvaluator) [🟡 Planned PR #10]
   │
   ▼
DatabaseStorage Engine Abstraction [🟢 Implemented API PR #5]
   │
   ▼
Persistent Engine Store (Saves student database state across app restarts) [🟡 Planned PR #9]
   │
   ▼
QueryResult (Returned rows for SELECT, affected rows for INSERT/UPDATE/DELETE, duration, diagnostics)
```
