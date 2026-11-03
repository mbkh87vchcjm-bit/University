/// Token kinds emitted by the SQL Student Studio T-SQL lexer.
enum SqlTokenKind {
  keyword,
  identifier,
  bracketedIdentifier,
  quotedIdentifier,
  variable,
  stringLiteral,
  unicodeStringLiteral,
  integerLiteral,
  decimalLiteral,
  approximateNumericLiteral,
  binaryLiteral,
  operator,
  punctuation,
  lineComment,
  blockComment,
  eof,
}

/// A lexical token with a half-open source span.
///
/// Offsets are zero-based UTF-16 code-unit offsets. Lines and columns are
/// one-based; endLine/endColumn identify the position immediately after the
/// token. This convention maps directly to Dart String indexing.
class SqlToken {
  final SqlTokenKind kind;
  final String lexeme;
  final String value;
  final int startOffset;
  final int endOffset;
  final int startLine;
  final int startColumn;
  final int endLine;
  final int endColumn;
  final int batchNumber;

  const SqlToken({
    required this.kind,
    required this.lexeme,
    required this.value,
    required this.startOffset,
    required this.endOffset,
    required this.startLine,
    required this.startColumn,
    required this.endLine,
    required this.endColumn,
    required this.batchNumber,
  });

  bool get isComment =>
      kind == SqlTokenKind.lineComment || kind == SqlTokenKind.blockComment;

  bool get isEndOfFile => kind == SqlTokenKind.eof;

  @override
  String toString() =>
      'SqlToken($kind, $lexeme, $startLine:$startColumn-$endLine:$endColumn)';
}

/// A recoverable lexical diagnostic with a stable simulator-specific code.
class SqlLexException implements Exception {
  final String code;
  final String message;
  final int offset;
  final int line;
  final int column;

  const SqlLexException({
    required this.code,
    required this.message,
    required this.offset,
    required this.line,
    required this.column,
  });

  @override
  String toString() => '$code at $line:$column: $message';
}
