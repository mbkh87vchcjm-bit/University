# Development Roadmap

## Phase 0 — Analysis & Specification (Completed)
- [x] Architecture design & separation of Android UI vs SQL Engine.
- [x] Specification of T-SQL subset matrix.
- [x] Database model & metadata entity definitions.
- [x] UI/UX specification for mobile SSMS layout.

## Phase 1 — MVP Core Development (Current Milestone)
- [ ] Android Kotlin + Jetpack Compose project structure setup.
- [ ] Base UI screens: Home, Database Explorer, Query Editor, Results/Messages.
- [ ] Room Database metadata configuration.
- [ ] `sqlengine` Lexer & Parser implementation (`CREATE DB`, `CREATE TABLE`, `INSERT`, `SELECT`, `UPDATE`, `DELETE`, `WHERE`).
- [ ] Batch execution (`GO` support).
- [ ] Monospace SQL Editor with basic syntax highlighting.
- [ ] Offline local execution engine.

## Phase 2 — Intermediate Features (v1.5)
- [ ] `JOIN` support (`INNER JOIN`, `LEFT JOIN`).
- [ ] `GROUP BY`, `HAVING`, and aggregate functions (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`).
- [ ] Schema-aware IntelliSense Autocomplete.
- [ ] Table Designer GUI.
- [ ] ER Diagram viewer.
- [ ] File Manager & CSV/JSON Export.

## Phase 3 — Advanced Features (v2.0)
- [ ] Views support (`CREATE VIEW`).
- [ ] Project Export / Backup ZIP & Restore.
- [ ] Interactive Practice / Tutorial Mode with automatic query verification.
- [ ] Offline AI Error Explanation Assistant.
