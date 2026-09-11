import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/rag_service.dart';

class RagAssistantScreen extends StatefulWidget {
  const RagAssistantScreen({super.key});

  @override
  State<RagAssistantScreen> createState() => _RagAssistantScreenState();
}

class _RagAssistantScreenState extends State<RagAssistantScreen> {
  final RagService _ragService = RagService();
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isIndexing = false;
  bool _isProcessingQuery = false;
  String? _documentName;
  int _totalPages = 0;
  int _totalChunks = 0;

  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    if (_ragService.currentDocument != null) {
      final doc = _ragService.currentDocument!;
      _documentName = doc.fileName;
      _totalPages = doc.pages.length;
      _totalChunks = doc.chunks.length;
    }
  }

  Future<void> _pickAndIndexDocument() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'png', 'jpg', 'jpeg'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isIndexing = true;
          _documentName = result.files.single.name;
        });

        final doc = await _ragService.processAndIndexDocument(
          result.files.single.path!,
          result.files.single.name,
        );

        setState(() {
          _isIndexing = false;
          _totalPages = doc.pages.length;
          _totalChunks = doc.chunks.length;
          _messages.add({
            'sender': 'system',
            'text': 'تم تحليل وفهرسة المرجع "${doc.fileName}" بنجاح!\nعدد الصفحات: ${doc.pages.length} | عدد الوحدات المستخرجة (Chunks): ${doc.chunks.length}',
          });
        });
      }
    } catch (e) {
      setState(() => _isIndexing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في اختيار الملف: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleAskQuestion() async {
    final text = _questionController.text.trim();
    if (text.isEmpty) return;

    if (_ragService.currentDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى رفع ملف المرجع أولاً قبل كتابة السؤال.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _questionController.clear();
    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isProcessingQuery = true;
    });

    _scrollToBottom();

    final result = await _ragService.queryDocument(text);

    setState(() {
      _isProcessingQuery = false;
      _messages.add({
        'sender': 'assistant',
        'text': result.answer,
        'isGrounded': result.isFoundInReference,
        'pageReferences': result.pageReferences,
        'confidence': result.confidenceScore,
      });
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المساعد الذكي للمراجع (RAG Offline)'),
        backgroundColor: const Color(0xFF1B4965),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Document Status & Picker Header
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Card(
                elevation: 2,
                color: const Color(0xFFE8F1F5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF1B4965),
                        child: Icon(
                          _documentName == null ? Icons.upload_file : Icons.picture_as_pdf,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _documentName ?? 'لم يتم اختيار مرجع بعد',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _documentName == null
                                  ? 'قم برفع PDF / ملزمة / صورة للتحليل الفوري'
                                  : 'الصفحات: $_totalPages | Chunks: $_totalChunks (جاهز للاسترجاع المحلي)',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4965),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isIndexing ? null : _pickAndIndexDocument,
                        icon: _isIndexing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.file_upload, size: 18),
                        label: Text(_documentName == null ? 'رفع مرجع' : 'تغيير المرجع'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Chat Messages List
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.psychology, size: 64, color: Colors.teal.shade300),
                          const SizedBox(height: 12),
                          const Text('نظام الاسترجاع الموثق من المرجع حصراً', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              '✓ يدعم PDF والنصوص والصور\n✓ يجيب بالعربية الموثقة من المرجع الإنجليزي/العربي\n✓ يمنع الهلوسة ويرفض الإجابة عند غياب النص',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isUser = msg['sender'] == 'user';
                        final isSystem = msg['sender'] == 'system';

                        if (isSystem) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.teal.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified, color: Colors.teal, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(msg['text'], style: const TextStyle(fontSize: 12, color: Colors.teal))),
                              ],
                            ),
                          );
                        }

                        return Align(
                          alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                            decoration: BoxDecoration(
                              color: isUser ? const Color(0xFF1B4965) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                              border: isUser ? null : Border.all(color: Colors.teal.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg['text'],
                                  style: TextStyle(
                                    color: isUser ? Colors.white : Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                if (!isUser && msg.containsKey('isGrounded')) ...[
                                  const Divider(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        msg['isGrounded'] ? Icons.check_circle : Icons.cancel,
                                        size: 14,
                                        color: msg['isGrounded'] ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        msg['isGrounded'] ? 'إجابة موثقة من المرجع' : 'غير موجود بالمرجع',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: msg['isGrounded'] ? Colors.green.shade800 : Colors.red.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (_isProcessingQuery)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('جاري البحث والتحقق من المرجع المحلي...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),

            // Question Input Field
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      decoration: InputDecoration(
                        hintText: 'اسأل عن أي معلومة في المرجع المرفق...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _handleAskQuestion(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF1B4965),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _isProcessingQuery ? null : _handleAskQuestion,
                    ),
                  ),
                ],
              ),
            ),

            // Developer Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: const Color(0xFF1B4965),
              child: const Text(
                'المطور محمد الفقيه',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
