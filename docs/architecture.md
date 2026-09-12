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

## 📁 Repository Directory Layout

```
SQL-Student-Studio/
│
├── lib/
│   ├── main.dart                # Application entry point
│   │
│   ├── app/                     # App configuration (theme, router, app widget)
│   │   ├── app.dart
│   │   ├── router.dart
│   │   └── theme.dart
│   │
│   ├── core/                    # Core utilities, base storage, common widgets
│   │   ├── errors/
│   │   ├── storage/
│   │   └── widgets/
│   │
│   ├── features/                # Feature UI modules
│   │   ├── home/
│   │   ├── projects/
│   │   ├── explorer/
│   │   ├── editor/
│   │   └── results/
│   │
│   └── sql_engine/              # Standalone Pure Dart T-SQL Engine (No Flutter Dependencies)
│       ├── lexer/               # GO Batch Processor, Lexer & String Escaper
│       ├── parser/              # Recursive Descent & Pratt Expression Parser
│       ├── ast/                 # Abstract Syntax Tree Nodes
│       ├── validator/           # Semantic & Schema Validator
│       ├── executor/            # Expression Evaluator & Execution Engine
│       ├── types/               # SqlValue hierarchy & SQL data types
│       ├── storage/             # DatabaseStorage & Persistent Engine Store
│       └── errors/              # SqlError Diagnostic System
│
├── test/                        # Unit and Widget Tests
│   ├── sql_engine/
│   └── features/
│
├── docs/                        # Specifications & Architecture Documentation
├── pubspec.yaml
└── README.md
```

---

## ⚙️ SQL Engine Pipeline

```
Raw SQL Text
   │
   ▼
Batch Processor (Pre-lexer split by isolated GO directives)
   │
   ▼
Lexer (Tokenizes SQL keywords, operators, identifiers, literals, escaped strings)
   │
   ▼
Parser (Recursive Descent Parser for DDL/DML + Pratt Expression Parser for expressions)
   │
   ▼
Abstract Syntax Tree (AST)
   │
   ▼
Semantic Validator (Type checking, schema verification, constraint rules)
   │
   ▼
Executor (Evaluates AST expressions via ExpressionEvaluator)
   │
   ▼
DatabaseStorage Engine Abstraction
   │
   ▼
Persistent Engine Store (Saves student database state across app restarts)
   │
   ▼
QueryResult (Returned rows for SELECT, affected rows for INSERT/UPDATE/DELETE, execution duration, diagnostics)
```
