/// Immutable syntax-tree model for the supported T-SQL teaching subset.
/// The AST describes syntax only; it does not resolve names or execute SQL.
abstract class SqlAstNode {
  final SqlSourceSpan? span;
  const SqlAstNode({this.span});
}

class SqlSourceSpan {
  final int startOffset;
  final int endOffset;
  final int startLine;
  final int startColumn;
  final int endLine;
  final int endColumn;
  final int batchNumber;

  const SqlSourceSpan({
    required this.startOffset,
    required this.endOffset,
    required this.startLine,
    required this.startColumn,
    required this.endLine,
    required this.endColumn,
    required this.batchNumber,
  });
}

sealed class SqlStatement extends SqlAstNode {
  const SqlStatement({super.span});
}

class CreateDatabaseStatement extends SqlStatement {
  final String databaseName;
  const CreateDatabaseStatement(this.databaseName, {super.span});
}

class DropDatabaseStatement extends SqlStatement {
  final String databaseName;
  const DropDatabaseStatement(this.databaseName, {super.span});
}

class UseDatabaseStatement extends SqlStatement {
  final String databaseName;
  const UseDatabaseStatement(this.databaseName, {super.span});
}

class SqlTableName extends SqlAstNode {
  final String? schema;
  final String name;
  final String? alias;

  const SqlTableName({
    this.schema,
    required this.name,
    this.alias,
    super.span,
  });
}

class SqlColumnDefinition extends SqlAstNode {
  final String name;
  final String typeName;
  final List<String> typeArguments;
  final bool isNullable;
  final bool isIdentity;
  final bool isPrimaryKey;
  final bool isUnique;

  const SqlColumnDefinition({
    required this.name,
    required this.typeName,
    this.typeArguments = const [],
    this.isNullable = true,
    this.isIdentity = false,
    this.isPrimaryKey = false,
    this.isUnique = false,
    super.span,
  });
}

class CreateTableStatement extends SqlStatement {
  final SqlTableName table;
  final List<SqlColumnDefinition> columns;
  final List<SqlTableConstraint> constraints;

  const CreateTableStatement({
    required this.table,
    required this.columns,
    this.constraints = const [],
    super.span,
  });
}

class DropTableStatement extends SqlStatement {
  final SqlTableName table;
  const DropTableStatement(this.table, {super.span});
}

class InsertStatement extends SqlStatement {
  final SqlTableName table;
  final List<String> columns;
  final List<List<SqlExpression>> valueRows;

  const InsertStatement({
    required this.table,
    this.columns = const [],
    required this.valueRows,
    super.span,
  });
}

class SelectStatement extends SqlStatement {
  final bool distinct;
  final int? top;
  final List<SqlSelectItem> items;
  final SqlTableName? from;
  final List<SqlJoinClause> joins;
  final SqlExpression? where;
  final List<SqlExpression> groupBy;
  final SqlExpression? having;
  final List<SqlOrderByItem> orderBy;

  const SelectStatement({
    this.distinct = false,
    this.top,
    required this.items,
    this.from,
    this.joins = const [],
    this.where,
    this.groupBy = const [],
    this.having,
    this.orderBy = const [],
    super.span,
  });
}

class SqlSelectItem extends SqlAstNode {
  final SqlExpression expression;
  final String? alias;
  const SqlSelectItem({required this.expression, this.alias, super.span});
}

class SqlOrderByItem extends SqlAstNode {
  final SqlExpression expression;
  final bool ascending;
  const SqlOrderByItem({
    required this.expression,
    this.ascending = true,
    super.span,
  });
}

sealed class SqlExpression extends SqlAstNode {
  const SqlExpression({super.span});
}

enum SqlLiteralKind {
  nullValue,
  integer,
  decimal,
  approximateNumeric,
  binary,
  string,
  unicodeString,
}

class SqlLiteralExpression extends SqlExpression {
  final SqlLiteralKind kind;
  final String raw;
  final Object? value;

  const SqlLiteralExpression({
    required this.kind,
    required this.raw,
    this.value,
    super.span,
  });
}

class SqlIdentifierExpression extends SqlExpression {
  final List<String> parts;
  const SqlIdentifierExpression(this.parts, {super.span});
}

class SqlVariableExpression extends SqlExpression {
  final String name;
  const SqlVariableExpression(this.name, {super.span});
}

class SqlWildcardExpression extends SqlExpression {
  const SqlWildcardExpression({super.span});
}

class SqlParenthesizedExpression extends SqlExpression {
  final SqlExpression expression;
  const SqlParenthesizedExpression(this.expression, {super.span});
}

class SqlUnaryExpression extends SqlExpression {
  final String operator;
  final SqlExpression operand;
  const SqlUnaryExpression(this.operator, this.operand, {super.span});
}

class SqlBinaryExpression extends SqlExpression {
  final String operator;
  final SqlExpression left;
  final SqlExpression right;
  const SqlBinaryExpression({
    required this.operator,
    required this.left,
    required this.right,
    super.span,
  });
}

class SqlIsNullExpression extends SqlExpression {
  final SqlExpression expression;
  final bool negated;
  const SqlIsNullExpression(
    this.expression, {
    this.negated = false,
    super.span,
  });
}

class SqlInExpression extends SqlExpression {
  final SqlExpression expression;
  final List<SqlExpression> values;
  final bool negated;
  const SqlInExpression(
    this.expression,
    this.values, {
    this.negated = false,
    super.span,
  });
}

class SqlFunctionCallExpression extends SqlExpression {
  final String name;
  final List<SqlExpression> arguments;
  final bool starArgument;
  const SqlFunctionCallExpression(
    this.name,
    this.arguments, {
    this.starArgument = false,
    super.span,
  });
}

enum SqlTableConstraintKind { primaryKey, unique, foreignKey }

class SqlTableConstraint extends SqlAstNode {
  final String? name;
  final SqlTableConstraintKind kind;
  final List<String> columns;
  final SqlTableName? referencedTable;
  final List<String> referencedColumns;

  const SqlTableConstraint({
    this.name,
    required this.kind,
    required this.columns,
    this.referencedTable,
    this.referencedColumns = const [],
    super.span,
  });
}

enum SqlJoinType { inner, left, right, full, cross }

class SqlJoinClause extends SqlAstNode {
  final SqlJoinType type;
  final SqlTableName table;
  final SqlExpression? condition;

  const SqlJoinClause({
    required this.type,
    required this.table,
    this.condition,
    super.span,
  });
}

class SqlAssignment extends SqlAstNode {
  final String column;
  final SqlExpression expression;

  const SqlAssignment({
    required this.column,
    required this.expression,
    super.span,
  });
}

class UpdateStatement extends SqlStatement {
  final SqlTableName table;
  final List<SqlAssignment> assignments;
  final SqlExpression? where;

  const UpdateStatement({
    required this.table,
    required this.assignments,
    this.where,
    super.span,
  });
}

class DeleteStatement extends SqlStatement {
  final SqlTableName table;
  final SqlExpression? where;

  const DeleteStatement({
    required this.table,
    this.where,
    super.span,
  });
}

enum SqlTransactionKind { begin, commit, rollback, save }

class SqlTransactionStatement extends SqlStatement {
  final SqlTransactionKind kind;
  final String? savepointName;

  const SqlTransactionStatement({
    required this.kind,
    this.savepointName,
    super.span,
  });
}

class SqlBetweenExpression extends SqlExpression {
  final SqlExpression expression;
  final SqlExpression lower;
  final SqlExpression upper;
  final bool negated;

  const SqlBetweenExpression({
    required this.expression,
    required this.lower,
    required this.upper,
    this.negated = false,
    super.span,
  });
}
