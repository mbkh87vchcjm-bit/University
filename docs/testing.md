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

### SQL foundation and phase 2 tests

- SqlLexer tokenizes the documented subset of keywords, Unicode identifiers, variables, quoted/bracketed identifiers, strings, numeric/binary literals, operators, punctuation, and comments.
- Lexer tokens retain source spans, batch numbers, and structured diagnostics; nested block comments and CRLF/LF are covered.
- BatchProcessor uses lexer tokens to split isolated GO lines, preserves positive repeat-count metadata, and rejects malformed repeat counts.
- GO inside strings, comments, and quoted/bracketed identifiers is ignored as a separator.
- SqlValue literal formatting and basic equality are tested.
- TableModel row ID allocation, foreign-key column-count validation, and optional column type metadata are tested.
- SqlTypeSpec validates parameter ranges for DECIMAL/NUMERIC, FLOAT, CHAR/VARCHAR, NCHAR/NVARCHAR, BINARY/VARBINARY, TIME, DATETIME2, and DATETIMEOFFSET.
- SqlTypeSystem tests integer boundaries, exact decimal rounding/overflow, MONEY/SMALLMONEY bounds, FLOAT/REAL finite values, BIT conversion, string length/code-page behavior, Unicode UTF-16 length, binary hex conversion/padding, date ranges, temporal rounding, GUID validation, and rejection of direct ROWVERSION assignment.
- SqlTruthValue tests the full NOT/AND/OR three-valued truth tables and the TRUE-only WHERE filter rule.
- SqlCollation tests case/accent profile behavior and the documented Arabic combining-mark subset.

**Important:** These are component-level foundations. They do not indicate that a complete T-SQL lexer/parser, SQL Server collation engine, CREATE/ALTER/DROP, INSERT/SELECT/UPDATE/DELETE, constraints, transactions, or persisted student database is implemented.



### Phase 3 lexer and batch tests

- Keyword and identifier classification, including Arabic identifiers and variables.
- Escaped bracketed identifiers, quoted identifiers, Unicode string literals, numeric/exponent literals, and hexadecimal binary literals.
- Line and nested block comments, including comment omission mode.
- Source offset/line/column accuracy across CRLF and multiline strings.
- Stable diagnostics for unterminated strings/identifiers/comments, malformed exponents/binary literals, and invalid characters.
- Lexer-aware GO separation, repeat-count metadata, malformed repeat-count rejection, trailing multi-line block-comment rejection, and GO text inside non-code lexical constructs.
- CRLF preservation in decoded multiline literals, trailing-dot decimal tokens, and comment-aware separator handling.

The lexer is a documented subset. It does not parse SQL statements or make them executable.

### Phase 3 acceptance evidence

Accepted on code commit `c7b02a2e63077ab9dc5f8773c0aed294b42de3d4`:

- Flutter analysis passed.
- All 83 unit/widget test cases passed.
- Android debug APK build passed.
- Android release APK build passed.
- GitHub Actions uploaded `sql-student-studio-release-apk`.
- Verification workflow: https://github.com/mbkh87vchcjm-bit/University/actions/runs/41691620736
- Flutter CI workflow: https://github.com/mbkh87vchcjm-bit/University/actions/runs/41691620691

The APK is a release build of the educational shell and isolated lexer/type foundations. It does not expose executable SQL statements because the parser, semantic binder, database catalog, and query executor are later phases.

## 3. Required CI quality gates

Every phase revision must pass:

- flutter pub get
- dart format . (CI normalizes Dart source in its checkout before analysis, tests, and APK builds.)
- flutter analyze
- flutter test
- flutter build apk --debug
- flutter build apk --release
- APK upload artifact sql-student-studio-release-apk

A green analyzer alone is not a successful phase. Both test workflows and the APK build workflow must pass on the current branch head.

## 4. Phase 2 acceptance evidence

The Phase 2 branch acceptance run completed on commit `532da4358e5ceb3222dca70951f93d5124790010`:

- Flutter static analysis passed.
- All 65 reported unit/widget test cases passed.
- Android debug APK build passed.
- Android release APK build passed.
- Release artifact `sql-student-studio-release-apk` was uploaded by GitHub Actions.

Phase 2 regression coverage includes numeric precedence, strict ISO calendar/time rejection, DATE minimum/maximum boundaries, DATE/TIME/DATETIME rounding and limits, Unicode/code-page behavior, binary conversion, GUID validation, NULL truth tables, and the documented collation subset.

This acceptance applies only to isolated semantic components. It does not claim that SQL statements are parsed or executed, or that student database catalogs and rows are persisted.

## 5. Phase 1 acceptance checks

- New install initializes workspace metadata correctly.
- An existing v1 workspace migrates to v2 without losing projects.
- Create, list, open, delete, and last-opened restoration work.
- Theme preference (system/light/dark) survives database reopen.
- No UI action falsely implies that a SQL database or query engine has been implemented.
- Student-visible storage errors are actionable and do not expose internal exception details.
- Android package identity and app label use SQL Student Studio.
- No unrelated coursework, medical logo, or previous product identity remains in the active app identity.


## 6. Phase 4 parser tests and acceptance evidence

The parser suite covers:

- Multiple statements, original script source offsets/line numbers, and GO batch number propagation.
- CREATE/DROP DATABASE, USE, CREATE/DROP TABLE, parameterized types, NULL/NOT NULL, IDENTITY, inline keys, and named table PRIMARY KEY/UNIQUE/FOREIGN KEY REFERENCES syntax.
- INSERT with optional column lists, multiple VALUES rows, and decoded Arabic Unicode strings.
- UPDATE assignments and DELETE predicates.
- SELECT DISTINCT/TOP, projection aliases, qualified FROM, table aliases, INNER/LEFT/RIGHT/FULL/CROSS JOIN, ON predicates, WHERE, GROUP BY, HAVING, and ORDER BY.
- Arithmetic/boolean precedence, parentheses, NOT binding, IS [NOT] NULL, IN/NOT IN, BETWEEN/NOT BETWEEN, wildcard selection, and function-call syntax including reserved-word function names.
- BEGIN/COMMIT/ROLLBACK/SAVE transaction syntax.
- Negative syntax cases for malformed JOIN, UPDATE, expressions, column lists, unsupported statements, and three-part object names.

Acceptance on code commit 56184dfdd93184f6c328f5ed4ec6afbd1bab1b4c:
- Flutter analysis passed; 103 automated tests passed.
- Android analysis and tests passed.
- Android Debug APK and Release APK builds passed.
- Release artifact sql-student-studio-release-apk uploaded (artifact ID 13323482339).
- Flutter workflow: https://github.com/mbkh87vchcjm-bit/University/actions/runs/41833071408
- Android workflow: https://github.com/mbkh87vchcjm-bit/University/actions/runs/41833071402

These results establish parser syntax behavior only. They do not prove object-name binding, type/constraint validation, catalog updates, transaction behavior, or SQL execution.
