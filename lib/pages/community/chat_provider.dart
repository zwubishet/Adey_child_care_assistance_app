import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/pages/community/message_model.dart';

class ChatProvider with ChangeNotifier {
  List<Message> _messages = [];
  RealtimeChannel? _channel;

  List<Message> get messages => _messages;

  Future<void> fetchMessages(
    String currentMotherId,
    String otherMotherId,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from('communitymessages')
          .select(
            '*, sender:mothers!sender_id(full_name), receiver:mothers!receiver_id(full_name)',
          )
          .or(
            'and(sender_id.eq.$currentMotherId,receiver_id.eq.$otherMotherId),'
            'and(sender_id.eq.$otherMotherId,receiver_id.eq.$currentMotherId)',
          )
          .order('created_at', ascending: true);

      _messages = response.map<Message>((map) => Message.fromMap(map)).toList();
      notifyListeners();
      print(
        'Fetched ${_messages.length} messages for $currentMotherId ↔ $otherMotherId',
      );

      await _markMessagesAsSeen(currentMotherId, otherMotherId);
    } catch (e) {
      print('Error fetching messages: $e');
      rethrow;
    }
  }

  Future<void> _markMessagesAsSeen(
    String currentMotherId,
    String otherMotherId,
  ) async {
    try {
      await Supabase.instance.client
          .from('communitymessages')
          .update({'is_seen': true})
          .eq('receiver_id', currentMotherId)
          .eq('sender_id', otherMotherId)
          .eq('is_seen', false);
      print('Marked messages as seen for $currentMotherId from $otherMotherId');
    } catch (e) {
      print('Error marking messages as seen: $e');
    }
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final response =
          await Supabase.instance.client
              .from('communitymessages')
              .insert({
                'sender_id': senderId,
                'receiver_id': receiverId,
                'content': content,
                'is_seen': false,
                'is_edited': false,
              })
              .select(
                '*, sender:mothers!sender_id(full_name), receiver:mothers!receiver_id(full_name)',
              )
              .single();

      _messages.add(Message.fromMap(response));
      notifyListeners();
      print('Sent message from $senderId to $receiverId');
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    try {
      final response =
          await Supabase.instance.client
              .from('communitymessages')
              .update({
                'content': newContent,
                'is_edited': true,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', messageId)
              .select(
                '*, sender:mothers!sender_id(full_name), receiver:mothers!receiver_id(full_name)',
              )
              .single();

      final updatedMessage = Message.fromMap(response);
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages[index] = updatedMessage;
        notifyListeners();
      }
      print('Edited message $messageId');
    } catch (e) {
      print('Error editing message: $e');
      rethrow;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await Supabase.instance.client
          .from('communitymessages')
          .delete()
          .eq('id', messageId);

      _messages.removeWhere((msg) => msg.id == messageId);
      notifyListeners();
      print('Deleted message $messageId');
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  void subscribeToMessages(String currentMotherId, String otherMotherId) {
    final channelName = 'messages:$currentMotherId:$otherMotherId';
    _channel = Supabase.instance.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'communitymessages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: currentMotherId,
          ),
          callback: (payload) async {
            try {
              final response =
                  await Supabase.instance.client
                      .from('communitymessages')
                      .select(
                        '*, sender:mothers!sender_id(full_name), receiver:mothers!receiver_id(full_name)',
                      )
                      .eq('id', payload.newRecord['id'])
                      .single();
              final message = Message.fromMap(response);
              if ((message.senderId == currentMotherId &&
                      message.receiverId == otherMotherId) ||
                  (message.senderId == otherMotherId &&
                      message.receiverId == currentMotherId)) {
                _messages.add(message);
                notifyListeners();
                print('New message added via subscription: ${message.id}');

                if (message.receiverId == currentMotherId) {
                  await _markMessagesAsSeen(currentMotherId, otherMotherId);
                }
              }
            } catch (e) {
              print('Error in message subscription: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'communitymessages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: '*',
          ),
          callback: (payload) async {
            try {
              final response =
                  await Supabase.instance.client
                      .from('communitymessages')
                      .select(
                        '*, sender:mothers!sender_id(full_name), receiver:mothers!receiver_id(full_name)',
                      )
                      .eq('id', payload.newRecord['id'])
                      .single();
              final updatedMessage = Message.fromMap(response);
              if ((updatedMessage.senderId == currentMotherId &&
                      updatedMessage.receiverId == otherMotherId) ||
                  (updatedMessage.senderId == otherMotherId &&
                      updatedMessage.receiverId == currentMotherId)) {
                final index = _messages.indexWhere(
                  (msg) => msg.id == updatedMessage.id,
                );
                if (index != -1) {
                  _messages[index] = updatedMessage;
                  notifyListeners();
                  print(
                    'Updated message via subscription: ${updatedMessage.id}',
                  );
                }
              }
            } catch (e) {
              print('Error in message update subscription: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'communitymessages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: '*',
          ),
          callback: (payload) {
            final messageId = payload.oldRecord['id'] as String;
            _messages.removeWhere((msg) => msg.id == messageId);
            notifyListeners();
            print('Deleted message via subscription: $messageId');
          },
        )
        .subscribe((status, [error]) {
          print('Subscription status: $status for $channelName');
          if (status == 'CHANNEL_ERROR') {
            print('Message subscription error: $error');
          } else if (status == 'SUBSCRIBED') {
            print(
              'Subscribed to messages for $currentMotherId ↔ $otherMotherId',
            );
          }
        });
  }

  void unsubscribe() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
      print('Unsubscribed from message channel');
    }
    _messages.clear();
    notifyListeners();
  }

  String _getChatId(String id1, String id2) {
    final ids = [id1, id2]..sort();
    return '${ids[0]}:${ids[1]}';
  }

  Future<void> sendTypingStatus(
    String currentMotherId,
    String otherMotherId,
    bool isTyping,
  ) async {
    try {
      await Supabase.instance.client.from('typing_status').upsert({
        'user_id': currentMotherId,
        'chat_id': _getChatId(currentMotherId, otherMotherId),
        'is_typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error sending typing status: $e');
    }
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
