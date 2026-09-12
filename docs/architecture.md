# SQL Student Studio - System Architecture

## Overview
**SQL Student Studio** is an offline-first T-SQL learning environment designed for Android students studying IT and Computer Science who do not own a PC. It provides an SSMS-inspired experience on mobile devices without attempting to run Microsoft SQL Server natively on Android.

---

## 🏛️ Architectural Principles & Decoupling

### 1. Standalone Pure Kotlin SQL Engine
The SQL Engine is decoupled from Android UI, Activities, Context, Compose, and Room. It is a pure Kotlin implementation that can be compiled and unit tested independently.

### 2. Dual Database Architecture
The application maintains two distinct database systems:
- **Application Database (Room / SQLite)**: Stores app metadata (projects, scripts, query history, settings, workspace state).
- **Student SQL Engine (Custom Educational Engine)**: Implements database concepts, T-SQL execution, schema management, data types, constraints, and local engine storage abstraction. Student data is never dumped directly into Room as a quick shortcut.

```
UI (Jetpack Compose)
       │
       ▼
   ViewModel
       │
       ▼
   Use Cases
       │
 ┌─────┴───────────────┐
 ▼                     ▼
Repositories       SqlEngine
 │                     │
 ▼                     ▼
Room              Engine Storage (DatabaseStorage)
 │
 ▼
SQLite
```

---

## 📁 Source Directory Layout

```
SQL-Student-Studio/
│
├── app/
│   └── src/
│       ├── main/
│       │   ├── java/com/sqlstudentstudio/app/
│       │   │   ├── ui/          # Jetpack Compose UI (screens, theme, components)
│       │   │   ├── domain/      # Domain models & Use Cases
│       │   │   ├── data/        # Room Database, DAOs, Repositories
│       │   │   ├── sqlengine/   # Pure Kotlin T-SQL Engine (Lexer, Parser, AST, Storage)
│       │   │   ├── intellisense/# Schema-aware suggestion provider
│       │   │   ├── formatter/   # SQL code formatter
│       │   │   ├── export/      # Import / Export (.sql, .csv, .json, .zip)
│       │   │   └── backup/      # Project zip backup & restore
│       │   │
│       │   └── res/             # Android Resources
│       │
│       ├── test/                # Local JVM Unit Tests (Engine & ViewModels)
│       └── androidTest/         # Instrumented Android & UI Tests
│
├── docs/                        # Specifications & Architecture Documentation
├── gradle/
├── build.gradle.kts
├── settings.gradle.kts
└── README.md
```

---

## ⚙️ SQL Engine Pipeline

```
SQL Text
   │
   ▼
Batch Processor (Splits raw script by GO separators)
   │
   ▼
Lexer (Tokenizes SQL keywords, operators, identifiers, literals)
   │
   ▼
Parser (Recursive Descent Parser + Pratt Expression Parser)
   │
   ▼
Abstract Syntax Tree (AST)
   │
   ▼
Semantic Validator (Type checking, schema validation, constraint checks)
   │
   ▼
Executor (Evaluates AST against DatabaseStorage context)
   │
   ▼
DatabaseStorage Engine Abstraction
   │
   ▼
QueryResult (Rows, affected count, execution time, messages, errors)
```
