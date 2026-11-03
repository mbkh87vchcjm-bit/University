# SQL Student Studio — Test Strategy

## 1. Test layers

The project is validated at four separate levels:

1. **Domain unit tests:** SQL values, model validation, batch processing, diagnostics, and other pure Dart behavior.
2. **Application storage integration tests:** real SQLite schema creation, migrations, persistence across close/reopen, and invalid settings.
3. **Widget tests:** navigation, planned-feature disclosures, project creation/open/delete, confirmation dialogs, and theme selection.
4. **Android build validation:** debug and release APK compilation plus GitHub Actions artifact upload.

## 2. Currently implemented tests

### Workspace models

- A valid database record maps into a WorkspaceProject.
- Malformed or incomplete stored records throw a controlled FormatException.

### Workspace SQLite repository

- A version-1 workspace database with an existing project is opened by the version-2 repository.
- The migration creates app settings without deleting the pre-existing project.
- The newly created project and selected theme are persisted.
- Closing and reopening the repository preserves projects and settings.
- Unsupported theme modes are rejected.

These tests use sqflite_common_ffi and a temporary SQLite database file on the CI runner. They exercise SQLite persistence and migration rather than a fake in-memory repository.

### Widget tests

- The app displays the SQL Student Studio home and five navigation destinations.
- Student can create a project through the create-project dialog.
- Database and query screens visibly identify themselves as planned features with the appropriate phase number.
- Student can open a project and delete it only after confirmation.
- Theme selection updates the application preference through the repository interface.

### SQL foundation tests

- BatchProcessor splits isolated GO separators with case-insensitive handling.
- It ignores GO in quoted strings and comments.
- It handles empty batches and CRLF line endings.
- SqlValue literal formatting and basic equality are tested.
- TableModel row ID allocation and foreign-key column-count validation are tested.

**Important:** SQL foundation tests do not indicate that complete T-SQL parsing, type conversion, SQL Server collation, DDL, or DML execution is implemented. Those are covered by later phases.

## 3. Required CI quality gates

Every Phase 1 revision must pass:

- flutter pub get
- dart format --output=none --set-exit-if-changed .
- flutter analyze
- flutter test
- flutter build apk --debug
- flutter build apk --release
- APK upload artifact sql-student-studio-release-apk

A green analyzer alone is not a successful phase. Both test workflows and the APK build workflow must pass on the current branch head.

## 4. Phase 1 acceptance checks

- New install initializes workspace metadata correctly.
- An existing v1 workspace migrates to v2 without losing projects.
- Create, list, open, delete, and last-opened restoration work.
- Theme preference (system/light/dark) survives database reopen.
- No UI action falsely implies that a SQL database or query engine has been implemented.
- Student-visible storage errors are actionable and do not expose internal exception details.
- Android package identity and app label use SQL Student Studio.
- No unrelated coursework, medical logo, or previous product identity remains in the active app identity.
