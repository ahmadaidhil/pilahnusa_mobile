import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_colors.dart';
import '../models/chat_message.dart';
import '../services/gemini_chatbot_service.dart';
import '../database/database_helper.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<String> _suggestedPrompts = [
    'Bagaimana cara memilah botol plastik?',
    'Apa bahaya limbah B3 baterai?',
    'Tips membuat pupuk kompos di rumah',
    'Berapa lama sampah plastik terurai?',
  ];

  @override
  void initState() {
    super.initState();
    GeminiChatbotService.instance.initialize();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final history = await DatabaseHelper.instance.getAllChatMessages();
    setState(() {
      _messages.clear();
      if (history.isEmpty) {
        // Add welcome message
        _messages.add(
          ChatMessage(
            id: const Uuid().v4(),
            text:
                'Halo! Saya asisten edukasi PilahNusa AI. Tanyakan apa saja seputar pemilahan sampah, cara mendaur ulang, atau tips pemakaian aplikasi.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        _messages.addAll(history);
      }
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

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _textController.clear();

    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    await DatabaseHelper.instance.insertChatMessage(userMsg);
    _scrollToBottom();

    try {
      final replyText = await GeminiChatbotService.instance.sendMessage(trimmed);
      final botMsg = ChatMessage(
        id: const Uuid().v4(),
        text: replyText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(botMsg);
          _isTyping = false;
        });
        await DatabaseHelper.instance.insertChatMessage(botMsg);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = ChatMessage(
          id: const Uuid().v4(),
          text: 'Maaf, terjadi kesalahan saat memproses jawaban: $e',
          isUser: false,
          timestamp: DateTime.now(),
        );
        setState(() {
          _messages.add(errorMsg);
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(
      text: GeminiChatbotService.instance.apiKey ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vpn_key_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Konfigurasi Gemini API'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Google Gemini API Key Anda untuk menghubungkan asisten AI cerdas secara live.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await GeminiChatbotService.instance.setApiKey(controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gemini API Key berhasil disimpan!'),
                    backgroundColor: AppColors.primaryDark,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearChat() async {
    await DatabaseHelper.instance.clearChatMessages();
    setState(() {
      _messages.clear();
      _messages.add(
        ChatMessage(
          id: const Uuid().v4(),
          text: 'Pesan telah dibersihkan. Silakan mulai percakapan baru.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined, color: AppColors.primaryDark, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tanya AI PilahNusa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Edukasi Pengelolaan Sampah',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined),
            tooltip: 'Konfigurasi Gemini API Key',
            onPressed: _showApiKeyDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Bersihkan Obrolan',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggested prompts chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _suggestedPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(prompt),
                      onPressed: () => _sendMessage(prompt),
                      backgroundColor: AppColors.bgSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Chat message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg);
              },
            ),
          ),

          // Typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'PilahNusa AI sedang mengetik...',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          // Input field row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Tanyakan cara memilah sampah...',
                        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.bgSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: Border.all(
            color: msg.isUser ? AppColors.primary : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                color: msg.isUser ? Colors.white : AppColors.textPrimary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Teks disalin ke papan klip.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: msg.isUser ? Colors.white70 : AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

