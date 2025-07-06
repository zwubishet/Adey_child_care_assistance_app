import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatHistoryScreen extends StatefulWidget {
  final SupabaseClient supabase;

  const ChatHistoryScreen({super.key, required this.supabase});

  @override
  _ChatHistoryScreenState createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0); // Ensure top is visible on load
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final userId = widget.supabase.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final response = await widget.supabase
          .from("chat_history")
          .select()
          .eq("user_id", userId)
          .order("timestamp", ascending: false); // Newest first
      return response;
    } catch (e) {
      debugPrint("Error fetching chat history: $e");
      return [];
    }
  }

  Future<void> _clearAllHistory() async {
    final userId = widget.supabase.auth.currentUser?.id;
    if (userId == null) {
      _showSnackBar("User not authenticated");
      return;
    }

    try {
      await widget.supabase.from("chat_history").delete().eq("user_id", userId);
      _showSnackBar("Chat history cleared", isSuccess: true);
      setState(() {}); // Refresh the UI
    } catch (e) {
      _showSnackBar("Error clearing history: $e");
    }
  }

  Future<void> _deleteChatEntry(int id) async {
    try {
      await widget.supabase.from("chat_history").delete().eq("id", id);
      _showSnackBar("Chat deleted", isSuccess: true);
      setState(() {}); // Refresh the UI
    } catch (e) {
      _showSnackBar("Error deleting chat: $e");
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:
                  isSuccess
                      ? Colors.white
                      : Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor:
              isSuccess
                  ? Colors.green.shade400
                  : Theme.of(context).colorScheme.error,
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
          "adey Chat History",
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            color:
                theme.brightness == Brightness.light
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.primary,
          ),
        ),
        backgroundColor:
            theme.brightness == Brightness.light
                ? theme.colorScheme.surface
                : theme.colorScheme.onPrimary,
        elevation: theme.appBarTheme.elevation,
        actions: [
          IconButton(
            color:
                theme.brightness == Brightness.light
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.primary,
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => _buildClearAllDialog(theme),
              );
              if (confirm == true) {
                await _clearAllHistory();
              }
            },
            tooltip: "Clear All History",
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading history",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            );
          }
          final history = snapshot.data ?? [];
          if (history.isEmpty) {
            return Center(
              child: Text(
                "No chat history yet.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            );
          }
          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(screenHeight * 0.01),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];
              return _buildHistoryCard(entry, theme, screenHeight);
            },
          );
        },
      ),
    );
  }

  Widget _buildClearAllDialog(ThemeData theme) {
    return AlertDialog(
      title: Text(
        "Clear All History",
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      content: Text(
        "Are you sure you want to delete all chat history? This cannot be undone.",
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            "Cancel",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            "Clear",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildDeleteChatDialog(ThemeData theme, int id) {
    return AlertDialog(
      title: Text(
        "Delete Chat",
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      content: Text(
        "Are you sure you want to delete this chat?",
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            "Cancel",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            "Delete",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildHistoryCard(
    Map<String, dynamic> entry,
    ThemeData theme,
    double screenHeight,
  ) {
    DateTime? timestamp;
    try {
      timestamp =
          entry["timestamp"] != null
              ? DateTime.parse(entry["timestamp"])
              : null;
    } catch (e) {
      timestamp = null;
    }

    return GestureDetector(
      onLongPress: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => _buildDeleteChatDialog(theme, entry["id"]),
        );
        if (confirm == true) {
          await _deleteChatEntry(entry["id"]);
        }
      },
      child: Card(
        margin: EdgeInsets.symmetric(
          horizontal: screenHeight * 0.01,
          vertical: screenHeight * 0.005,
        ),
        color: theme.cardTheme.color,
        elevation: theme.cardTheme.elevation,
        shape: theme.cardTheme.shape,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "You: ${entry['message'] ?? 'No message'}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "adde: ${entry['response'] ?? 'No response'}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timestamp != null
                    ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp)
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
}
