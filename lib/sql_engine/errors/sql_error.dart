enum ErrorCategory {
  lexerError,
  parserError,
  semanticError,
  typeError,
  constraintError,
  executionError,
  storageError,
}

class SqlError implements Exception {
  final String code;
  final ErrorCategory category;
  final String message;
  final int line;
  final int column;
  final String? suggestion;

  const SqlError({
    required this.code,
    required this.category,
    required this.message,
    required this.line,
    required this.column,
    this.suggestion,
  });

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeln('❌ $code: ${category.name.toUpperCase()}')
      ..writeln('Line $line, Column $column: $message');
    if (suggestion != null) {
      buffer.writeln('Suggestion: $suggestion');
    }
    return buffer.toString().trim();
  }
}
