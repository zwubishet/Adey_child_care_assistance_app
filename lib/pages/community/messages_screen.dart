import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/community/peer_chat_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class MessagesScreen extends StatefulWidget {
  final String motherId;

  const MessagesScreen({super.key, required this.motherId});

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;
  RealtimeChannel? _messageChannel;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _subscribeToMessages();
  }

  Future<void> _fetchConversations() async {
    try {
      final response = await Supabase.instance.client
          .from('communitymessages')
          .select(
            '*, sender:mothers!sender_id(full_name, profile_url, online_status), receiver:mothers!receiver_id(full_name, profile_url, online_status)',
          )
          .or(
            'sender_id.eq.${widget.motherId},receiver_id.eq.${widget.motherId}',
          )
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      final Map<String, Map<String, dynamic>> conversationMap = {};
      for (var message in response) {
        final otherId =
            message['sender_id'] == widget.motherId
                ? message['receiver_id']
                : message['sender_id'];
        final otherName =
            message['sender_id'] == widget.motherId
                ? message['receiver']['full_name']
                : message['sender']['full_name'];
        final otherProfileUrl =
            message['sender_id'] == widget.motherId
                ? message['receiver']['profile_url']
                : message['sender']['profile_url'];
        final isOnline =
            message['sender_id'] == widget.motherId
                ? message['receiver']['online_status'] ?? false
                : message['sender']['online_status'] ?? false;
        final isSender = message['sender_id'] == widget.motherId;

        if (!conversationMap.containsKey(otherId)) {
          conversationMap[otherId] = {
            'otherId': otherId,
            'otherName': otherName,
            'profileUrl': otherProfileUrl,
            'lastMessage': message['content'],
            'messageType': message['message_type'] ?? 'text',
            'timestamp': DateTime.parse(message['created_at']),
            'isSeen': message['is_seen'] || isSender,
            'isPinned': message['is_pinned'] ?? false,
            'unreadCount': 0,
            'isOnline': isOnline,
            'isSender': isSender,
          };
        }

        if (!message['is_seen'] && !isSender) {
          conversationMap[otherId]!['unreadCount'] =
              (conversationMap[otherId]!['unreadCount'] as int) + 1;
        }
      }

      setState(() {
        _conversations =
            conversationMap.values.toList()..sort((a, b) {
              if (a['isPinned'] && !b['isPinned']) return -1;
              if (!a['isPinned'] && b['isPinned']) return 1;
              return b['timestamp'].compareTo(a['timestamp']);
            });
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching conversations: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(
          context,
        )!.errorFetchingConversations(e.toString());
      });
      _showSnackBar(
        AppLocalizations.of(context)!.errorFetchingConversations(e.toString()),
      );
    }
  }

  void _subscribeToMessages() {
    _messageChannel =
        Supabase.instance.client
            .channel('messages:${widget.motherId}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'communitymessages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'sender_id',
                value: widget.motherId,
              ),
              callback: (payload) {
                _fetchConversations();
              },
            )
            .subscribe();
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
            content: Text(
              message,
              style: TextStyle(
                color:
                    isSuccess
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                isSuccess
                    ? theme.colorScheme.primary
                    : theme.colorScheme.errorContainer,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ).animate().fadeIn(duration: 300.ms)
          as SnackBar,
    );
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

  @override
  void dispose() {
    if (_messageChannel != null) {
      Supabase.instance.client.removeChannel(_messageChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor:
            isDarkMode
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          l10n.messagesTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color:
                isDarkMode
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
          ),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                  strokeWidth: 3,
                ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut),
              )
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      IconlyLight.dangerCircle,
                      size: 48,
                      color: theme.colorScheme.error,
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _fetchConversations();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.retryButton),
                    ).animate().scale(
                      duration: 300.ms,
                      delay: 200.ms,
                      curve: Curves.easeOutCubic,
                    ),
                  ],
                ),
              )
              : _conversations.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      IconlyLight.chat,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noConversations,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchConversations,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = _conversations[index];
                    final isUnread = conversation['unreadCount'] > 0;

                    return Card(
                          color: theme.colorScheme.surfaceContainer,
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Semantics(
                              label: l10n.profileOf(conversation['otherName']),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    backgroundImage: _getImageProvider(
                                      conversation['profileUrl'],
                                    ),
                                    child:
                                        conversation['profileUrl'] == null ||
                                                _getImageProvider(
                                                      conversation['profileUrl'],
                                                    ) ==
                                                    null
                                            ? Text(
                                              conversation['otherName']
                                                      .isNotEmpty
                                                  ? conversation['otherName'][0]
                                                      .toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                            : null,
                                  ).animate().scale(
                                    duration: 300.ms,
                                    curve: Curves.easeOutCubic,
                                    delay: (index * 100).ms,
                                  ),
                                  if (conversation['isOnline'])
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: CircleAvatar(
                                        radius: 6,
                                        backgroundColor: Colors.green,
                                        child: CircleAvatar(
                                          radius: 4,
                                          backgroundColor:
                                              theme.colorScheme.surface,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    conversation['otherName'],
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight:
                                              isUnread
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (conversation['isPinned'])
                                  Icon(
                                    IconlyLight.bookmark,
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                if (conversation['messageType'] != 'text') ...[
                                  Icon(
                                    _getMessageTypeIcon(
                                      conversation['messageType'],
                                    ),
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Text(
                                    _getMessagePreview(
                                      conversation,
                                      l10n,
                                      conversation['isSender'],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight:
                                          isUnread
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  timeago.format(
                                    conversation['timestamp'],
                                    locale: l10n.localeName,
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        isUnread
                                            ? theme.colorScheme.primary
                                            : theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                  ),
                                ),
                                if (conversation['unreadCount'] > 0)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${conversation['unreadCount']}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => PeerChatScreen(
                                        currentMotherId: widget.motherId,
                                        otherMotherId: conversation['otherId'],
                                        otherMotherName:
                                            conversation['otherName'],
                                      ),
                                ),
                              ).then((_) => _fetchConversations());
                            },
                          ),
                        )
                        .animate()
                        .fadeIn(
                          duration: 400.ms,
                          delay: (index * 100).ms,
                          curve: Curves.easeOutCubic,
                        )
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 400.ms,
                          delay: (index * 100).ms,
                          curve: Curves.easeOutCubic,
                        );
                  },
                ),
              ),
    );
  }

  IconData _getMessageTypeIcon(String type) {
    switch (type) {
      case 'image':
        return IconlyLight.image;
      case 'video':
        return IconlyLight.video;
      case 'document':
        return IconlyLight.document;
      default:
        return IconlyLight.chat;
    }
  }

  String _getMessagePreview(
    Map<String, dynamic> conversation,
    AppLocalizations l10n,
    bool isSender,
  ) {
    final type = conversation['messageType'];
    final content = conversation['lastMessage'];
    if (isSender) {
      return '${l10n.you}: ${_getContentForType(type, content, l10n)}';
    }
    return _getContentForType(type, content, l10n);
  }

  String _getContentForType(
    String type,
    String content,
    AppLocalizations l10n,
  ) {
    switch (type) {
      case 'image':
        return l10n.imageMessage;
      case 'video':
        return l10n.videoMessage;
      case 'document':
        return l10n.documentMessage;
      default:
        return content;
    }
  }
}
