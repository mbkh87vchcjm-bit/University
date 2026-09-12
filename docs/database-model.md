# Engine Storage & Database Data Models

## Overview
SQL Student Studio separates application management models (stored in Room) from student database engine models (managed via `DatabaseStorage` interface).

---

## 1. Application Storage (Room Database)

Room manages application-level metadata and workspace history:

```kotlin
@Entity(tableName = "projects")
data class ProjectEntity(
    @PrimaryKey val id: String,
    val name: String,
    val description: String?,
    val createdAt: Long,
    val updatedAt: Long
)

@Entity(tableName = "script_files")
data class ScriptFileEntity(
    @PrimaryKey val id: String,
    val projectId: String,
    val fileName: String,
    val content: String,
    val updatedAt: Long
)

@Entity(tableName = "query_history")
data class QueryHistoryEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val projectId: String,
    val queryText: String,
    val executedAt: Long,
    val executionDurationMs: Long,
    val isSuccess: Boolean,
    val errorMessage: String?
)

@Entity(tableName = "app_settings")
data class AppSettingsEntity(
    @PrimaryKey val key: String,
    val value: String
)
```

---

## 2. Student Database Engine Models (`sqlengine`)

### Storage Interface Abstraction
```kotlin
interface DatabaseStorage {
    fun createDatabase(dbName: String)
    fun dropDatabase(dbName: String)
    fun getDatabase(dbName: String): DatabaseModel?
    fun createTable(dbName: String, table: TableModel)
    fun dropTable(dbName: String, schema: String, tableName: String)
    fun insertRows(dbName: String, schema: String, tableName: String, rows: List<Map<String, Any?>>)
    fun selectRows(dbName: String, schema: String, tableName: String): List<Map<String, Any?>>
    fun updateRows(dbName: String, schema: String, tableName: String, predicate: (Map<String, Any?>) -> Boolean, updates: Map<String, Any?>): Int
    fun deleteRows(dbName: String, schema: String, tableName: String, predicate: (Map<String, Any?>) -> Boolean): Int
}
```

### Hierarchy & Constraint Models
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
    val constraints: MutableList<ConstraintModel> = mutableListOf(),
    val rows: MutableList<Map<String, Any?>> = mutableListOf()
)

data class ColumnModel(
    val name: String,
    val dataType: DataType,
    val nullable: Boolean = true,
    val identity: Boolean = false,
    val defaultValue: String? = null
)

sealed interface ConstraintModel {
    val name: String?

    data class PrimaryKeyConstraint(
        override val name: String?,
        val columns: List<String>
    ) : ConstraintModel

    data class ForeignKeyConstraint(
        override val name: String?,
        val columns: List<String>,
        val referencedTable: String,
        val referencedColumns: List<String>
    ) : ConstraintModel

    data class UniqueConstraint(
        override val name: String?,
        val columns: List<String>
    ) : ConstraintModel

    data class DefaultConstraint(
        override val name: String?,
        val column: String,
        val defaultValueExpression: String
    ) : ConstraintModel

    data class CheckConstraint(
        override val name: String?,
        val expression: String
    ) : ConstraintModel
}
```
