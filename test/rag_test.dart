import 'package:flutter_test/flutter_test.dart';
import 'package:tabeeb_ashiah/services/rag_service.dart';

void main() {
  group('Offline RAG Pipeline & Grounded QA Tests', () {
    final ragService = RagService();

    test('Index reference document and create vector embeddings & chunks', () async {
      final doc = await ragService.processAndIndexDocument('sample_ref.txt', 'Computer_Architecture_Ref.pdf');

      expect(doc.fileName, 'Computer_Architecture_Ref.pdf');
      expect(doc.pages.length, greaterThan(0));
      expect(doc.chunks.length, greaterThan(0));
      expect(doc.chunks.first.vectorEmbedding, isNotEmpty);
    });

    test('Query retrieves relevant chunks with page citation when answer exists', () async {
      await ragService.processAndIndexDocument('sample_ref.txt', 'Computer_Architecture_Ref.pdf');

      final result = await ragService.queryDocument('ما هي وظيفة ALU؟');

      expect(result.isFoundInReference, isTrue);
      expect(result.pageReferences, contains(12));
      expect(result.answer, contains('Arithmetic Logic Unit'));
      expect(result.answer, contains('📄 المصدر المرجعي:'));
    });

    test('Query returns fallback message when information is missing in reference', () async {
      await ragService.processAndIndexDocument('sample_ref.txt', 'Computer_Architecture_Ref.pdf');

      final result = await ragService.queryDocument('ما هي عاصمة اليابان وطريقة صناعة السوشي؟');

      expect(result.isFoundInReference, isFalse);
      expect(result.answer, equals('المعلومة غير موجودة في المرجع.'));
      expect(result.pageReferences, isEmpty);
    });
  });
}
