# Database & Metadata Data Models

## Overview
SQL Student Studio uses a dual-layer data model:
1. **Application Metadata Model (Room DB)**: Stores projects, settings, script files, query history, database metadata, and ERD configurations.
2. **Student Database Engine Model**: In-memory and local SQLite representation of student databases, tables, columns, rows, and constraints.

## Room Entities (Metadata)

### 1. `ProjectEntity`
- `id`: String (UUID, Primary Key)
- `name`: String
- `createdAt`: Long (Timestamp)
- `updatedAt`: Long (Timestamp)
- `description`: String?

### 2. `ScriptFileEntity`
- `id`: String (UUID, Primary Key)
- `projectId`: String (Foreign Key to Project)
- `fileName`: String
- `content`: String (SQL code)
- `updatedAt`: Long (Timestamp)

### 3. `QueryHistoryEntity`
- `id`: Long (Auto-increment Primary Key)
- `projectId`: String
- `queryText`: String
- `executedAt`: Long
- `executionDurationMs`: Long
- `isSuccess`: Boolean
- `errorMessage`: String?

## Student Database Model (`sqlengine`)

```kotlin
data class DatabaseModel(
    val name: String,
    val schemas: MutableMap<String, SchemaModel> = mutableMapOf("dbo" to SchemaModel("dbo"))
)

data class SchemaModel(
    val name: String,
    val tables: MutableMap<String, TableModel> = mutableMapOf()
)

data class TableModel(
    val name: String,
    val schema: String = "dbo",
    val columns: MutableList<ColumnModel>,
    val primaryKey: List<String> = emptyList(),
    val foreignKeys: List<ForeignKeyModel> = emptyList(),
    val rows: MutableList<Map<String, Any?>> = mutableListOf()
)

data class ColumnModel(
    val name: String,
    val dataType: DataType,
    val isNullable: Boolean = true,
    val isPrimaryKey: Boolean = false,
    val isIdentity: Boolean = false,
    val defaultValue: String? = null
)

data class ForeignKeyModel(
    val constraintName: String,
    val columnName: String,
    val referencedTable: String,
    val referencedColumn: String
)
```
