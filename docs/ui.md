# UI Component Categorization & Mobile UX

## Overview
SQL Student Studio provides a mobile-optimized SSMS workflow using Jetpack Compose components (bottom sheets, drawer, tabbed interfaces, monospace code editor, scrollable data grids).

---

## UI Feature Categorization

### 🟢 MVP Baseline Product Scope
1. **Home Screen (`ui/home`)**
   - New Project & Open Project buttons.
   - Recent Projects list.
   - Recent Queries list.
2. **Database Explorer (`ui/explorer`)**
   - Database and Table tree view (`dbo` schema).
   - Basic context menus (View Data, Script Table, Delete).
3. **Query Editor (`ui/editor`)**
   - Single & Multi-line SQL text editor with line numbers and monospace font.
   - Basic Syntax Highlighting (Keywords, Strings, Numbers, Comments).
   - Execution controls: `▶ Execute` (Run All or Selection).
   - Basic Save/Open SQL script actions.
4. **Results & Messages (`ui/results`)**
   - Scrollable tabular result grid.
   - Execution messages (Returned rows count for `SELECT`, Affected rows count for `INSERT`/`UPDATE`/`DELETE`, execution time in ms, diagnostic error display).
5. **Projects (`ui/project`)**
   - Basic project workspace creation.

---

### 🟡 Phase 2 Features (Post-MVP)
1. **Multi-Tab Query Editor**: Browser-like tabbed interface for editing multiple scripts simultaneously.
2. **Schema-Aware IntelliSense Autocomplete**: Contextual suggestions based on active schema metadata (Tables, Columns).
3. **SQL Formatter**: Code beautifier for T-SQL syntax formatting.
4. **Visual Table Designer (`ui/designer`)**: GUI grid for table structure creation generating standard `CREATE TABLE` scripts.
5. **ER Diagram Viewer (`ui/diagram`)**: Entity Relationship graph rendering PK/FK links.
6. **Advanced File Management & CSV / JSON Export (`ui/files`)**: Advanced file manager, export results grid to CSV and JSON formats.

---

### 🔵 Phase 3 & Future Capabilities
1. **Views Support (`ui/explorer`)**: Database Explorer tree node and engine support for Views (`CREATE VIEW`).
2. **Interactive Tutorial & Practice Mode**: Self-paced SQL lessons with automated validation.
3. **Project ZIP Backup & Restore**: Full archive packaging and restoration.
4. **Optional AI Error Assistant**: Local or optional cloud helper providing human-friendly syntax guidance for execution errors.
