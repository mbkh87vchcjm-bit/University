# Engine Storage & Database Data Models

## Overview
SQL Student Studio separates application metadata models (stored in Room) from student database engine models (managed via `DatabaseStorage` and `Persistent Engine Store`).

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

### Strongly-Typed Value Abstraction (`SqlValue`)
To prevent type-erasure issues with comparison, sorting, equality, aggregations, and NULL handling, all engine values strictly implement `SqlValue`:

```kotlin
sealed interface SqlValue {
    data object Null : SqlValue
    data class IntValue(val value: Int) : SqlValue
    data class LongValue(val value: Long) : SqlValue
    data class DecimalValue(val value: BigDecimal) : SqlValue
    data class DoubleValue(val value: Double) : SqlValue
    data class StringValue(val value: String) : SqlValue
    data class BooleanValue(val value: Boolean) : SqlValue
    data class DateValue(val value: LocalDate) : SqlValue
    data class DateTimeValue(val value: LocalDateTime) : SqlValue
    data class TimeValue(val value: LocalTime) : SqlValue
}

typealias Row = Map<String, SqlValue>
```

---

### Storage Interface Abstraction (`DatabaseStorage`)
`DatabaseStorage` provides clean query and raw mutation methods for the Engine.

**Crucial Architecture Requirement**: The `Executor` and `ExpressionEvaluator` components are exclusively responsible for parsing, evaluating `WHERE` clauses, evaluating predicates, and calculating update values. `DatabaseStorage` does **not** accept or execute Kotlin lambdas, predicates, or evaluation logic; it purely accepts evaluated row subsets provided directly by the Executor.

```kotlin
interface DatabaseStorage {
    fun createDatabase(dbName: String)
    fun dropDatabase(dbName: String)
    fun getDatabase(dbName: String): DatabaseModel?
    fun listDatabases(): List<String>

    fun createTable(dbName: String, table: TableModel)
    fun dropTable(dbName: String, schema: String, tableName: String)
    fun getTable(dbName: String, schema: String, tableName: String): TableModel?
    fun listTables(dbName: String, schema: String = "dbo"): List<String>

    fun insertRows(dbName: String, schema: String, tableName: String, rows: List<Row>)
    fun selectRows(dbName: String, schema: String, tableName: String): List<Row>
    fun updateRows(dbName: String, schema: String, tableName: String, targetRows: List<Row>, updates: Map<String, SqlValue>): Int
    fun deleteRows(dbName: String, schema: String, tableName: String, targetRows: List<Row>): Int

    fun persistState()
    fun restoreState()
}
```

---

### Schema, Table & Constraint Models

#### Single Source of Truth for DEFAULT Constraints
Default values are specified exclusively via `DefaultConstraint(column, expression)`. To prevent duplicate or conflicting definitions, `ColumnModel` does not contain a raw `defaultValue` string field.

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
    val rows: MutableList<Row> = mutableListOf()
)

data class ColumnModel(
    val name: String,
    val dataType: DataType,
    val nullable: Boolean = true,
    val identity: Boolean = false
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
    ) : ConstraintModel {
        init {
            require(columns.size == referencedColumns.size) {
                "Foreign Key column count must match referenced column count."
            }
        }
    }

    data class UniqueConstraint(
        override val name: String?,
        val columns: List<String>
    ) : ConstraintModel

    data class DefaultConstraint(
        override val name: String?,
        val column: String,
        val expression: Expression
    ) : ConstraintModel

    data class CheckConstraint(
        override val name: String?,
        val expression: Expression
    ) : ConstraintModel
}
```

---

## 3. Persistence Strategy for Student Database Engine
To ensure student databases survive application restarts without polluting Room:
- Student database instances, schemas, tables, constraints, and rows are stored in JSON/binary format inside the application's internal files directory (`context.filesDir/student_db/`).
- Calling `persistState()` serializes `DatabaseStorage` state to disk; calling `restoreState()` loads it back into memory upon app launch.
