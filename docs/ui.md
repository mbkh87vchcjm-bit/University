# UI Design & Components Specification

## Overview
The user interface is built with **Jetpack Compose**, targeting a desktop SSMS-like experience optimized for Android smartphones and tablets.

## Key Screens & Features

### 1. Home Screen (`ui/home`)
- **New Project Button**: Create a new database sandbox.
- **Recent Projects List**: Quick access to recent projects (e.g., University DB, Sales System).
- **Recent Queries List**: Quickly reopen recently executed scripts.

### 2. Database Explorer (`ui/explorer`)
- Tree View representation of student databases:
  ```
  📁 University
     ├── 📁 Tables
     │    ├── dbo.Students
     │    ├── dbo.Doctors
     │    └── dbo.Courses
     ├── 📁 Views
     └── 📁 Database Diagrams
  ```
- **Context Actions (Long Press/Click)**: View Data, Design Table, Script Table as CREATE, Rename, Delete.

### 3. Query Editor Screen (`ui/editor`)
- **Query Tabs**: Multiple open script files/tabbed queries.
- **Syntax Highlighting**: Keywords (`SELECT`, `FROM`, `WHERE`), strings, numbers, and comments in SSMS-inspired dark/light theme colors.
- **IntelliSense Autocomplete**: Real-time schema suggestions for database names, table names, and column names.
- **Monospace Font**: JetBrains Mono or system monospace font for LTR SQL code editing.
- **Toolbar**:
  - `▶ Execute`: Run all or execute highlighted selection.
  - `Format`: Auto-format SQL code.
  - `Save`: Save script to local file storage.

### 4. Results & Messages Grid (`ui/results`)
- **Results Tab**: Scrollable data grid showing result rows with sorting, search, and CSV/JSON export buttons.
- **Messages Tab**: Execution logs, affected rows count (`(2 rows affected)`), execution time in ms, or line/column error details.

### 5. Table Designer (`ui/designer`)
- GUI grid allowing visual creation of tables without writing raw SQL.
- Automatically generates equivalent `CREATE TABLE` T-SQL DDL script.

### 6. ER Diagram Viewer (`ui/diagram`)
- Visual graph rendering table relationships (Primary Keys and Foreign Keys).
