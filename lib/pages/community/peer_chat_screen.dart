import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/community/chat_provider.dart';
import 'package:adde/pages/community/message_model.dart';

class PeerChatScreen extends StatefulWidget {
  final String currentMotherId;
  final String otherMotherId;
  final String otherMotherName;

  const PeerChatScreen({
    super.key,
    required this.currentMotherId,
    required this.otherMotherId,
    required this.otherMotherName,
  });

  @override
  State<PeerChatScreen> createState() => _PeerChatScreenState();
}

class _PeerChatScreenState extends State<PeerChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isTyping = false;
  String? _otherProfileImageBase64;
  String? _editingMessageId;
  final TextEditingController _editMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _messageController.addListener(_onTyping);
    _scrollController.addListener(_maintainScrollPosition);
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      _currentUserId = user.id;
      if (_currentUserId != widget.currentMotherId) {
        throw Exception('Current user ID does not match mother ID');
      }

      final motherData =
          await Supabase.instance.client
              .from('mothers')
              .select('profile_url')
              .eq('user_id', widget.otherMotherId)
              .single();

      final chatProvider = context.read<ChatProvider>();
      await chatProvider.fetchMessages(
        widget.currentMotherId,
        widget.otherMotherId,
      );
      chatProvider.subscribeToMessages(
        widget.currentMotherId,
        widget.otherMotherId,
      );

      setState(() {
        _otherProfileImageBase64 = motherData['profile_url'] as String?;
        _isLoading = false;
        _hasError = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      _displayError(e);
    }
  }

  void _maintainScrollPosition() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  void _onTyping() {
    final isTyping = _messageController.text.trim().isNotEmpty;
    if (isTyping != _isTyping) {
      setState(() => _isTyping = isTyping);
      context.read<ChatProvider>().sendTypingStatus(
        widget.currentMotherId,
        widget.otherMotherId,
        isTyping,
      );
    }
  }

  void _displayError(dynamic error) {
    final l10n = AppLocalizations.of(context)!;
    String message = l10n.unableToLoadChat;
    if (error.toString().contains(
      'relation "public.communitymessages" does not exist',
    )) {
      message = l10n.chatServiceUnavailable;
    } else if (error.toString().contains('User not authenticated')) {
      message = l10n.pleaseLogInChat;
    } else if (error is PostgrestException) {
      message = l10n.databaseError(error.message);
    } else if (error.toString().contains('network')) {
      message = l10n.networkError;
    }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: l10n.retryButton,
          textColor: Theme.of(context).colorScheme.onErrorContainer,
          onPressed: _initializeChat,
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUserId == null) {
      return;
    }

    try {
      final chatProvider = context.read<ChatProvider>();
      if (_editingMessageId != null) {
        await chatProvider.editMessage(
          messageId: _editingMessageId!,
          newContent: _messageController.text.trim(),
        );
        setState(() {
          _editingMessageId = null;
        });
        _messageController.clear();
      } else {
        await chatProvider.sendMessage(
          senderId: widget.currentMotherId,
          receiverId: widget.otherMotherId,
          content: _messageController.text.trim(),
        );
        _messageController.clear();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } catch (e) {
      print('Error sending/editing message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.failedToSendMessage(e.toString()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await context.read<ChatProvider>().deleteMessage(messageId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.messageDeleted,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      print('Error deleting message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.failedToDeleteMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _startEditingMessage(Message message) {
    setState(() {
      _editingMessageId = message.id;
      _messageController.text = message.content;
    });
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  @override
  void dispose() {
    context.read<ChatProvider>().unsubscribe();
    _messageController.removeListener(_onTyping);
    _scrollController.removeListener(_maintainScrollPosition);
    _messageController.dispose();
    _editMessageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  ImageProvider? _getImageProvider(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) return null;
    try {
      final bytes = base64Decode(base64Image);
      return MemoryImage(bytes);
    } catch (e) {
      print('Error decoding base64 image: $e');
      return null;
    }
  }

  Widget _buildChatBody(ChatProvider chatProvider) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              l10n.unableToLoadChat,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initializeChat,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retryButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child:
              chatProvider.messages.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.startChatting(widget.otherMotherName),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatProvider.messages[index];
                      final isSender =
                          message.senderId == widget.currentMotherId;
                      return GestureDetector(
                        onLongPress:
                            isSender
                                ? () => _showMessageOptions(context, message)
                                : null,
                        child: _buildMessageBubble(message, isSender),
                      );
                    },
                  ),
        ),
        if (_isTyping) _buildTypingIndicator(theme, l10n),
        _buildMessageInput(),
      ],
    );
  }

  void _showMessageOptions(BuildContext context, Message message) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text(l10n.editMessage),
                  onTap: () {
                    Navigator.pop(context);
                    _startEditingMessage(message);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete),
                  title: Text(l10n.deleteMessage),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message.id);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme, AppLocalizations l10n) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
              backgroundImage: _getImageProvider(_otherProfileImageBase64),
              child:
                  _otherProfileImageBase64 == null ||
                          _getImageProvider(_otherProfileImageBase64) == null
                      ? Text(
                        widget.otherMotherName.isNotEmpty
                            ? widget.otherMotherName[0].toUpperCase()
                            : '?',
                      )
                      : null,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.typing,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isSender) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isRecent = DateTime.now().difference(message.createdAt).inMinutes < 1;

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment:
              isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isSender)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  backgroundImage: _getImageProvider(_otherProfileImageBase64),
                  child:
                      _otherProfileImageBase64 == null ||
                              _getImageProvider(_otherProfileImageBase64) ==
                                  null
                          ? Text(
                            message.senderName.isNotEmpty
                                ? message.senderName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: theme.colorScheme.onSecondary,
                            ),
                          )
                          : null,
                ),
              ),
            Flexible(
              child: Semantics(
                label:
                    isSender
                        ? '${l10n.sentMessage}: ${message.content}'
                        : '${l10n.receivedMessage}: ${message.content}',
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isSender
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      topLeft:
                          isSender
                              ? const Radius.circular(16)
                              : const Radius.circular(4),
                      topRight:
                          isSender
                              ? const Radius.circular(4)
                              : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        isSender
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
                      if (message.isEdited)
                        Text(
                          l10n.edited,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                isSender
                                    ? theme.colorScheme.onPrimary.withOpacity(
                                      0.7,
                                    )
                                    : theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      Text(
                        message.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              isSender
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeago.format(
                              message.createdAt,
                              locale: l10n.localeName,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  isSender
                                      ? theme.colorScheme.onPrimary.withOpacity(
                                        0.7,
                                      )
                                      : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (isSender && isRecent)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                message.isSeen ? Icons.done_all : Icons.done,
                                size: 16,
                                color: theme.colorScheme.onPrimary.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_hasError,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    _editingMessageId != null
                        ? l10n.editMessageHint
                        : _hasError
                        ? l10n.chatUnavailableHint
                        : l10n.typeMessageHint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_editingMessageId != null)
            IconButton(
              icon: const Icon(Icons.cancel),
              color: theme.colorScheme.onSurfaceVariant,
              onPressed: () {
                setState(() {
                  _editingMessageId = null;
                  _messageController.clear();
                });
              },
              tooltip: l10n.cancelEdit,
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  _messageController.text.trim().isEmpty || _hasError
                      ? theme.colorScheme.onSurfaceVariant.withOpacity(0.3)
                      : theme.colorScheme.primary,
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              color: theme.colorScheme.onPrimary,
              onPressed:
                  _messageController.text.trim().isEmpty || _hasError
                      ? null
                      : _sendMessage,
              tooltip:
                  _editingMessageId != null
                      ? l10n.saveEdit
                      : l10n.sendMessageTooltip,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection:
          l10n.localeName == 'am' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                backgroundImage: _getImageProvider(_otherProfileImageBase64),
                child:
                    _otherProfileImageBase64 == null ||
                            _getImageProvider(_otherProfileImageBase64) == null
                        ? Text(
                          widget.otherMotherName.isNotEmpty
                              ? widget.otherMotherName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.onSecondary,
                          ),
                        )
                        : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.otherMotherName,
                  style: theme.appBarTheme.titleTextStyle?.copyWith(
                    color:
                        isDarkMode
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor:
              isDarkMode
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.surface,
          elevation: theme.appBarTheme.elevation,
        ),
        body:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                )
                : Consumer<ChatProvider>(
                  builder:
                      (context, chatProvider, _) =>
                          _buildChatBody(chatProvider),
                ),
      ),
    );
  }
}
