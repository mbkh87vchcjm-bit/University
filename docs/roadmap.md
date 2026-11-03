# SQL Student Studio — Development Roadmap v2.0

## 1. Product Definition

SQL Student Studio is an **offline-first mobile learning laboratory** for relational databases, T-SQL, and introductory SQL Server administration. It is designed for students who need to practise on Android without installing a database server on the phone.

The product contains two deliberately separate data systems:

1. **Application workspace store** — projects, saved scripts, lesson progress, preferences, recent files, and query history.
2. **Student database simulator** — databases, schemas, tables, columns, indexes, constraints, rows, security principals, and simulated administration state.

The simulator interprets a documented subset of T-SQL in Dart. It is not Microsoft SQL Server, does not host a SQL Server service, and must never claim that simulated backup files, execution plans, locks, or availability features are native SQL Server artifacts.

## 2. Compatibility Policy

### Primary educational baseline

- SQL Server 2014 (12.x), database compatibility level 120.
- The baseline is selected to match the stated university lab environment.
- The application must display the active compatibility profile in the editor and lesson screens.
- T-SQL features must be version-gated. A feature introduced after SQL Server 2014 must not silently run in the 2014 profile.
- SQL Server 2014 reached the end of standard extended support on 10 July 2024. It is retained here for classroom compatibility, not recommended as a new production deployment baseline.

### Future profiles

Add later profiles only after the 2014 baseline is tested:

- SQL Server 2016 / compatibility 130.
- SQL Server 2019 / compatibility 150.
- SQL Server 2022 / compatibility 160.
- SQL Server 2025 / compatibility 170, only after its feature set and compatibility rules are separately specified.

Examples of version gating: native JSON functions and Query Store belong to SQL Server 2016 and later, not the 2014 baseline.

### Collation and language

- Implement collation as a dedicated service. Never approximate it by lowercasing every identifier or string.
- Keep identifier resolution, string equality, ordering, and LIKE semantics distinct but driven by the selected collation where applicable.
- Support the baseline options needed for classroom work: case sensitivity (CI/CS) and accent sensitivity (AI/AS), with clearly documented limits.
- Support Arabic and Unicode data correctly, especially NVARCHAR/NCHAR and Unicode literals.
- Make the difference between VARCHAR code-page storage and Unicode types visible in lessons.
- Preserve source spelling for display even when name lookup is case-insensitive.

## 3. Product Principles

1. **Correctness before breadth:** implement a small, tested SQL subset before adding many commands.
2. **Honest support matrix:** every feature is marked Implemented, Partial, Planned, or Unsupported. A menu item must not imply a feature is operational.
3. **Offline by default:** the core editor, simulator, lessons, projects, and saved work must work without an account or network.
4. **Safe student sandbox:** all query execution is against a local practice database. Destructive statements show the target database/table and a confirmation where appropriate. A resettable sample database will be provided after the database engine exists; never fake it during the app-shell phase.
5. **No silent data loss:** persistence, migrations, backups, and restore operations are tested before release.
6. **Mobile-first interaction:** the editor, result grid, object explorer, keyboard, dialogs, and navigation are designed for a phone before tablet enhancement.
7. **Separation of concerns:** the T-SQL engine has no dependency on Flutter widgets or BuildContext. UI code must not parse SQL or mutate database rows directly.
8. **Educational explanation:** show the statement result, affected rows, error location, and a brief explanation appropriate to the learner.
9. **Traceable compatibility:** never invent Microsoft error numbers or claim exact SQL Server behavior unless verified. Use a separate SSS error namespace for simulator-only diagnostics.

## 4. Target Architecture

```
Flutter Presentation
  Home | Databases | Query Editor | Results | Learn | Administration
            |
Application Services
  Projects | Scripts | Lessons | Progress | Import/Export | Settings
            |
T-SQL Domain Engine (pure Dart)
  Batch Processor -> Lexer -> Parser -> AST
  Binder/Validator -> Type & Collation Services
  Executor -> Transaction Coordinator -> Result/Diagnostics
            |
Storage Interfaces
  In-memory test adapter | Persistent local adapter
            |
Local Workspace
  App metadata store | Student database catalog/data store
```

Required boundaries:

- Keep application metadata separate from student SQL data, even if both use local SQLite technology underneath.
- Provide an in-memory storage adapter for fast deterministic engine tests.
- Implement a persistent adapter behind the storage interface. The engine must not depend directly on Flutter UI or platform widgets.
- Use transactions and atomic write semantics for each SQL statement. A failed statement must not leave partial row changes.
- Add explicit schema/data migration versions for app upgrades.
- Keep sample databases and lesson content versioned and resettable.

## 5. Mobile Interface Plan

The interface is developed incrementally, not postponed until the final stage.

### Main navigation

Use a stable bottom navigation structure:

- **Home:** continue learning, recent projects, recent scripts, last activity, and quick actions.
- **Databases:** database/object explorer and sample projects.
- **Query:** SQL editor, execution controls, results, and messages.
- **Learn:** courses, guided labs, exercises, and progress.
- **More:** administration labs, backups, settings, help, and about.

### Query workspace

- Monospace SQL editor with line numbers, syntax highlighting, selection execution, run-current-batch, and run-all.
- Show current project, active database, compatibility profile, and unsaved state.
- Results, Messages, and (where implemented) Execution Plan appear in a mobile-friendly tab panel.
- Results grid supports horizontal scrolling, row numbering, NULL display, column sizing, and copy/export.
- Add a compact SQL-key row for common symbols and keywords on touch devices; do not block the normal Android keyboard.
- Keep SQL text LTR while Arabic explanations/messages follow the appropriate RTL layout.
- Preserve editor text and cursor state when switching screens or rotating the device.

### Database Explorer

Use a tree structure that grows with implemented features:

- Databases -> Security / Schemas / Tables / Views / Programmability / Storage.
- Only show a node when the associated feature is available; otherwise show it explicitly as a learning preview or planned item.
- Object actions include View Data, Design, Script as CREATE, Rename (when supported), and Drop with a clear confirmation.

### Student usability

- First-run onboarding offers creation of an empty local workspace. Sample databases are installed only after the storage/catalog engine exists.
- No fake recent projects, fake timestamps, or sample query history presented as real user data.
- Empty states explain the next useful action.
- Error dialogs must not hide the SQL editor or erase the student's work.
- Support light/dark themes, scalable text, accessible touch targets, and small-screen layouts.

## 6. Fifteen Development Phases

Each phase is a separate reviewable unit. Do not start the next phase until the current phase passes its acceptance gate, unless a documented dependency requires a small shared foundation change.

### Phase 1 — Repository, Architecture, App Shell, and Reliability

**Goal:** establish a clean, maintainable SQL Student Studio application.

Work:
- Finish the removal of unrelated coursework and legacy medical branding from tracked project files.
- Confirm Android application ID, MainActivity package, label, launcher identity, and build workflow.
- Update README and all docs so the support matrix matches the actual code.
- Create the main navigation and real screen routing for Home, Databases, Query, Learn, and More.
- Remove placeholder buttons and fake recent activity; replace them with working empty states or disable actions until implemented.
- Add app-level error handling, logging suitable for offline debugging, settings persistence, and schema versioning.
- Provide a clear empty state and create-first-project flow. Defer sample database installation/reset until Phase 6 can create real catalog objects.
- Persist System/Light/Dark theme selection in the versioned app metadata store.
- Migrate the workspace metadata schema safely from version 1 to version 2.
- Keep Android as the release target; maintain other platform folders only if their build configuration remains valid.

Acceptance:
- No legacy product name or unrelated standalone coursework remains in app/project identity.
- Navigation works; no dead buttons are presented as functional.
- Fresh install, create/open/delete project, last-opened restoration, theme preference persistence, and schema v1-to-v2 migration pass without losing existing projects.
- `flutter analyze`, `flutter test`, debug APK build, and release APK build pass in CI.

### Phase 2 — SQL Types, Conversion Rules, NULL, and Collation

**Goal:** establish the semantic foundation used by every SQL statement.

Work:
- Validate numeric ranges and exact DECIMAL(p,s) precision/scale behavior.
- Add or specify required SQL Server 2014 types in priority order: integer types, DECIMAL/NUMERIC, MONEY/SMALLMONEY, FLOAT/REAL, BIT, character/Unicode, BINARY/VARBINARY, DATE/TIME/DATETIME/SMALLDATETIME/DATETIME2/DATETIMEOFFSET, UNIQUEIDENTIFIER, and ROWVERSION where justified.
- Implement type precedence, implicit/explicit conversion, overflow, truncation, and invalid conversion diagnostics.
- Implement SQL three-valued logic for NULL (TRUE/FALSE/UNKNOWN).
- Implement collation configuration and Arabic/Unicode test vectors.
- Clarify CHAR/VARCHAR byte/code-page limitations versus NCHAR/NVARCHAR Unicode behavior.

Current implementation checkpoint:
- Added type descriptors with parameter validation for DECIMAL/NUMERIC, FLOAT, character, binary, and temporal types.
- Added conversion and boundary validation for the documented subset of integer, numeric, text, binary, temporal, GUID, and ROWVERSION assignment behavior.
- Added standalone SQL TRUE/FALSE/UNKNOWN truth-table helpers.
- Added a deliberately limited collation profile with case/accent and Arabic combining-mark test vectors.
- Added tests for numeric boundaries, text lengths/code pages, binary values, temporal rounding, offset retention, NULL logic, and collation.
- Extended column metadata to retain an optional precision/scale-aware type descriptor.
- Added strict ISO-oriented date/time parsing that rejects normalized invalid calendar days and clock components.
- Enforced the SQL Server DATE range from 0001-01-01 through 9999-12-31, including explicit boundary tests.
- Corrected the supported numeric precedence direction and added regression tests.

**Phase 2 acceptance: PASSED** on commit `532da4358e5ceb3222dca70951f93d5124790010`.
The current-branch Flutter CI passed analysis and all 65 reported tests. The Android workflow passed debug and release APK builds and uploaded the release artifact. This accepts only the isolated type, conversion, NULL-logic, and collation foundations. They are still not wired into a SQL parser, DDL, DML, or a persistent student database.

Acceptance:
- Boundary and conversion tests cover the currently implemented type subset.
- NULL truth-table tests pass.
- Case/accent and Arabic comparison tests pass for the documented simulator profile.
- Unsupported types and conversions are rejected explicitly, never silently coerced.
- Flutter analysis, all tests, and Android debug/release builds pass on the phase 2 branch.

### Phase 3 — Lexer and Batch Processing

**Goal:** convert SQL source into correct tokens and batches.

Current implementation checkpoint (development branch):
- Added a pure-Dart scanner for the documented subset: keywords, Unicode identifiers, variables, bracketed and quoted identifiers, strings, numeric and binary literals, operators, punctuation, and comments.
- Added zero-based UTF-16 source offsets, one-based line/column spans, batch numbers, and stable SSS lexical diagnostics.
- Added nested block-comment support and CRLF/LF-aware position tracking.
- Reworked GO splitting to use lexer tokens in linear time, recognize isolated GO lines, retain positive repeat-count metadata, and reject malformed repeat syntax or a trailing multi-line block comment.
- GO text inside strings, comments, and quoted/bracketed identifiers is not treated as a batch separator.

**Phase 3 acceptance: PASSED** on code commit `c7b02a2e63077ab9dc5f8773c0aed294b42de3d4`.

- Flutter CI: static analysis passed and all 83 tests passed.
- Android CI: debug APK build passed, release APK build passed, and the `sql-student-studio-release-apk` artifact was uploaded.
- The accepted scope is the documented lexer subset and lexer-aware GO batch handling. It does not include a SQL statement parser, AST, semantic binder, or SQL execution.

Work:
- Tokenize keywords, identifiers, bracketed identifiers, quoted identifiers when enabled, literals, comments, punctuation, and multi-character operators.
- Handle escaped single quotes, Unicode string literals, decimal/exponent numbers, and source positions.
- Improve GO handling, including documented supported forms and clear rejection of unsupported repeat syntax.
- Track line, column, offset, and batch number for every token.
- Never treat keywords inside string literals or comments as executable syntax.

Acceptance:
- Lexer golden tests for valid and invalid input.
- Tests for CRLF/LF, nested block comment behavior if supported, quoted identifiers, multiline input, Arabic text, and GO edge cases.
- No uncaught exceptions for malformed input.

### Phase 4 — Parser and AST

**Goal:** create a structured representation of supported T-SQL.

Work:
- Build a recursive-descent statement parser and Pratt expression parser.
- Add AST nodes for supported DDL, DML, joins, predicates, expressions, constraints, and transaction statements.
- Preserve source spans on AST nodes.
- Implement operator precedence and parentheses correctly.
- Separate parse errors from semantic errors.
- Define a documented grammar subset for the 2014 profile.

Acceptance:
- Golden AST tests.
- Precedence and parenthesis tests.
- Negative syntax tests with exact line/column.
- The parser never executes or mutates data.

### Phase 5 — Semantic Binding, Validation, and Diagnostics

**Goal:** catch errors before execution.

Work:
- Resolve current database, schema, table, column, alias, and function names.
- Validate duplicate names, missing objects, ambiguous columns, invalid scope, and incorrect argument counts.
- Enforce data type compatibility and collation rules.
- Add structured error categories: lexical, syntax, binding, type, constraint, permission, transaction, execution, and storage.
- Show statement/batch context, line/column, message, and practical hint.
- Use actual SQL Server error numbers only when verified for the selected compatibility profile. Otherwise use SSS-specific codes.

Acceptance:
- Negative test corpus with no mutation on validation failure.
- Diagnostics identify the relevant token/span and offer useful hints.
- Error wording is localized without changing the stable error code.

### Phase 6 — Database Catalog, DDL, and Persistence

**Goal:** create the database objects that students manage.

Work:
- Implement database catalog, default dbo schema, custom schemas, and active database context.
- Implement CREATE/DROP DATABASE, CREATE/DROP TABLE, and staged ALTER TABLE operations.
- Add columns, defaults, identity metadata, nullability, and object naming rules.
- Persist databases, schemas, tables, constraints, and rows across app restarts.
- Add system-catalog learning views (for example a limited educational model of database/object metadata).
- Update Object Explorer as each catalog operation succeeds.

Acceptance:
- DDL integration tests and persistence/reopen tests.
- Duplicate object and missing database cases return diagnostics.
- Schema migration tests preserve existing student data.
- Explorer always matches the persisted catalog.

### Phase 7 — Core DML and Query Workspace

**Goal:** make the SQL editor genuinely useful.

Work:
- Implement INSERT (single/multi-row), SELECT projection, aliases, expressions, WHERE, ORDER BY, DISTINCT, and TOP.
- Implement UPDATE and DELETE with correct predicate evaluation.
- Show affected rows, returned rows, elapsed time, and diagnostics.
- Support executing current selection, current batch, or full script.
- Display tabular results, NULL values, empty results, and multiple result/message sections.
- Add query history and saved scripts.

Acceptance:
- End-to-end benchmark script creates a student database, table, inserts rows, queries, updates, and deletes.
- A failed statement is atomic.
- Editor contents survive navigation and app restart.
- Result values and row counts match expected test fixtures.

### Phase 8 — Relational Queries and Advanced SELECT

**Goal:** teach real relational query composition.

Work:
- INNER/LEFT/RIGHT/FULL joins in a staged sequence.
- CROSS JOIN and self-join after basic joins.
- COUNT/SUM/AVG/MIN/MAX, GROUP BY, HAVING.
- Subqueries, EXISTS, IN, UNION/UNION ALL, CASE, and common scalar functions.
- CTEs and window functions only after the baseline grammar/evaluator supports them.
- Add query examples that show intermediate concepts and explain join cardinality.

Acceptance:
- Join cardinality, NULL join behavior, grouping, aggregate, and nested-query tests.
- No incorrect duplicate elimination or row multiplication.
- Sample projects include multi-table scenarios (Students/Courses/Enrollments).

### Phase 9 — Constraints, Index Metadata, and Programmability

**Goal:** model relational integrity and commonly taught programmable objects.

Work:
- Enforce PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL, DEFAULT, and CHECK.
- Support single and composite keys, constraint naming, and referenced-column validation.
- Add identity behavior and sequence support as separately tested features.
- Implement Views after the SELECT engine is stable.
- Add a controlled subset of stored procedures and user-defined functions.
- Defer triggers, cursors, and dynamic SQL until their execution and recursion/security semantics can be tested safely.
- Add Visual Table Designer and ER Diagram screens based on the real catalog, not separate manually maintained data.

Acceptance:
- Constraint tests include duplicate, NULL, missing FK parent, and update/delete referential actions.
- Designer-generated SQL round-trips through the parser.
- ERD edges match actual PK/FK metadata.
- Unsupported programmable features are clearly marked.

### Phase 10 — Transactions and Concurrency Learning

**Goal:** teach ACID and transaction control without pretending the mobile simulator is a multi-user SQL Server instance.

Work:
- Implement BEGIN TRANSACTION, COMMIT, ROLLBACK, and SAVE TRANSACTION.
- Guarantee statement and transaction atomicity.
- Teach ACID using controlled examples.
- Add isolation-level concepts (READ UNCOMMITTED, READ COMMITTED, REPEATABLE READ, SERIALIZABLE, SNAPSHOT) as documented simulations.
- Build deterministic concurrency lessons for locks, blocking, deadlocks, and row-versioning.
- Clearly distinguish simulated schedules from real SQL Server locking internals.

Acceptance:
- Commit/rollback/savepoint tests, nested transaction behavior tests, and failure recovery tests.
- Concurrency labs produce deterministic, explainable outcomes.
- No feature is labelled as native multi-session concurrency unless a real backend exists.

### Phase 11 — Security and Permissions

**Goal:** teach database security concepts in a safe local sandbox.

Work:
- Model logins, database users, schemas, fixed/custom roles, and ownership.
- Implement a learning subset of GRANT, DENY, and REVOKE.
- Add a current-user/session selector for permission demonstrations.
- Teach least privilege, role membership, schema permissions, and ownership chaining.
- Add auditing lesson records for simulated administrative events.
- Never store real server passwords in the offline workspace.

Acceptance:
- Permission matrix tests for allowed and denied operations.
- Role membership changes are reflected immediately and persisted.
- Security labs cannot escape the local student workspace.

### Phase 12 — DBA Operations, Backup, and Recovery

**Goal:** give students a coherent administration workflow.

Work:
- Model database files, filegroups, growth settings, and recovery models conceptually.
- Teach SIMPLE, FULL, and BULK_LOGGED recovery behavior.
- Implement educational full, differential, and transaction-log backup snapshots in the app's own project format.
- Teach restore ordering, recovery points, and common restore mistakes.
- Add integrity-check lessons and a limited DBCC learning simulator.
- Add maintenance checklists and a simulated job scheduler; do not claim to run Windows SQL Server Agent jobs.

Acceptance:
- Backup/restore exercises recreate the exact saved workspace state.
- Invalid backup chains return actionable errors.
- Restore is atomic and can recover from an interrupted operation.
- Clearly state that the exported project backup is not a native SQL Server .bak file.

### Phase 13 — Performance, Indexes, and Monitoring

**Goal:** teach why query plans and indexes affect performance.

Work:
- Add clustered/nonclustered index concepts and a limited executable index model.
- Model statistics and cardinality estimates as educational approximations.
- Display a simulator-generated plan: table scan, index seek/scan, filter, sort, aggregate, and join operators as they become supported.
- Show estimated versus measured simulator work (rows visited, comparisons, elapsed time) with clear labels.
- Add practical labs for sargability, selectivity, covering-index concepts, and query rewrites.
- Add simulated DMV/wait-statistics dashboards only when backed by clearly defined simulator metrics.
- Keep SQL Server 2014 and later-version monitoring features separate; do not present Query Store as a 2014 feature.

Acceptance:
- Index correctness tests prove results equal indexed and non-indexed execution.
- Benchmarks use repeatable data sets and do not rely solely on wall-clock timing.
- Every plan view says "Educational simulated plan", not "Actual SQL Server execution plan".

### Phase 14 — High Availability, Distribution, and Data Services

**Goal:** introduce advanced DBA/BI subjects at a conceptual and scenario level.

Work:
- Lessons and diagrams for failover clustering, Always On availability groups, log shipping, replication, and recovery objectives.
- Explain SSIS/ETL, SSAS, SSRS, data warehouses, CDC, and Service Broker.
- Use guided scenario simulators for roles, data flow, synchronization, and failure recovery.
- Do not claim to create real clusters, replicas, agents, or SSIS packages from an Android-only offline app.
- Add modern-version labels where feature support differs from the 2014 profile.

Acceptance:
- Scenario state transitions are deterministic and explain their assumptions.
- Diagrams and reports identify simulated versus real operations.
- The feature matrix states the exact learning scope.

### Phase 15 — Learning Academy, Full UX Integration, QA, and Release

**Goal:** turn the engine into a useful and dependable student product.

Work:
- Build Arabic-first learning modules with English SQL terminology.
- Each lesson contains: concept, syntax, example, guided practice, expected result, automatic checking, explanation, and a next exercise.
- Organize learning paths: database basics, data types, DDL, DML, joins, constraints, transactions, security, DBA, and performance.
- Add exercises with graded difficulty, hints, progress tracking, bookmarks, and a resettable practice database.
- Add project-based labs: University, Library, Sales/Inventory, and other relational examples.
- Complete Object Explorer, editor, result grid, table designer, ERD, script manager, import/export, backup/restore UI, and settings.
- Add CSV/JSON result export and a versioned project backup/restore format.
- Add accessible RTL/LTR layout, light/dark theme selection, scalable fonts, onboarding, help, and an offline glossary.
- Run regression, persistence, migration, low-memory, small-screen, and usability tests.
- Prepare a release checklist, changelog, supported-feature matrix, and APK artifact.

Acceptance:
- Clean install and upgrade scenarios pass.
- All navigation and visible actions work; no dead buttons.
- All supported sample labs complete from a clean workspace.
- `flutter analyze`, `flutter test`, debug build, release build, and artifact upload pass.
- No known data-loss or crash blocker remains.
- Release notes clearly distinguish implemented, simulated, partial, and unsupported features.

## 7. Features Deliberately Outside the First Release

The following must not delay a correct and useful core product:

- Full SQL Server wire-protocol compatibility or running the actual SQL Server Database Engine on Android.
- Native compatibility with SQL Server `.bak` backup files.
- Production-grade multi-user locking, real Windows services, SQL Server Agent, failover clusters, or Always On deployment.
- Complete T-SQL grammar, every system stored procedure, every DMV, and every edition-specific Enterprise feature.
- Cloud accounts, mandatory telemetry, or mandatory internet access.

An optional real-server connection/gateway can be evaluated only after the offline product is stable, with explicit network configuration, encryption, least-privilege credentials, and clear separation from simulator mode.

## 8. Test and Quality Gates

Every phase must add tests at the layer it changes.

### Engine
- Unit tests for types, collation, conversion, NULL, lexer, parser, AST, binding, constraints, and evaluators.
- Golden scripts with expected result grids, affected row counts, and diagnostics.
- Atomicity tests: syntax/type/constraint errors must not partially mutate data.
- Persistence, migration, backup/restore, and interrupted-operation tests.
- Fuzz/malformed-input tests to confirm the engine returns diagnostics instead of crashing.

### UI and student workflow
- Widget and integration tests for navigation, editor state, query execution, result rendering, RTL/LTR, and accessibility.
- Small-screen checks (including narrow Android widths), keyboard resizing, and orientation changes.
- First-run, empty-state, restart, reset, and upgrade scenarios.

### CI and release
- `flutter pub get`
- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `flutter build apk --release`
- Upload the APK as a versioned GitHub Actions artifact.
- A phase is not complete until its workflow run is green and the support documentation is updated.

## 9. Delivery Rules

- Work on the feature branch and use an isolated PR/commit group per phase.
- Never merge to `main` without the user's explicit instruction.
- Before each phase, inspect the current branch head and existing changes; do not overwrite work from the user or another agent.
- Implement only the current phase and its required dependencies.
- After each phase, report: files changed, functionality implemented, test results, known limits, and the next phase.
- Never report "complete" based on code being present alone. Completion requires tests and a successful build.
- If a requirement cannot be implemented faithfully, mark it Partial or Unsupported and explain the limitation.

## 10. Immediate Starting Point

The next engineering action is **Phase 1 completion review**, not adding advanced SQL commands. Verify the recent repository cleanup, resolve any remaining legacy branding/assets or generated metadata, inspect the current GitHub Actions results, and confirm a release APK can be built. Then continue through the fifteen phases in order.
