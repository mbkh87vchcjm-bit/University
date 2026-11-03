# SQL Student Studio — Mobile Interface Specification

## Current Phase 1 UI Status

The app shell now exposes five Arabic-first destinations:

1. **Home:** local workspace projects, active project, create/open/delete actions, and honest empty/error/loading states.
2. **Databases:** reserved for the database catalog and Object Explorer (Phase 6).
3. **Query:** reserved for the T-SQL editor and result workspace (Phase 7).
4. **Learn:** reserved for structured Arabic lessons and exercises (Phase 15).
5. **More:** shows the compatibility profile, active workspace, and offline/simulator disclosures.

The home screen's project metadata is persisted in a dedicated SQLite application database. It is not the student SQL database. No placeholder database or query results are shown as if they were real.

## Navigation and Mobile UX

- Material 3 NavigationBar with five persistent destinations.
- RTL is used for Arabic application navigation and explanations.
- SQL source editors must use LTR text direction in the query workspace.
- Layout is scrollable and designed for narrow Android screens.
- System theme is followed by default; dark and light themes are defined.
- Destructive project deletion requires confirmation.
- The active/most recently opened workspace is restored from local metadata.
- Loading, empty, and error states must remain visible and actionable.
- No visible action may be a dead button. An unimplemented feature is shown as planned with its phase.

## Phase 1 — Workspace UI

Implemented:
- Home workspace.
- Create a project with a required name and a 60-character limit.
- List saved projects.
- Open a project and update its last-opened timestamp.
- Delete a project only after confirmation.
- Restore the most recently opened project when the application starts.
- Display compatibility and simulator disclosures.

Not implemented yet:
- Student database engine and Object Explorer.
- Query editor, SQL execution, result grid, and query history.
- Learning modules, lessons, assessment, and progress tracking.
- Table Designer, ERD, administration tools, export, and project backup.

## Query Workspace (Phase 7)

Planned structure:
- Context row: active project, database, compatibility profile, and unsaved status.
- SQL editor: monospace font, line numbers, syntax highlighting, selection execution, run-batch, run-all, save, and open.
- Touch keyboard row for common SQL syntax without replacing the Android keyboard.
- Results / Messages tabs, with clear execution and affected-row counts.
- SQL source is LTR; Arabic explanations and messages are RTL.

## Database Explorer (Phase 6 onward)

Planned tree:
- Databases
- Security
- Schemas
- Tables
- Views
- Programmability
- Storage

A tree node appears as functional only after the matching engine capability is implemented and tested.

## Accessibility and Reliability

- Scalable text and accessible touch targets.
- Preserve editor contents and cursor selection across navigation and rotation.
- Do not clear a student's work after a SQL error.
- Show confirmation for destructive database/table operations.
- Keep Arabic, English, and Unicode SQL values distinct in storage and rendering.
- Show clear support status and simulator limitations for advanced administration screens.
