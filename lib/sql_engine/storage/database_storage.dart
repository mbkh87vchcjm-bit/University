import '../models/table_model.dart';
import '../types/sql_value.dart';

abstract interface class DatabaseStorage {
  void createDatabase(String dbName);
  void dropDatabase(String dbName);
  DatabaseModel? getDatabase(String dbName);
  List<String> listDatabases();

  void createTable(String dbName, TableModel table);
  void dropTable(String dbName, String schema, String tableName);
  TableModel? getTable(String dbName, String schema, String tableName);
  List<String> listTables(String dbName, {String schema = 'dbo'});

  void insertRows(String dbName, String schema, String tableName, List<SqlRow> rows);
  List<StoredRow> selectStoredRows(String dbName, String schema, String tableName);
  int updateRowsByRowId(String dbName, String schema, String tableName, List<int> targetRowIds, Map<String, SqlValue> updates);
  int deleteRowsByRowId(String dbName, String schema, String tableName, List<int> targetRowIds);

  Future<void> persistState();
  Future<void> restoreState();
}
