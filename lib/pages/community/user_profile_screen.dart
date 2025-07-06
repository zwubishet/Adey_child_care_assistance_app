import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/community/peer_chat_screen.dart';
import 'package:adde/pages/community/post_card.dart';
import 'package:adde/pages/community/post_detail_screen.dart';
import 'package:adde/pages/community/post_model.dart';

class UserProfileScreen extends StatefulWidget {
  final String motherId;
  final String fullName;

  const UserProfileScreen({
    super.key,
    required this.motherId,
    required this.fullName,
  });

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List<Post> _userPosts = [];
  bool _isLoading = true;
  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _fetchUserPosts();
  }

  Future<void> _fetchUserPosts() async {
    try {
      final response = await Supabase.instance.client
          .from('posts')
          .select('*, mothers(full_name, profile_url)')
          .eq('mother_id', widget.motherId)
          .order('created_at', ascending: false);

      final motherData =
          await Supabase.instance.client
              .from('mothers')
              .select('profile_url')
              .eq('user_id', widget.motherId)
              .single();

      setState(() {
        _userPosts =
            response.map<Post>((map) {
              return Post.fromMap(map, widget.fullName)..isLiked = false;
            }).toList();
        _profileImageBase64 = motherData['profile_url'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorFetchingPosts(e.toString()),
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToChat() async {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.pleaseLogInChat,
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
      return;
    }

    print(
      'Navigating to chat with currentMotherId: ${currentUser.id}, otherMotherId: ${widget.motherId}',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PeerChatScreen(
              currentMotherId: currentUser.id,
              otherMotherId: widget.motherId,
              otherMotherName: widget.fullName,
            ),
      ),
    );
  }

  ImageProvider? _getImageProvider(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) return null;
    try {
      final bytes = base64Decode(base64Image);
      return MemoryImage(bytes);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.fullName,
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
              : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => UserProfileScreen(
                                          motherId: currentUserId ?? '',
                                          fullName: currentUserId ?? '',
                                        ),
                                  ),
                                ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                              backgroundImage: _getImageProvider(
                                _profileImageBase64,
                              ),
                              child:
                                  _profileImageBase64 == null ||
                                          _getImageProvider(
                                                _profileImageBase64,
                                              ) ==
                                              null
                                      ? Text(
                                        widget.fullName.isNotEmpty
                                            ? widget.fullName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(fontSize: 32),
                                      )
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.fullName,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (currentUserId != widget.motherId)
                            ElevatedButton.icon(
                              onPressed: _navigateToChat,
                              icon: const Icon(Icons.message),
                              label: Text(l10n.messageButton),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        l10n.postsTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  if (_userPosts.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            l10n.noPosts,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = _userPosts[index];
                        return AnimatedOpacity(
                          opacity: 1.0,
                          duration: Duration(milliseconds: 300 + index * 100),
                          child: PostCard(
                            post: post,
                            onTap: () {
                              print('Tapped post ID: ${post.id} from profile');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PostDetailScreen(post: post),
                                ),
                              );
                            },
                            onProfileTap: () {}, // Prevent recursive navigation
                          ),
                        );
                      }, childCount: _userPosts.length),
                    ),
                ],
              ),
    );
  }
}
