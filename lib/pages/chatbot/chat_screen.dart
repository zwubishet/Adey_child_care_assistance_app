import 'package:adde/pages/chatbot/chat_history.dart';
import 'package:adde/pages/chatbot/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'config.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // System prompt with "adde"
  static const String _systemPrompt = """
You are adey, a friendly and knowledgeable assistant specializing in pregnancy and child care. Provide accurate, supportive advice on topics like prenatal health, nutrition, baby milestones, postpartum care, and parenting tips. Keep responses concise, empathetic, and tailored to the user's needs.
""";

  @override
  void initState() {
    super.initState();
    Gemini.init(apiKey: Config.geminiApiKey);
    _addWelcomeMessage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0); // Ensure top is visible on load
      }
    });
  }

  @override
  void dispose() {
    _saveCurrentChatOnExit();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Add a welcome message from adde
  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text:
              "Hello! I’m adey, your pregnancy and child care companion. How can I assist you today?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  // Send message asynchronously with streaming
  Future<void> _sendMessage(String userInput) async {
    if (userInput.trim().isEmpty || _isLoading) return;

    final userMessage = ChatMessage(
      text: userInput.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Add placeholder for streaming response
    int streamMessageIndex = _messages.length;
    _messages.add(
      ChatMessage(text: "", isUser: false, timestamp: DateTime.now()),
    );

    StringBuffer responseBuffer = StringBuffer();
    try {
      await for (final chunk in _getGeminiResponse(userInput)) {
        setState(() {
          responseBuffer.write(chunk);
          _messages[streamMessageIndex] = ChatMessage(
            text: responseBuffer.toString(),
            isUser: false,
            timestamp: DateTime.now(),
          );
        });
        // Scroll during streaming
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      }

      if (responseBuffer.isNotEmpty) {
        await _saveToSupabase(userMessage.text, responseBuffer.toString());
      }
    } catch (e) {
      setState(() {
        _messages[streamMessageIndex] = ChatMessage(
          text: "Error: Failed to get response - $e",
          isUser: false,
          timestamp: DateTime.now(),
        );
      });
    } finally {
      setState(() => _isLoading = false);
      _controller.clear();
    }
  }

  // Gemini API call using promptStream
  Stream<String> _getGeminiResponse(String userInput) async* {
    try {
      final stream = Gemini.instance.promptStream(
        parts: [TextPart(_systemPrompt), TextPart("User: $userInput")],
      );
      await for (final response in stream) {
        final content = response?.content;
        if (content == null || content.parts!.isEmpty) {
          yield "Error: No response content from Gemini";
          return;
        }
        final text =
            content.parts!
                .map(
                  (part) =>
                      part is TextPart ? part.text ?? "" : part.toString(),
                )
                .join(" ")
                .trim();
        if (text.isEmpty) {
          yield "Error: Empty response from Gemini";
          return;
        }
        yield text;
      }
    } catch (e) {
      debugPrint("Gemini error: $e");
      yield "Error: Failed to get response - $e";
    }
  }

  // Save chat to Supabase
  Future<void> _saveToSupabase(String userMessage, String botResponse) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not authenticated");

      await _supabase.from("chat_history").insert({
        "user_id": userId,
        "message": userMessage,
        "response": botResponse,
        "timestamp": DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Supabase save error: $e");
      _showSnackBar("Failed to save chat: $e");
    }
  }

  // Save current chat when exiting
  Future<void> _saveCurrentChatOnExit() async {
    for (int i = 0; i < _messages.length - 1; i += 2) {
      if (_messages[i].isUser && !_messages[i + 1].isUser) {
        await _saveToSupabase(_messages[i].text, _messages[i + 1].text);
      }
    }
  }

  // Clear chat
  void _clearChat() {
    setState(() {
      _messages.clear();
      _addWelcomeMessage();
    });
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "adey - Your Pregnancy Companion",
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            color:
                Theme.of(context).brightness == Brightness.light
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor:
            Theme.of(context).brightness == Brightness.light
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.onPrimary,
        elevation: theme.appBarTheme.elevation,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChatHistoryScreen(supabase: _supabase),
                  ),
                ),
            tooltip: "View Chat History",
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearChat,
            tooltip: "Clear Chat",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(screenHeight * 0.01),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageTile(message, theme);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(screenHeight * 0.01),
              child: Row(
                children: [
                  SizedBox(width: screenHeight * 0.01),
                  Text(
                    "adey is typing...",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          _buildInputArea(theme, screenHeight),
        ],
      ),
    );
  }

  Widget _buildMessageTile(ChatMessage message, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color:
                message.isUser
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message.timestamp != null
                    ? DateFormat('HH:mm').format(message.timestamp)
                    : "Time unavailable",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, double screenHeight) {
    return Padding(
      padding: EdgeInsets.all(screenHeight * 0.01),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Ask adde anything...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: _sendMessage,
              enabled: !_isLoading,
              style: theme.textTheme.bodyMedium,
              textInputAction: TextInputAction.send,
            ),
          ),
          SizedBox(width: screenHeight * 0.01),
          IconButton(
            icon: Icon(Icons.send, color: theme.colorScheme.primary),
            onPressed: _isLoading ? null : () => _sendMessage(_controller.text),
            tooltip: "Send Message",
          ),
        ],
      ),
    );
  }
}
