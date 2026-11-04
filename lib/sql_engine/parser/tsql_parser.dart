import '../ast/sql_ast.dart';
import '../errors/sql_error.dart';
import '../lexer/sql_lexer.dart';
import '../lexer/sql_token.dart';

/// Recursive-descent statement parser with a Pratt expression parser.
/// Syntax only: this component never accesses storage or executes SQL.
class TsqlParser {
  final List<SqlToken> _tokens;
  int _current = 0;

  TsqlParser(String source)
      : _tokens = SqlLexer(includeComments: false).tokenize(source);

  List<SqlStatement> parse() {
    final statements = <SqlStatement>[];
    while (!_isAtEnd) {
      while (_matchPunctuation(';')) {}
      if (_isAtEnd) break;
      statements.add(_parseStatement());
      if (_matchPunctuation(';')) {
        while (_matchPunctuation(';')) {}
      } else if (!_isAtEnd) {
        _fail('Expected a semicolon or the end of the batch.');
      }
    }
    return List.unmodifiable(statements);
  }

  SqlStatement _parseStatement() {
    if (_matchKeyword('CREATE')) {
      final start = _previous;
      if (_matchKeyword('DATABASE')) {
        final name = _consumeIdentifier('database name');
        return CreateDatabaseStatement(name.value, span: _spanFrom(start));
      }
      if (_matchKeyword('TABLE')) return _parseCreateTable(start);
      _fail('Expected DATABASE or TABLE after CREATE.');
    }
    if (_matchKeyword('DROP')) {
      final start = _previous;
      if (_matchKeyword('DATABASE')) {
        final name = _consumeIdentifier('database name');
        return DropDatabaseStatement(name.value, span: _spanFrom(start));
      }
      if (_matchKeyword('TABLE')) {
        return DropTableStatement(_parseTableName(), span: _spanFrom(start));
      }
      _fail('Expected DATABASE or TABLE after DROP.');
    }
    if (_matchKeyword('USE')) {
      final start = _previous;
      final name = _consumeIdentifier('database name');
      return UseDatabaseStatement(name.value, span: _spanFrom(start));
    }
    if (_matchKeyword('INSERT')) return _parseInsert(_previous);
    if (_matchKeyword('SELECT')) return _parseSelect(_previous);
    _fail('Statement is not supported by this parser phase.');
  }

  CreateTableStatement _parseCreateTable(SqlToken start) {
    final table = _parseTableName();
    _consumePunctuation('(', 'Expected "(" before the table column list.');
    final columns = <SqlColumnDefinition>[];
    do {
      final columnStart = _peek;
      final name = _consumeIdentifier('column name');
      final type = _consumeTypeName();
      final arguments = <String>[];
      if (_matchPunctuation('(')) {
        do {
          final parameter = _peek;
          if (parameter.kind == SqlTokenKind.integerLiteral ||
              parameter.kind == SqlTokenKind.identifier ||
              parameter.kind == SqlTokenKind.keyword) {
            arguments.add(_advance().lexeme.toUpperCase());
          } else {
            _fail('Expected a type parameter such as a number or MAX.');
          }
        } while (_matchPunctuation(','));
        _consumePunctuation(')', 'Expected ")" after type parameters.');
      }

      var nullable = true;
      var identity = false;
      var primaryKey = false;
      var readingModifiers = true;
      while (readingModifiers) {
        if (_matchKeyword('NOT')) {
          _consumeKeyword('NULL', 'Expected NULL after NOT.');
          nullable = false;
        } else if (_matchKeyword('NULL')) {
          nullable = true;
        } else if (_matchKeyword('IDENTITY')) {
          identity = true;
          if (_matchPunctuation('(')) {
            _consumeIntegerLiteral('IDENTITY seed');
            _consumePunctuation(',', 'Expected comma between IDENTITY seed and increment.');
            _consumeIntegerLiteral('IDENTITY increment');
            _consumePunctuation(')', 'Expected ")" after IDENTITY arguments.');
          }
        } else if (_matchKeyword('PRIMARY')) {
          _consumeKeyword('KEY', 'Expected KEY after PRIMARY.');
          primaryKey = true;
          nullable = false;
        } else {
          readingModifiers = false;
        }
      }
      columns.add(SqlColumnDefinition(
        name: name.value,
        typeName: type,
        typeArguments: List.unmodifiable(arguments),
        isNullable: nullable,
        isIdentity: identity,
        isPrimaryKey: primaryKey,
        span: _spanFrom(columnStart),
      ));
    } while (_matchPunctuation(','));
    _consumePunctuation(')', 'Expected ")" after the table column list.');
    return CreateTableStatement(
      table: table,
      columns: List.unmodifiable(columns),
      span: _spanFrom(start),
    );
  }

  InsertStatement _parseInsert(SqlToken start) {
    _matchKeyword('INTO');
    final table = _parseTableName();
    final columns = <String>[];
    if (_matchPunctuation('(')) {
      do {
        columns.add(_consumeIdentifier('insert column name').value);
      } while (_matchPunctuation(','));
      _consumePunctuation(')', 'Expected ")" after INSERT column names.');
    }
    _consumeKeyword('VALUES', 'Expected VALUES in this INSERT form.');
    final rows = <List<SqlExpression>>[];
    do {
      _consumePunctuation('(', 'Expected "(" before a VALUES row.');
      final row = <SqlExpression>[];
      if (!_checkPunctuation(')')) {
        do {
          row.add(_parseExpression());
        } while (_matchPunctuation(','));
      }
      _consumePunctuation(')', 'Expected ")" after a VALUES row.');
      if (row.isEmpty) _fail('A VALUES row cannot be empty.');
      rows.add(List.unmodifiable(row));
    } while (_matchPunctuation(','));
    return InsertStatement(
      table: table,
      columns: List.unmodifiable(columns),
      valueRows: List.unmodifiable(rows),
      span: _spanFrom(start),
    );
  }

  SelectStatement _parseSelect(SqlToken start) {
    final distinct = _matchKeyword('DISTINCT');
    int? top;
    if (_matchKeyword('TOP')) {
      _consumePunctuation('(', 'Expected "(" after TOP in this parser subset.');
      top = _consumeIntegerLiteral('TOP row count');
      _consumePunctuation(')', 'Expected ")" after TOP row count.');
      if (top < 0) _fail('TOP row count cannot be negative.');
    }

    final items = <SqlSelectItem>[];
    do {
      final itemStart = _peek;
      final expression = _parseExpression();
      String? alias;
      if (_matchKeyword('AS')) alias = _consumeIdentifier('SELECT alias').value;
      items.add(SqlSelectItem(
        expression: expression,
        alias: alias,
        span: _spanFrom(itemStart),
      ));
    } while (_matchPunctuation(','));

    SqlTableName? from;
    if (_matchKeyword('FROM')) {
      from = _parseTableName();
      String? alias;
      if (_matchKeyword('AS')) alias = _consumeIdentifier('table alias').value;
      if (alias != null) {
        from = SqlTableName(
          schema: from.schema,
          name: from.name,
          alias: alias,
          span: from.span,
        );
      }
    }

    SqlExpression? where;
    if (_matchKeyword('WHERE')) where = _parseExpression();

    final orderBy = <SqlOrderByItem>[];
    if (_matchKeyword('ORDER')) {
      _consumeKeyword('BY', 'Expected BY after ORDER.');
      do {
        final itemStart = _peek;
        final expression = _parseExpression();
        final ascending = !_matchKeyword('DESC');
        if (ascending) _matchKeyword('ASC');
        orderBy.add(SqlOrderByItem(
          expression: expression,
          ascending: ascending,
          span: _spanFrom(itemStart),
        ));
      } while (_matchPunctuation(','));
    }

    return SelectStatement(
      distinct: distinct,
      top: top,
      items: List.unmodifiable(items),
      from: from,
      where: where,
      orderBy: List.unmodifiable(orderBy),
      span: _spanFrom(start),
    );
  }

  SqlTableName _parseTableName() {
    final start = _peek;
    final first = _consumeIdentifier('table name');
    String? schema;
    var name = first.value;
    if (_matchPunctuation('.')) {
      schema = first.value;
      name = _consumeIdentifier('table name after schema qualifier').value;
      if (_matchPunctuation('.')) {
        _fail('Three-part database.schema.table names are not supported yet.');
      }
    }
    return SqlTableName(schema: schema, name: name, span: _spanFrom(start));
  }

  String _consumeTypeName() {
    final token = _peek;
    if (token.kind != SqlTokenKind.keyword &&
        token.kind != SqlTokenKind.identifier &&
        token.kind != SqlTokenKind.bracketedIdentifier) {
      _fail('Expected a SQL data type name.');
    }
    _advance();
    return token.value.toUpperCase();
  }

  int _consumeIntegerLiteral(String description) {
    final token = _peek;
    if (token.kind != SqlTokenKind.integerLiteral) {
      _fail('Expected an integer for $description.');
    }
    _advance();
    final value = int.tryParse(token.lexeme);
    if (value == null) _fail('Invalid integer for $description.');
    return value;
  }

  SqlExpression _parseExpression([int minimumPrecedence = 1]) {
    final start = _peek;
    var left = _parsePrefix();
    while (!_isAtEnd) {
      if (_checkKeyword('IS')) {
        const precedence = 3;
        if (precedence < minimumPrecedence) break;
        _advance();
        final negated = _matchKeyword('NOT');
        _consumeKeyword('NULL', 'Expected NULL after IS or IS NOT.');
        left = SqlIsNullExpression(left, negated: negated, span: _spanFrom(start));
        continue;
      }

      var negatedPredicate = false;
      if (_checkKeyword('NOT') &&
          (_checkKeywordAt(1, 'IN') || _checkKeywordAt(1, 'LIKE'))) {
        if (3 < minimumPrecedence) break;
        _advance();
        negatedPredicate = true;
      }
      if (_checkKeyword('IN') || _checkKeyword('LIKE')) {
        final predicate = _advance().lexeme.toUpperCase();
        if (predicate == 'IN') {
          _consumePunctuation('(', 'Expected "(" after IN.');
          final values = <SqlExpression>[];
          if (_checkPunctuation(')')) _fail('IN requires at least one expression.');
          do {
            values.add(_parseExpression());
          } while (_matchPunctuation(','));
          _consumePunctuation(')', 'Expected ")" after IN values.');
          left = SqlInExpression(
            left,
            List.unmodifiable(values),
            negated: negatedPredicate,
            span: _spanFrom(start),
          );
        } else {
          final right = _parseExpression(4);
          left = SqlBinaryExpression(
            operator: negatedPredicate ? 'NOT LIKE' : 'LIKE',
            left: left,
            right: right,
            span: _spanFrom(start),
          );
        }
        continue;
      } else if (negatedPredicate) {
        _current--;
      }

      final operator = _binaryOperator(_peek);
      if (operator == null) break;
      final precedence = _precedence(operator);
      if (precedence < minimumPrecedence) break;
      _advance();
      final right = _parseExpression(precedence + 1);
      left = SqlBinaryExpression(
        operator: operator,
        left: left,
        right: right,
        span: _spanFrom(start),
      );
    }
    return left;
  }

  SqlExpression _parsePrefix() {
    final token = _peek;
    if (token.kind == SqlTokenKind.integerLiteral ||
        token.kind == SqlTokenKind.decimalLiteral ||
        token.kind == SqlTokenKind.approximateNumericLiteral ||
        token.kind == SqlTokenKind.binaryLiteral) {
      _advance();
      final kind = switch (token.kind) {
        SqlTokenKind.integerLiteral => SqlLiteralKind.integer,
        SqlTokenKind.decimalLiteral => SqlLiteralKind.decimal,
        SqlTokenKind.approximateNumericLiteral => SqlLiteralKind.approximateNumeric,
        _ => SqlLiteralKind.binary,
      };
      return SqlLiteralExpression(
        kind: kind,
        raw: token.lexeme,
        value: kind == SqlLiteralKind.binary ? token.value : token.lexeme,
        span: _spanFrom(token),
      );
    }
    if (token.kind == SqlTokenKind.stringLiteral ||
        token.kind == SqlTokenKind.unicodeStringLiteral) {
      _advance();
      final unicode = token.kind == SqlTokenKind.unicodeStringLiteral;
      return SqlLiteralExpression(
        kind: unicode ? SqlLiteralKind.unicodeString : SqlLiteralKind.string,
        raw: token.lexeme,
        value: token.value,
        span: _spanFrom(token),
      );
    }
    if (_matchKeyword('NULL')) {
      return SqlLiteralExpression(
        kind: SqlLiteralKind.nullValue,
        raw: _previous.lexeme,
        span: _spanFrom(_previous),
      );
    }
    if (token.kind == SqlTokenKind.variable) {
      _advance();
      return SqlVariableExpression(token.value, span: _spanFrom(token));
    }
    if (_matchOperator('*')) {
      return SqlWildcardExpression(span: _spanFrom(_previous));
    }
    if (_matchPunctuation('(')) {
      final start = _previous;
      final expression = _parseExpression();
      _consumePunctuation(')', 'Expected ")" after expression.');
      return SqlParenthesizedExpression(expression, span: _spanFrom(start));
    }
    if (_checkOperator('+') || _checkOperator('-') || _checkKeyword('NOT')) {
      final operator = _advance();
      final operand = _parseExpression(operator.lexeme.toUpperCase() == 'NOT' ? 3 : 6);
      return SqlUnaryExpression(
        operator.lexeme.toUpperCase(),
        operand,
        span: _spanFrom(operator),
      );
    }
    if (_isIdentifierToken(token)) {
      final start = token;
      final parts = <String>[_advance().value];
      while (_matchPunctuation('.')) {
        parts.add(_consumeIdentifier('qualified name part').value);
      }
      if (parts.length == 1 && _matchPunctuation('(')) {
        final arguments = <SqlExpression>[];
        var starArgument = false;
        if (_matchOperator('*')) {
          starArgument = true;
          _consumePunctuation(')', 'Expected ")" after function star argument.');
        } else if (!_matchPunctuation(')')) {
          do {
            arguments.add(_parseExpression());
          } while (_matchPunctuation(','));
          _consumePunctuation(')', 'Expected ")" after function arguments.');
        }
        return SqlFunctionCallExpression(
          parts.single,
          List.unmodifiable(arguments),
          starArgument: starArgument,
          span: _spanFrom(start),
        );
      }
      return SqlIdentifierExpression(
        List.unmodifiable(parts),
        span: _spanFrom(start),
      );
    }
    _fail('Expected a literal, identifier, function call, or parenthesized expression.');
  }

  String? _binaryOperator(SqlToken token) {
    if (token.kind == SqlTokenKind.operator) {
      final value = token.lexeme;
      if (const {'=', '!=', '<>', '<', '>', '<=', '>='}.contains(value)) return value;
      if (const {'+', '-', '*', '/', '%'}.contains(value)) return value;
    }
    if (token.kind == SqlTokenKind.keyword) {
      final value = token.lexeme.toUpperCase();
      if (value == 'AND' || value == 'OR') return value;
    }
    return null;
  }

  int _precedence(String operator) {
    switch (operator) {
      case 'OR': return 1;
      case 'AND': return 2;
      case '=':
      case '!=':
      case '<>':
      case '<':
      case '>':
      case '<=':
      case '>=': return 3;
      case '+':
      case '-': return 4;
      case '*':
      case '/':
      case '%': return 5;
      default: return 0;
    }
  }

  bool _isIdentifierToken(SqlToken token) =>
      token.kind == SqlTokenKind.identifier ||
      token.kind == SqlTokenKind.bracketedIdentifier ||
      token.kind == SqlTokenKind.quotedIdentifier;

  bool _matchKeyword(String keyword) {
    if (!_checkKeyword(keyword)) return false;
    _advance();
    return true;
  }

  bool _checkKeyword(String keyword) =>
      !_isAtEnd &&
      _peek.kind == SqlTokenKind.keyword &&
      _peek.lexeme.toUpperCase() == keyword;

  bool _checkKeywordAt(int distance, String keyword) {
    final position = _current + distance;
    if (position >= _tokens.length) return false;
    final token = _tokens[position];
    return token.kind == SqlTokenKind.keyword &&
        token.lexeme.toUpperCase() == keyword;
  }

  void _consumeKeyword(String keyword, String message) {
    if (!_matchKeyword(keyword)) _fail(message);
  }

  bool _matchPunctuation(String punctuation) {
    if (!_checkPunctuation(punctuation)) return false;
    _advance();
    return true;
  }

  bool _checkPunctuation(String punctuation) =>
      !_isAtEnd &&
      _peek.kind == SqlTokenKind.punctuation &&
      _peek.lexeme == punctuation;

  void _consumePunctuation(String punctuation, String message) {
    if (!_matchPunctuation(punctuation)) _fail(message);
  }

  bool _matchOperator(String operator) {
    if (!_checkOperator(operator)) return false;
    _advance();
    return true;
  }

  bool _checkOperator(String operator) =>
      !_isAtEnd &&
      _peek.kind == SqlTokenKind.operator &&
      _peek.lexeme == operator;

  SqlToken _consumeIdentifier(String description) {
    if (!_isIdentifierToken(_peek)) _fail('Expected $description.');
    return _advance();
  }

  SqlToken get _peek => _tokens[_current];
  SqlToken get _previous => _tokens[_current - 1];
  bool get _isAtEnd => _peek.kind == SqlTokenKind.eof;

  SqlToken _advance() {
    if (!_isAtEnd) _current++;
    return _previous;
  }

  SqlSourceSpan _spanFrom(SqlToken start) {
    final end = _current == 0 ? start : _previous;
    return SqlSourceSpan(
      startOffset: start.startOffset,
      endOffset: end.endOffset,
      startLine: start.startLine,
      startColumn: start.startColumn,
      endLine: end.endLine,
      endColumn: end.endColumn,
      batchNumber: start.batchNumber,
    );
  }

  Never _fail(String message) {
    final token = _peek;
    final near = token.kind == SqlTokenKind.eof ? 'end of input' : "'${token.lexeme}'";
    throw SqlError(
      code: 'SSS-PARSE-SYNTAX',
      category: ErrorCategory.parserError,
      message: '$message Found $near.',
      line: token.startLine,
      column: token.startColumn,
    );
  }
}
