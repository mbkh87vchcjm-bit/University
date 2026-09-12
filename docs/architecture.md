# SQL Student Studio - System Architecture

## Overview
**SQL Student Studio** is an offline-first Android application designed for IT and Computer Science students who do not own a PC. It simulates a database development environment similar to Microsoft SQL Server Management Studio (SSMS), enabling students to practice T-SQL and manage relational databases on Android devices.

The application does NOT run Microsoft SQL Server natively. Instead, it embeds a custom educational SQL Engine (Lexer, Parser, AST, Validator, Execution Engine, Storage Layer) alongside an Android UI built with **Kotlin** and **Jetpack Compose**, with **Room / SQLite** handling local application metadata.

## Architectural Decision & Principles

### 1. Separation of Concerns
The SQL Engine is decoupled from the Android UI layer:

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

- **SQL Engine (`sqlengine/`)**: Pure Kotlin module (UI-independent). Responsible for lexing, parsing T-SQL, AST building, semantic validation, execution, and local storage state.
- **Android App (`app/`)**: Jetpack Compose UI, ViewModels, Room DAOs for application metadata (projects, settings, saved scripts, query history).

### 2. Execution Flow
```
SQL Text Input (Editor)
         ↓
  Batch Processor (GO Detector)
         ↓
   Lexer (Tokens)
         ↓
 Parser (Abstract Syntax Tree)
         ↓
  Validator (Schema Check)
         ↓
Execution Engine (Thread / Coroutine)
         ↓
 Storage Layer (SQLite / Internal Storage)
         ↓
 Result Set & Messages Grid
```

## Module Structure

```
SQL-Student-Studio/
│
├── app/
│   └── ui/
│       ├── home/          # Home screen, project list, recent scripts
│       ├── explorer/      # SSMS-like Database Tree Explorer
│       ├── editor/        # SQL Query Editor with IntelliSense & Highlighting
│       ├── results/       # Data result grids & messages
│       ├── files/         # Script file manager
│       ├── project/       # Project creation & settings
│       ├── diagram/       # ER Diagram visualization
│       └── settings/      # App preferences & theme configuration
│
├── domain/                # Use cases & business logic
├── data/                  # Room DAOs, repositories, local storage
├── sqlengine/
│   ├── lexer/             # SQL Tokenizer
│   ├── parser/            # T-SQL Parser & AST construction
│   ├── ast/               # Abstract Syntax Tree nodes
│   ├── validator/         # Semantic validation (tables, columns, types, constraints)
│   ├── executor/          # Query execution engine & context
│   ├── datatype/          # Supported data types (INT, VARCHAR, DATETIME, etc.)
│   └── error/             # Detailed SQL error mapping
│
├── intellisense/          # Schema-aware autocomplete provider
├── formatter/             # SQL code beautifier
├── export/                # Import/Export engine (.sql, .csv, .json, .zip)
└── docs/                  # Architecture & feature documentation
```
