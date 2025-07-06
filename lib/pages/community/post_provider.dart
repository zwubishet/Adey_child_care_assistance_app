import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/pages/community/post_model.dart';

class PostProvider with ChangeNotifier {
  List<Post> _posts = [];
  List<Post> get posts => _posts;
  RealtimeChannel? _postsChannel;

  PostProvider() {
    _subscribeToPosts();
  }

  void _subscribeToPosts() {
    _postsChannel = Supabase.instance.client
        .channel('posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'posts',
          callback: (payload) {
            print('Post change detected: ${payload.eventType}');
            final motherId =
                Supabase.instance.client.auth.currentUser?.id ?? '';
            if (payload.eventType == 'DELETE') {
              final postId = payload.oldRecord['id'] as String;
              _posts.removeWhere((post) => post.id == postId);
              notifyListeners();
            } else {
              fetchPosts(motherId);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comments',
          callback: (payload) {
            print('Comment change detected: ${payload.eventType}');
            final motherId =
                Supabase.instance.client.auth.currentUser?.id ?? '';
            fetchPosts(motherId);
          },
        )
        .subscribe((status, [error]) {
          print('Subscription status: $status');
          if (status == 'CHANNEL_ERROR') {
            print('Subscription error: $error');
          } else if (status == 'SUBSCRIBED') {
            print('Successfully subscribed to posts, likes, and comments');
          }
        });
  }

  Future<void> fetchPosts(String motherId) async {
    try {
      final response = await Supabase.instance.client
          .from('posts')
          .select(
            '*, mothers!posts_mother_id_fkey(full_name, profile_url), likes!likes_post_id_fkey(mother_id)',
          )
          .order('created_at', ascending: false);

      _posts =
          response.map<Post>((map) {
            return Post.fromMap(map, map['mothers']['full_name'] ?? 'Unknown');
          }).toList();

      // Prioritize posts based on engagement
      _posts.sort((a, b) {
        final aEngagement = a.likesCount + a.commentCount;
        final bEngagement = b.likesCount + b.commentCount;
        return bEngagement.compareTo(aEngagement); // Descending
      });

      notifyListeners();
      print('Fetched ${_posts.length} posts for motherId: $motherId');
      print('Post IDs: ${_posts.map((p) => p.id).toList()}');
    } catch (e) {
      print('Error fetching posts: $e');
      rethrow;
    }
  }

  Future<Post> fetchPost(String postId, String motherId) async {
    try {
      final response =
          await Supabase.instance.client
              .from('posts')
              .select(
                '*, mothers!posts_mother_id_fkey(full_name, profile_url), likes!likes_post_id_fkey(mother_id)',
              )
              .eq('id', postId)
              .single();

      final isLiked =
          (response['likes'] as List<dynamic>?)?.any(
            (like) => like['mother_id'] == motherId,
          ) ??
          false;
      final post = Post.fromMap(
        response,
        response['mothers']['full_name'] ?? 'Unknown',
      )..isLiked = isLiked;
      print(
        'Fetched post ID: $postId, likes: ${post.likesCount}, comments: ${post.commentCount}, isLiked: $isLiked',
      );
      return post;
    } catch (e) {
      print('Error fetching post $postId: $e');
      rethrow;
    }
  }

  Future<void> createPost(
    String motherId,
    String fullName,
    String title,
    String content, {
    File? imageFile,
  }) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$motherId.jpg';
        await Supabase.instance.client.storage
            .from('post-images')
            .upload(fileName, imageFile);
        imageUrl = Supabase.instance.client.storage
            .from('post-images')
            .getPublicUrl(fileName);
      }

      final response =
          await Supabase.instance.client
              .from('posts')
              .insert({
                'mother_id': motherId,
                'title': title.isNotEmpty ? title : 'Post by $fullName',
                'content': content,
                'image_url': imageUrl,
                'likes_count': 0,
                'comment_count': 0,
              })
              .select('*, mothers!posts_mother_id_fkey(full_name, profile_url)')
              .single();

      _posts.insert(0, Post.fromMap(response, fullName));
      notifyListeners();
      print('Created post by $motherId');
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  Future<void> updatePost(
    String postId,
    String title,
    String content, {
    File? imageFile,
  }) async {
    try {
      String? imageUrl;
      final existingPost = _posts.firstWhere((post) => post.id == postId);

      if (imageFile != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${existingPost.motherId}.jpg';
        await Supabase.instance.client.storage
            .from('post-images')
            .upload(
              fileName,
              imageFile,
              fileOptions: const FileOptions(upsert: true),
            );
        imageUrl = Supabase.instance.client.storage
            .from('post-images')
            .getPublicUrl(fileName);

        if (existingPost.imageUrl != null) {
          final oldFileName = existingPost.imageUrl!.split('/').last;
          await Supabase.instance.client.storage.from('post-images').remove([
            oldFileName,
          ]);
        }
      } else if (imageFile == null && existingPost.imageUrl != null) {
        imageUrl = null;
        final oldFileName = existingPost.imageUrl!.split('/').last;
        await Supabase.instance.client.storage.from('post-images').remove([
          oldFileName,
        ]);
      }

      final response =
          await Supabase.instance.client
              .from('posts')
              .update({
                'title': title.isNotEmpty ? title : existingPost.title,
                'content': content,
                'image_url': imageUrl,
              })
              .eq('id', postId)
              .select('*, mothers!posts_mother_id_fkey(full_name, profile_url)')
              .single();

      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        _posts[index] = Post.fromMap(response, _posts[index].fullName)
          ..isLiked = _posts[index].isLiked;
        notifyListeners();
        print('Updated post $postId');
      }
    } catch (e) {
      print('Error updating post: $e');
      rethrow;
    }
  }

  Future<void> reportPost({
    required String postId,
    required String reporterId,
    required String reason,
  }) async {
    try {
      await Supabase.instance.client.from('temporary_report').insert({
        'post_id': postId,
        'reporter_id': reporterId,
        'reason': reason,
      });
      print('Reported post $postId by $reporterId with reason: $reason');
      await fetchPosts(reporterId);
    } catch (e) {
      print('Error reporting post: $e');
      rethrow;
    }
  }

  Future<void> deletePost({
    required String postId,
    required String motherId,
  }) async {
    try {
      final authUserId = Supabase.instance.client.auth.currentUser?.id;
      print(
        'Attempting to delete post $postId by motherId: $motherId, authUserId: $authUserId',
      );

      final post = _posts.firstWhere(
        (p) => p.id == postId,
        orElse: () => throw Exception('Post not found'),
      );
      if (post.imageUrl != null) {
        final fileName = post.imageUrl!.split('/').last;
        print('Removing image: $fileName');
        await Supabase.instance.client.storage.from('post-images').remove([
          fileName,
        ]);
      }

      final response =
          await Supabase.instance.client
              .from('posts')
              .delete()
              .eq('id', postId)
              .eq('mother_id', motherId)
              .select()
              .maybeSingle();

      if (response == null) {
        print('No post deleted for id: $postId, motherId: $motherId');
        throw Exception('Failed to delete post: No matching post found');
      }

      _posts.removeWhere((post) => post.id == postId);
      notifyListeners();
      print('Deleted post $postId by $motherId');

      final check =
          await Supabase.instance.client
              .from('posts')
              .select()
              .eq('id', postId)
              .maybeSingle();
      print(
        'Post $postId in database after deletion: ${check != null ? "exists" : "deleted"}',
      );
    } catch (e) {
      print('Error deleting post: $e');
      if (e.toString().contains('violates foreign key constraint')) {
        throw Exception(
          'Cannot delete post because it has associated comments.',
        );
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    if (_postsChannel != null) {
      Supabase.instance.client.removeChannel(_postsChannel!);
    }
    super.dispose();
  }
}
