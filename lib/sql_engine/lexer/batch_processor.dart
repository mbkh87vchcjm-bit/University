class BatchProcessor {
  /// Splits raw T-SQL script into discrete execution batches using the isolated `GO` directive.
  /// Ignores `GO` inside string literals (`'SELECT ''GO'';'`) and comments (`-- GO` or `/* GO */`).
  List<String> process(String script) {
    if (script.trim().isEmpty) return [];

    final batches = <String>[];
    final currentBatch = StringBuffer();

    bool inSingleQuoteString = false;
    bool inLineComment = false;
    bool inBlockComment = false;

    final lines = script.split(RegExp(r'\r?\n'));

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final trimmedLine = line.trim();

      // Check if line is an isolated GO separator
      if (!inSingleQuoteString && !inBlockComment && trimmedLine.toUpperCase() == 'GO') {
        final batchText = currentBatch.toString().trim();
        if (batchText.isNotEmpty) {
          batches.add(batchText);
        }
        currentBatch.clear();
        continue;
      }

      // Process characters for comments / quotes tracking
      for (int i = 0; i < line.length; i++) {
        final char = line[i];
        final nextChar = (i + 1 < line.length) ? line[i + 1] : '';

        if (inLineComment) {
          // Line comment ends at end of line
          continue;
        }

        if (inBlockComment) {
          if (char == '*' && nextChar == '/') {
            inBlockComment = false;
            i++;
          }
          continue;
        }

        if (inSingleQuoteString) {
          if (char == "'") {
            if (nextChar == "'") {
              // Escaped quote inside string
              i++;
            } else {
              inSingleQuoteString = false;
            }
          }
          continue;
        }

        // Start of string literal
        if (char == "'") {
          inSingleQuoteString = true;
          continue;
        }

        // Start of line comment
        if (char == '-' && nextChar == '-') {
          inLineComment = true;
          break;
        }

        // Start of block comment
        if (char == '/' && nextChar == '*') {
          inBlockComment = true;
          i++;
          continue;
        }
      }

      inLineComment = false;
      currentBatch.writeln(line);
    }

    final finalBatch = currentBatch.toString().trim();
    if (finalBatch.isNotEmpty) {
      batches.add(finalBatch);
    }

    return batches;
  }
}
