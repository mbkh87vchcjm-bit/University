import 'sql_token.dart';

/// Lexer for the documented SQL Server 2014 teaching subset.
///
/// This component only turns source text into tokens. It does not parse
/// statements, bind names, or execute SQL.
class SqlLexer {
  final bool quotedIdentifiers;
  final bool includeComments;
  final int batchNumber;
  final int startOffset;
  final int startLine;
  final int startColumn;

  SqlLexer({
    this.quotedIdentifiers = true,
    this.includeComments = true,
    this.batchNumber = 1,
    this.startOffset = 0,
    this.startLine = 1,
    this.startColumn = 1,
  }) {
    if (batchNumber < 1) {
      throw ArgumentError.value(batchNumber, 'batchNumber');
    }
    if (startOffset < 0 || startLine < 1 || startColumn < 1) {
      throw ArgumentError(
        'Source positions require a non-negative offset and positive line/column values.',
      );
    }
  }

  static const Set<String> _keywords = {
    'ADD', 'ALL', 'ALTER', 'AND', 'AS', 'ASC', 'AUTHORIZATION',
    'BACKUP', 'BEGIN', 'BETWEEN', 'BREAK', 'BY',
    'CASE', 'CAST', 'CHECK', 'CLOSE', 'CLUSTERED', 'COALESCE',
    'COLUMN', 'COMMIT', 'CONSTRAINT', 'CREATE', 'CROSS', 'CURRENT',
    'CURRENT_DATE', 'CURRENT_TIMESTAMP', 'DATABASE', 'DATE', 'DAY',
    'DEALLOCATE', 'DECIMAL', 'DECLARE', 'DEFAULT', 'DELETE', 'DESC',
    'DISTINCT', 'DROP', 'ELSE', 'END', 'ESCAPE', 'EXCEPT', 'EXEC',
    'EXECUTE', 'EXISTS', 'EXTERNAL', 'FETCH', 'FLOAT', 'FOR', 'FOREIGN',
    'FROM', 'FULL', 'FUNCTION', 'GO', 'GROUP', 'HAVING', 'IDENTITY',
    'IF', 'IN', 'INDEX', 'INNER', 'INSERT', 'INT', 'INTEGER', 'INTERSECT',
    'INTO', 'IS', 'JOIN', 'KEY', 'LEFT', 'LIKE', 'NOT', 'NULL', 'NUMERIC',
    'OFFSET', 'ON', 'OR', 'ORDER', 'OUTER', 'OVER', 'PARTITION', 'PERCENT',
    'PRIMARY', 'PRINT', 'PROCEDURE', 'RAISERROR', 'READ', 'REAL',
    'REFERENCES', 'RETURN', 'RETURNS', 'RIGHT', 'ROLLBACK', 'ROWCOUNT',
    'ROW_NUMBER', 'SCHEMA', 'SELECT', 'SET', 'SMALLINT', 'SMALLMONEY',
    'SOME', 'SUM', 'TABLE', 'THEN', 'TIME', 'TIMESTAMP', 'TINYINT',
    'TOP', 'TRAN', 'TRANSACTION', 'TRIGGER', 'TRUNCATE', 'TRY_CONVERT',
    'UNION', 'UNIQUE', 'UNIQUEIDENTIFIER', 'UPDATE', 'USE', 'USER',
    'VALUES', 'VARCHAR', 'VIEW', 'WAITFOR', 'WHEN', 'WHERE', 'WHILE',
    'WITH', 'XACT_ABORT',
  };

  static const List<String> _operators = [
    '!<', '!>', '!=', '<>', '<=', '>=', '+=', '-=', '*=', '/=', '%=',
    '&=', '^=', '|=', '::', '||',
  ];

  late String _source;
  int _index = 0;
  late int _line;
  late int _column;

  List<SqlToken> tokenize(String source) {
    _source = source;
    _index = 0;
    _line = startLine;
    _column = startColumn;
    final tokens = <SqlToken>[];

    while (!_isAtEnd) {
      if (_isWhitespace(_peek())) {
        _consumeWhitespace();
        continue;
      }

      final token = _scanToken();
      if (includeComments || !token.isComment) {
        tokens.add(token);
      }
    }

    tokens.add(
      SqlToken(
        kind: SqlTokenKind.eof,
        lexeme: '',
        value: '',
        startOffset: startOffset + _index,
        endOffset: startOffset + _index,
        startLine: _line,
        startColumn: _column,
        endLine: _line,
        endColumn: _column,
        batchNumber: batchNumber,
      ),
    );
    return tokens;
  }

  bool get _isAtEnd => _index >= _source.length;

  String _peek([int distance = 0]) {
    final position = _index + distance;
    if (position >= _source.length) return '';
    return _source[position];
  }

  bool _matches(String value) {
    if (_index + value.length > _source.length) return false;
    return _source.substring(_index, _index + value.length) == value;
  }

  String _advance() {
    if (_isAtEnd) return '';
    final current = _source[_index];
    if (current == '\r') {
      _index++;
      if (_peek() == '\n') _index++;
      _line++;
      _column = 1;
      return '\n';
    }
    if (current == '\n') {
      _index++;
      _line++;
      _column = 1;
      return '\n';
    }
    _index++;
    _column++;
    return current;
  }

  void _consumeWhitespace() {
    while (!_isAtEnd && _isWhitespace(_peek())) {
      _advance();
    }
  }

  bool _isWhitespace(String value) =>
      value.isNotEmpty && RegExp(r'\s').hasMatch(value);

  bool _isDigit(String value) =>
      value.isNotEmpty && value.codeUnitAt(0) >= 48 && value.codeUnitAt(0) <= 57;

  bool _isHexDigit(String value) {
    if (value.isEmpty) return false;
    final c = value.codeUnitAt(0);
    return (c >= 48 && c <= 57) ||
        (c >= 65 && c <= 70) ||
        (c >= 97 && c <= 102);
  }

  bool _isIdentifierStart(String value) {
    if (value.isEmpty) return false;
    final c = value.codeUnitAt(0);
    if ((c >= 65 && c <= 90) ||
        (c >= 97 && c <= 122) ||
        c == 95) {
      return true;
    }
    // Common Unicode letter blocks, including Arabic and Hebrew.
    return (c >= 0x00C0 && c <= 0x02FF) ||
        (c >= 0x0370 && c <= 0x052F) ||
        (c >= 0x0590 && c <= 0x08FF) ||
        (c >= 0x0900 && c <= 0x1FFF) ||
        (c >= 0x2C00 && c <= 0xD7FF) ||
        (c >= 0xF900 && c <= 0xFAFF);
  }

  bool _isIdentifierPart(String value) {
    if (value.isEmpty) return false;
    final c = value.codeUnitAt(0);
    return _isIdentifierStart(value) ||
        _isDigit(value) ||
        c == 36 || // $
        c == 64 || // @
        c == 35 || // #
        (c >= 0x064B && c <= 0x065F); // Arabic combining marks
  }

  SqlToken _scanToken() {
    final startIndex = _index;
    final startLineValue = _line;
    final startColumnValue = _column;

    if (_matches('--')) return _scanLineComment();
    if (_matches('/*')) return _scanBlockComment();
    if (_peek() == "'") return _scanString(unicode: false);
    if (_peek().toUpperCase() == 'N' && _peek(1) == "'") {
      return _scanUnicodeString();
    }
    if (_peek() == '[') return _scanBracketedIdentifier();
    if (_peek() == '"') return _scanQuotedIdentifier();
    if (_peek() == '@' || _peek() == '#') return _scanPrefixedIdentifier();
    if (_peek() == '0' && (_peek(1) == 'x' || _peek(1) == 'X')) {
      return _scanBinaryLiteral();
    }
    if (_isDigit(_peek()) || (_peek() == '.' && _isDigit(_peek(1)))) {
      return _scanNumber();
    }
    if (_isIdentifierStart(_peek())) return _scanWord();

    for (final op in _operators) {
      if (_matches(op)) {
        for (var i = 0; i < op.length; i++) {
          _advance();
        }
        return _token(
          SqlTokenKind.operator,
          startIndex,
          startLineValue,
          startColumnValue,
        );
      }
    }

    final current = _peek();
    if ('+-*/%=<>!&|^~?'.contains(current)) {
      _advance();
      return _token(
        SqlTokenKind.operator,
        startIndex,
        startLineValue,
        startColumnValue,
      );
    }

    if ('(),.;{}:'.contains(current)) {
      _advance();
      return _token(
        SqlTokenKind.punctuation,
        startIndex,
        startLineValue,
        startColumnValue,
      );
    }

    final codePoint = current.codeUnitAt(0).toRadixString(16).toUpperCase().padLeft(4, '0');
    _fail(
      'SSS-LEX-CHAR',
      'Unexpected character U+$codePoint.',
      startOffset + startIndex,
      startLineValue,
      startColumnValue,
    );
  }

  SqlToken _scanLineComment() {
    final start = _index;
    final line = _line;
    final column = _column;
    _advance();
    _advance();
    while (!_isAtEnd && _peek() != '\r' && _peek() != '\n') {
      _advance();
    }
    return _token(SqlTokenKind.lineComment, start, line, column);
  }

  SqlToken _scanBlockComment() {
    final start = _index;
    final line = _line;
    final column = _column;
    _advance();
    _advance();
    var depth = 1;
    while (!_isAtEnd && depth > 0) {
      if (_matches('/*')) {
        _advance();
        _advance();
        depth++;
      } else if (_matches('*/')) {
        _advance();
        _advance();
        depth--;
      } else {
        _advance();
      }
    }
    if (depth != 0) {
      _fail(
        'SSS-LEX-COMMENT',
        'Unterminated block comment.',
        startOffset + start,
        line,
        column,
      );
    }
    return _token(SqlTokenKind.blockComment, start, line, column);
  }

  SqlToken _scanString({required bool unicode}) {
    final start = _index;
    final line = _line;
    final column = _column;
    final value = _readQuotedContent(
      quote: "'",
      errorCode: 'SSS-LEX-STRING',
      errorMessage: 'Unterminated string literal.',
      startOffsetValue: startOffset + start,
      startLineValue: line,
      startColumnValue: column,
    );
    return _token(
      unicode ? SqlTokenKind.unicodeStringLiteral : SqlTokenKind.stringLiteral,
      start,
      line,
      column,
      value: value,
    );
  }

  SqlToken _scanUnicodeString() {
    final start = _index;
    final line = _line;
    final column = _column;
    _advance(); // N prefix
    final value = _readQuotedContent(
      quote: "'",
      errorCode: 'SSS-LEX-STRING',
      errorMessage: 'Unterminated Unicode string literal.',
      startOffsetValue: startOffset + start,
      startLineValue: line,
      startColumnValue: column,
    );
    return _token(
      SqlTokenKind.unicodeStringLiteral,
      start,
      line,
      column,
      value: value,
    );
  }

  String _readQuotedContent({
    required String quote,
    required String errorCode,
    required String errorMessage,
    required int startOffsetValue,
    required int startLineValue,
    required int startColumnValue,
  }) {
    _advance(); // opening quote
    final value = StringBuffer();
    while (!_isAtEnd) {
      final current = _advance();
      if (current == quote) {
        if (_peek() == quote) {
          _advance();
          value.write(quote);
          continue;
        }
        return value.toString();
      }
      value.write(current);
    }
    _fail(
      errorCode,
      errorMessage,
      startOffsetValue,
      startLineValue,
      startColumnValue,
    );
  }

  SqlToken _scanBracketedIdentifier() {
    final start = _index;
    final line = _line;
    final column = _column;
    _advance();
    final value = StringBuffer();
    while (!_isAtEnd) {
      final current = _advance();
      if (current == ']') {
        if (_peek() == ']') {
          _advance();
          value.write(']');
          continue;
        }
        if (value.isEmpty) {
          _fail(
            'SSS-LEX-IDENTIFIER',
            'Bracketed identifier cannot be empty.',
            startOffset + start,
            line,
            column,
          );
        }
        return _token(
          SqlTokenKind.bracketedIdentifier,
          start,
          line,
          column,
          value: value.toString(),
        );
      }
      value.write(current);
    }
    _fail(
      'SSS-LEX-IDENTIFIER',
      'Unterminated bracketed identifier.',
      startOffset + start,
      line,
      column,
    );
  }

  SqlToken _scanQuotedIdentifier() {
    final start = _index;
    final line = _line;
    final column = _column;
    final value = _readQuotedContent(
      quote: '"',
      errorCode: 'SSS-LEX-QUOTED',
      errorMessage: 'Unterminated double-quoted token.',
      startOffsetValue: startOffset + start,
      startLineValue: line,
      startColumnValue: column,
    );
    return _token(
      quotedIdentifiers
          ? SqlTokenKind.quotedIdentifier
          : SqlTokenKind.stringLiteral,
      start,
      line,
      column,
      value: value,
    );
  }

  SqlToken _scanPrefixedIdentifier() {
    final start = _index;
    final line = _line;
    final column = _column;
    final prefix = _peek();
    _advance();
    if (prefix == '@' && _peek() == '@') _advance();
    if (!_isIdentifierStart(_peek()) && !_isDigit(_peek())) {
      return _token(SqlTokenKind.operator, start, line, column);
    }
    while (_isIdentifierPart(_peek())) {
      _advance();
    }
    final prefixLength = prefix == '@' && _source.startsWith('@@', start) ? 2 : 1;
    final isVariable = prefix == '@';
    return _token(
      isVariable ? SqlTokenKind.variable : SqlTokenKind.identifier,
      start,
      line,
      column,
      value: isVariable
          ? _source.substring(start + prefixLength, _index)
          : _source.substring(start, _index),
    );
  }

  SqlToken _scanBinaryLiteral() {
    final start = _index;
    final line = _line;
    final column = _column;
    _advance();
    _advance();
    final digitsStart = _index;
    while (_isHexDigit(_peek())) {
      _advance();
    }
    if (_index == digitsStart || _isIdentifierPart(_peek())) {
      _fail(
        'SSS-LEX-BINARY',
        'Binary literal must start with 0x and contain uninterrupted hexadecimal digits.',
        startOffset + start,
        line,
        column,
      );
    }
    final digits = _source.substring(digitsStart, _index);
    if (digits.length.isOdd) {
      _fail(
        'SSS-LEX-BINARY',
        'Binary literal must contain an even number of hexadecimal digits.',
        startOffset + start,
        line,
        column,
      );
    }
    return _token(
      SqlTokenKind.binaryLiteral,
      start,
      line,
      column,
      value: digits.toUpperCase(),
    );
  }

  SqlToken _scanNumber() {
    final start = _index;
    final line = _line;
    final column = _column;
    var hasFraction = false;
    var hasExponent = false;

    if (_peek() == '.') {
      hasFraction = true;
      _advance();
      while (_isDigit(_peek())) {
        _advance();
      }
    } else {
      while (_isDigit(_peek())) {
        _advance();
      }
      if (_peek() == '.' && _isDigit(_peek(1))) {
        hasFraction = true;
        _advance();
        while (_isDigit(_peek())) {
          _advance();
        }
      }
    }

    if (_peek().toUpperCase() == 'E') {
      hasExponent = true;
      _advance();
      if (_peek() == '+' || _peek() == '-') _advance();
      if (!_isDigit(_peek())) {
        _fail(
          'SSS-LEX-NUMBER',
          'Exponent must contain at least one digit.',
          startOffset + start,
          line,
          column,
        );
      }
      while (_isDigit(_peek())) {
        _advance();
      }
    }

    final kind = hasExponent
        ? SqlTokenKind.approximateNumericLiteral
        : (hasFraction
            ? SqlTokenKind.decimalLiteral
            : SqlTokenKind.integerLiteral);
    return _token(kind, start, line, column);
  }

  SqlToken _scanWord() {
    final start = _index;
    final line = _line;
    final column = _column;
    _advance();
    while (_isIdentifierPart(_peek())) {
      _advance();
    }
    final word = _source.substring(start, _index);
    final kind = _keywords.contains(word.toUpperCase())
        ? SqlTokenKind.keyword
        : SqlTokenKind.identifier;
    return _token(kind, start, line, column);
  }

  SqlToken _token(
    SqlTokenKind kind,
    int startIndex,
    int line,
    int column, {
    String? value,
  }) {
    final lexeme = _source.substring(startIndex, _index);
    return SqlToken(
      kind: kind,
      lexeme: lexeme,
      value: value ?? lexeme,
      startOffset: startOffset + startIndex,
      endOffset: startOffset + _index,
      startLine: line,
      startColumn: column,
      endLine: _line,
      endColumn: _column,
      batchNumber: batchNumber,
    );
  }

  Never _fail(
    String code,
    String message,
    int offset,
    int line,
    int column,
  ) {
    throw SqlLexException(
      code: code,
      message: message,
      offset: offset,
      line: line,
      column: column,
    );
  }
}
