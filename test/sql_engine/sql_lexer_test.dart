import 'package:flutter_test/flutter_test.dart';
import 'package:sql_student_studio/sql_engine/lexer/sql_lexer.dart';
import 'package:sql_student_studio/sql_engine/lexer/sql_token.dart';

void main() {
  group('SqlLexer tokenization', () {
    test('recognizes keywords, identifiers, punctuation, and operators', () {
      final tokens = SqlLexer().tokenize('SELECT StudentId, Name FROM Students WHERE Id >= 10;');
      final useful = tokens.where((t) => !t.isEndOfFile).toList();

      expect(useful[0].kind, SqlTokenKind.keyword);
      expect(useful[0].lexeme, 'SELECT');
      expect(useful[1].kind, SqlTokenKind.identifier);
      expect(useful[2].kind, SqlTokenKind.punctuation);
      expect(useful[3].value, 'Name');
      expect(useful.any((t) => t.lexeme == '>=' && t.kind == SqlTokenKind.operator), isTrue);
      expect(useful.last.lexeme, ';');
    });

    test('decodes escaped bracketed and quoted identifiers', () {
      final tokens = SqlLexer().tokenize('[Student]]Archive] "Column""Name"');
      final useful = tokens.where((t) => !t.isEndOfFile).toList();

      expect(useful[0].kind, SqlTokenKind.bracketedIdentifier);
      expect(useful[0].value, 'Student]Archive');
      expect(useful[1].kind, SqlTokenKind.quotedIdentifier);
      expect(useful[1].value, 'Column"Name');
    });

    test('quoted identifier mode can be disabled', () {
      final token = SqlLexer(quotedIdentifiers: false)
          .tokenize('"not an identifier"')
          .first;
      expect(token.kind, SqlTokenKind.stringLiteral);
      expect(token.value, 'not an identifier');
    });

    test('decodes single-quoted and N-prefixed Unicode strings', () {
      final tokens = SqlLexer().tokenize("'It''s ready' N'مرحبا''بك'");
      expect(tokens[0].kind, SqlTokenKind.stringLiteral);
      expect(tokens[0].value, "It's ready");
      expect(tokens[1].kind, SqlTokenKind.unicodeStringLiteral);
      expect(tokens[1].value, "مرحبا'بك");
    });

    test('recognizes Arabic identifiers and SQL variables', () {
      final tokens = SqlLexer().tokenize('SELECT محمد FROM الطلاب WHERE Id = @studentId AND @@ROWCOUNT > 0; SELECT * FROM #tmpStudents');
      final identifiers = tokens.where((t) => t.kind == SqlTokenKind.identifier);
      final variables = tokens.where((t) => t.kind == SqlTokenKind.variable);

      expect(
        identifiers.map((t) => t.value),
        containsAll(['محمد', 'الطلاب', '#tmpStudents']),
      );
      expect(variables.map((t) => t.lexeme), containsAll(['@studentId', '@@ROWCOUNT']));
    });

    test('recognizes integer, decimal, exponent, and binary literals', () {
      final tokens = SqlLexer().tokenize('1 12.50 1. .75 3.2e-4 0xA1B2');
      final values = tokens.where((t) => !t.isEndOfFile).toList();

      expect(values.map((t) => t.kind), [
        SqlTokenKind.integerLiteral,
        SqlTokenKind.decimalLiteral,
        SqlTokenKind.decimalLiteral,
        SqlTokenKind.decimalLiteral,
        SqlTokenKind.approximateNumericLiteral,
        SqlTokenKind.binaryLiteral,
      ]);
      expect(values[2].lexeme, '1.');
      expect(values.last.value, 'A1B2');
    });

    test('handles comments and omits them when configured', () {
      const script = 'SELECT 1 -- note\r\n/* outer /* nested */ end */ SELECT 2';
      final all = SqlLexer().tokenize(script);
      final codeOnly = SqlLexer(includeComments: false).tokenize(script);

      expect(all.where((t) => t.isComment), hasLength(2));
      expect(codeOnly.any((t) => t.isComment), isFalse);
      expect(codeOnly.where((t) => !t.isEndOfFile).length, lessThan(all.length));
    });

    test('preserves accurate positions across CRLF and multiline strings', () {
      const source = "SELECT 'one\r\ntwo';\r\nGO";
      final tokens = SqlLexer(batchNumber: 4).tokenize(source);
      final stringToken = tokens.firstWhere(
        (t) => t.kind == SqlTokenKind.stringLiteral,
      );
      final goToken = tokens.firstWhere((t) => t.lexeme == 'GO');

      expect(stringToken.startLine, 1);
      expect(stringToken.endLine, 2);
      expect(goToken.startLine, 3);
      expect(goToken.batchNumber, 4);
      expect(goToken.startOffset, source.lastIndexOf('GO'));
    });

    test('preserves CRLF inside decoded multiline string values', () {
      final tokens = SqlLexer().tokenize("SELECT 'one\r\ntwo'");
      final token = tokens.firstWhere(
        (t) => t.kind == SqlTokenKind.stringLiteral,
      );
      expect(token.value, 'one\r\ntwo');
      expect(token.endLine, 2);
    });

    test('supports a non-zero source base offset and line', () {
      final token = SqlLexer(startOffset: 120, startLine: 8)
          .tokenize('SELECT')
          .first;
      expect(token.startOffset, 120);
      expect(token.startLine, 8);
      expect(token.endColumn, 7);
    });

    test('does not classify GO inside quoted forms as a keyword', () {
      final tokens = SqlLexer().tokenize("SELECT 'GO', [GO], \"GO\", GO");
      final goKeywords = tokens
          .where((t) => t.kind == SqlTokenKind.keyword && t.lexeme == 'GO');
      expect(goKeywords, hasLength(1));
    });
  });

  group('SqlLexer diagnostics', () {
    test('rejects unterminated strings, bracketed identifiers, and comments', () {
      for (final source in ["'unfinished", '[unfinished', '/* unfinished']) {
        expect(
          () => SqlLexer().tokenize(source),
          throwsA(isA<SqlLexException>()),
          reason: source,
        );
      }
    });

    test('rejects malformed numeric exponents and binary literals', () {
      for (final source in ['1e+', '0x0', '0x0G']) {
        expect(
          () => SqlLexer().tokenize(source),
          throwsA(isA<SqlLexException>()),
          reason: source,
        );
      }
    });

    test('returns a stable code and location for an invalid character', () {
      try {
        SqlLexer().tokenize('SELECT 1 §');
        fail('Expected a lexical error.');
      } on SqlLexException catch (error) {
        expect(error.code, 'SSS-LEX-CHAR');
        expect(error.line, 1);
        expect(error.column, 10);
        expect(error.offset, 9);
      }
    });
  });
}
