# SQL Student Studio — Architecture

## Product boundary

SQL Student Studio is an offline-first mobile learning environment. Its T-SQL engine is an educational simulator written in pure Dart; it is not the Microsoft SQL Server Database Engine and does not host a SQL Server service on Android.

## Implemented application foundation

- Flutter / Material 3 application shell.
- Arabic-first five-destination navigation.
- Home workspace screen.
- Local SQLite metadata repository for workspace projects.
- Create, list, open, delete-with-confirmation, and restore-most-recently-opened project metadata.
- Light and dark themes, following the device system theme by default.
- Persistent System/Light/Dark theme preference in versioned app metadata storage.
- Honest planned-state screens for database exploration, SQL editing, and the learning academy.

Workspace metadata is stored separately from student SQL database state. The current SQLite workspace table stores only project identity and timestamps; it does not yet persist database schemas, SQL tables, or rows.

## Target architecture

```text
Flutter Presentation
  Home | Databases | Query Editor | Results | Learn | More
           |
Application Services
  Workspace Projects | Scripts | Lessons | Progress | Settings
           |
T-SQL Domain Engine (pure Dart)
  Batch Processor -> Lexer -> Parser -> AST
  Binder/Validator -> Types & Collation
  Executor -> Transaction Coordinator -> Result/Diagnostics
           |
Storage Interfaces
  In-memory test adapter | Persistent student database adapter
           |
Local Workspace
  App metadata store | Student database catalog and row store
```

Phase 1 delivers the Flutter shell and workspace project metadata. Phase 2 adds isolated pure-Dart foundations for SQL type descriptors and conversion, SQL three-valued logic, and a deliberately limited collation profile. Phase 3 adds a source-aware lexer and GO batch handling. Phase 4 adds a syntax-only parser and AST for a documented T-SQL subset, including DML, joins, grouping, predicates, constraints, and transaction syntax. The parser is not connected to semantic binding, execution, or a persisted student database catalog.

## Storage separation

1. **Application workspace store:** project names, creation/open timestamps, settings, and later saved scripts and lesson progress.
2. **Student database store:** later stores database catalogs, schemas, tables, columns, constraints, and rows. It will be introduced separately behind the `DatabaseStorage` interface.

Do not store SQL student tables inside application project metadata records. The simulator must use explicit versioned migrations and atomic write operations.

## Engine isolation

The `lib/sql_engine/` domain layer must not import Flutter widgets, BuildContext, or presentation code. Storage must be injected through interfaces so that the same engine can use an in-memory adapter in tests and a persistent adapter in the application.

## Current source layout

```text
lib/
  app/                 # app configuration and theme
  core/
    models/            # workspace models
    storage/           # application workspace repository
  features/
    common/            # planned-feature state component
    home/              # workspace home
    navigation/        # five-destination app shell
  sql_engine/
    errors/            # structured SQL diagnostic model
    ast/               # syntax-tree node model
    lexer/             # token model, T-SQL scanner, and GO batch processor
    parser/            # recursive-descent statements and Pratt expressions
    models/            # database/table/constraint models
    storage/           # student database storage interface
    types/             # SQL value hierarchy
test/
  core/                # workspace model tests
  sql_engine/          # SQL lexer, parser, type, and foundation tests
  widget_test.dart     # application workflow tests
```

## Data and failure handling

- A malformed persisted project row must produce a controlled format error.
- Failed local database initialization must be retryable.
- Student data operations introduced in later phases must be atomic.
- No SQL statement error may leave partial mutations.
- The UI must preserve user-entered SQL when execution fails.
- No fake query history or sample records may be presented as actual student activity.

## Compatibility profile

The initial target is SQL Server 2014 / compatibility level 120 for the stated university lab environment. Later SQL Server versions must use separate feature profiles. Unsupported later-version syntax must be rejected or explicitly explained, not silently accepted in the 2014 profile.

## Quality gates

Every phase updates its implementation status and tests. A phase is complete only when static analysis, relevant unit/widget/integration tests, Android debug/release builds, and the documented acceptance checks pass.
