# SQL Student Studio - System Architecture

## Overview
**SQL Student Studio** is an offline-first T-SQL learning environment designed for Android students studying IT and Computer Science who do not own a PC. It provides an SSMS-inspired experience on mobile devices without attempting to run Microsoft SQL Server natively on Android.

---

## 🏛️ Architectural Principles & Decoupling

### 1. Standalone Pure Kotlin SQL Engine
The SQL Engine is decoupled from Android UI, Activities, Context, Compose, and Room. It is a pure Kotlin module (`sqlengine`) that compiles and executes unit tests independently on JVM without Android dependencies.

### 2. Dual Database Architecture
The application maintains two distinct database systems:
- **Application Database (Room / SQLite)**: Stores app metadata (projects, scripts, query history, app settings, workspace state).
- **Student SQL Engine (Custom Educational Engine)**: Implements T-SQL database concepts, schema management, data types, constraints, AST evaluation, and local engine storage abstraction via `DatabaseStorage` and `Persistent Engine Store` (decoupled from Room).

```
Android App
│
├── Application Layer
│   ├── Jetpack Compose UI
│   ├── ViewModel & Use Cases
│   ├── Room DB
│   └── SQLite (App Metadata)
│
└── SQL Student Engine (Standalone Pure Kotlin)
    ├── Batch Processor (GO)
    ├── Lexer
    ├── Parser (Recursive Descent + Pratt)
    ├── AST
    ├── Validator
    ├── Executor
    ├── DatabaseStorage Abstraction
    └── Persistent Engine Store (Student DB Storage)
```

---

## 📁 Repository Directory Layout

To maintain clear separation, the project is structured with an `app` Android module and a standalone `sqlengine` Pure Kotlin module:

```
SQL-Student-Studio/
│
├── app/                         # Android Native Application Module
│   └── src/
│       ├── main/
│       │   ├── java/com/sqlstudentstudio/app/
│       │   │   ├── ui/          # Jetpack Compose UI (screens, theme, components)
│       │   │   ├── domain/      # Domain models & Use Cases
│       │   │   └── data/        # Room Database, DAOs, Repositories
│       │   └── res/             # Android Resources
│       ├── test/                # Local Android Viewmodel / Repository Tests
│       └── androidTest/         # Instrumented Android UI Tests
│
├── sqlengine/                   # Standalone Pure Kotlin Engine Module (No Android Dependencies)
│   └── src/
│       ├── main/kotlin/com/sqlstudentstudio/sqlengine/
│       │   ├── batch/           # GO Batch Processor
│       │   ├── lexer/           # SQL Tokenizer & String Escaper
│       │   ├── parser/          # Recursive Descent & Pratt Expression Parser
│       │   ├── ast/             # Abstract Syntax Tree Nodes
│       │   ├── validator/       # Semantic & Schema Validator
│       │   ├── executor/        # Expression Evaluator & Execution Engine
│       │   ├── model/           # SqlValue, TableModel, ConstraintModel
│       │   ├── storage/         # DatabaseStorage & Persistent Engine Store
│       │   └── error/           # SqlError Diagnostic System
│       └── test/kotlin/         # JVM Standalone Unit Tests
│
├── docs/                        # Specifications & Architecture Documentation
├── build.gradle.kts
├── settings.gradle.kts
└── README.md
```

*Note: Component directories such as `intellisense/`, `formatter/`, `export/`, and `backup/` will be introduced in their respective PRs as outlined in `docs/roadmap.md`.*

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
