import 'sql_lexer.dart';
import 'sql_token.dart';

/// One source batch separated by an isolated GO directive.
class SqlBatch {
  final int batchNumber;
  final String sourceText;
  final int repeatCount;
  final int sourceStartOffset;
  final int sourceStartLine;
  final List<SqlToken> tokens;

  SqlBatch({
    required this.batchNumber,
    required this.sourceText,
    required this.repeatCount,
    required this.sourceStartOffset,
    required this.sourceStartLine,
    required List<SqlToken> tokens,
  }) : tokens = List<SqlToken>.unmodifiable(tokens);

  String get text => sourceText.trim();
}

/// Structured diagnostic for malformed GO repeat syntax.
class SqlBatchException implements Exception {
  final String code;
  final String message;
  final int offset;
  final int line;
  final int column;

  const SqlBatchException({
    required this.code,
    required this.message,
    required this.offset,
    required this.line,
    required this.column,
  });

  @override
  String toString() => '$code at $line:$column: $message';
}

class _LineRange {
  final int number;
  final int start;
  final int contentEnd;
  final int nextStart;

  const _LineRange(this.number, this.start, this.contentEnd, this.nextStart);
}

/// Splits T-SQL source on isolated GO lines using lexer tokens.
///
/// GO inside strings, comments, or quoted identifiers is not a separator.
/// Repeat counts are metadata only; no SQL execution is performed here.
class BatchProcessor {
  List<String> process(String script) =>
      processBatches(script).map((batch) => batch.text).toList();

  List<SqlBatch> processBatches(String script) {
    if (script.trim().isEmpty) return [];

    final allTokens = SqlLexer().tokenize(script);
    final lines = _lineRanges(script);
    final tokensByLine = <int, List<SqlToken>>{};

    // Index tokens once, avoiding a full-token scan for every source line.
    for (final token in allTokens) {
      if (token.isComment || token.isEndOfFile) continue;
      tokensByLine.putIfAbsent(token.startLine, () => <SqlToken>[]).add(token);
    }

    final delimiters = <_LineRange, int>{};

    for (final line in lines) {
      final lineTokens = tokensByLine[line.number] ?? const <SqlToken>[];

      if (lineTokens.isEmpty ||
          lineTokens.first.kind != SqlTokenKind.keyword ||
          lineTokens.first.lexeme.toUpperCase() != 'GO') {
        continue;
      }

      var repeatCount = 1;
      if (lineTokens.length == 2 &&
          lineTokens[1].kind == SqlTokenKind.integerLiteral) {
        final parsed = int.tryParse(lineTokens[1].lexeme);
        if (parsed == null || parsed < 1) {
          _invalidGo(
            lineTokens.first,
            'GO repeat count must be a positive integer.',
          );
        }
        repeatCount = parsed;
      } else if (lineTokens.length != 1) {
        _invalidGo(
          lineTokens.first,
          'GO must be alone on its line, optionally followed by one positive integer repeat count.',
        );
      }

      delimiters[line] = repeatCount;
    }

    final batches = <SqlBatch>[];
    var segmentStart = 0;
    var segmentStartLine = 1;

    void addSegment(int endOffset, int repeatCount) {
      if (endOffset < segmentStart) return;
      final sourceText = script.substring(segmentStart, endOffset);
      if (sourceText.trim().isEmpty) return;

      final batchNumber = batches.length + 1;
      final tokens = SqlLexer(
        batchNumber: batchNumber,
        startOffset: segmentStart,
        startLine: segmentStartLine,
      ).tokenize(sourceText).where((token) => !token.isEndOfFile).toList();

      batches.add(
        SqlBatch(
          batchNumber: batchNumber,
          sourceText: sourceText,
          repeatCount: repeatCount,
          sourceStartOffset: segmentStart,
          sourceStartLine: segmentStartLine,
          tokens: tokens,
        ),
      );
    }

    for (final line in lines) {
      final repeatCount = delimiters[line];
      if (repeatCount == null) continue;
      addSegment(line.start, repeatCount);
      segmentStart = line.nextStart;
      segmentStartLine = line.number + 1;
    }

    addSegment(script.length, 1);
    return batches;
  }

  List<_LineRange> _lineRanges(String source) {
    final result = <_LineRange>[];
    var start = 0;
    var line = 1;
    var index = 0;

    while (index < source.length) {
      final current = source[index];
      if (current == '\r' || current == '\n') {
        final contentEnd = index;
        if (current == '\r' &&
            index + 1 < source.length &&
            source[index + 1] == '\n') {
          index += 2;
        } else {
          index++;
        }
        result.add(_LineRange(line, start, contentEnd, index));
        start = index;
        line++;
      } else {
        index++;
      }
    }

    result.add(_LineRange(line, start, source.length, source.length));
    return result;
  }

  Never _invalidGo(SqlToken token, String message) {
    throw SqlBatchException(
      code: 'SSS-BATCH-GO',
      message: message,
      offset: token.startOffset,
      line: token.startLine,
      column: token.startColumn,
    );
  }
}
