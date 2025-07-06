import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/community/post_card.dart';
import 'package:adde/pages/community/post_provider.dart';
import 'package:adde/pages/community/user_profile_screen.dart';
import 'package:adde/pages/community/create_post_screen.dart';
import 'package:adde/pages/community/post_detail_screen.dart';
import 'package:adde/pages/community/search_screen.dart';
import 'package:adde/pages/community/messages_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_iconly/flutter_iconly.dart'; // For modern icons

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String? motherId;
  bool _isLoading = true;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showSnackBar(AppLocalizations.of(context)!.pleaseLogIn);
        setState(() => _isLoading = false);
        return;
      }
      motherId = user.id;
      final motherData = await Supabase.instance.client
          .from('mothers')
          .select('profile_url')
          .eq('user_id', motherId!)
          .single()
          .timeout(const Duration(seconds: 120));
      setState(() {
        _profileImageUrl = motherData['profile_url'] as String?;
        _isLoading = false;
      });
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      if (postProvider.posts.isEmpty) {
        await postProvider.fetchPosts(motherId!);
      }
    } catch (e) {
      _showSnackBar(
        AppLocalizations.of(context)!.errorFetchingUser(e.toString()),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshPosts() async {
    if (motherId != null) {
      await Provider.of<PostProvider>(
        context,
        listen: false,
      ).fetchPosts(motherId!);
    }
  }

  void _showSnackBar(String message, {VoidCallback? retry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        action:
            retry != null
                ? SnackBarAction(
                  label: AppLocalizations.of(context)!.retryButton,
                  onPressed: retry,
                  textColor: Theme.of(context).colorScheme.onErrorContainer,
                )
                : null,
      ),
    );
  }

  void _showCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreatePostScreen(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      elevation: 4,
    ).then((_) => _refreshPosts());
  }

  void _showReportDialog(String postId) {
    String? selectedReason;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: theme.colorScheme.surfaceContainer,
            title: Text(
              l10n.reportPostTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            content: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: l10n.reportReasonHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
              ),
              value: selectedReason,
              items: [
                DropdownMenuItem(
                  value: 'inappropriate',
                  child: Text(l10n.reasonInappropriate),
                ),
                DropdownMenuItem(value: 'spam', child: Text(l10n.reasonSpam)),
                DropdownMenuItem(
                  value: 'offensive',
                  child: Text(l10n.reasonOffensive),
                ),
                DropdownMenuItem(
                  value: 'misleading',
                  child: Text(l10n.reasonMisleading),
                ),
                DropdownMenuItem(
                  value: 'harassment',
                  child: Text(l10n.reasonHarassment),
                ),
                DropdownMenuItem(
                  value: 'copyright',
                  child: Text(l10n.reasonCopyright),
                ),
                DropdownMenuItem(value: 'other', child: Text(l10n.reasonOther)),
              ],
              onChanged: (value) => selectedReason = value,
              validator:
                  (value) => value == null ? l10n.reportReasonRequired : null,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.cancelButton,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedReason == null) {
                    _showSnackBar(l10n.reportReasonRequired);
                    return;
                  }
                  try {
                    await Provider.of<PostProvider>(
                      context,
                      listen: false,
                    ).reportPost(
                      postId: postId,
                      reporterId: motherId!,
                      reason: selectedReason!,
                    );
                    Navigator.pop(context);
                    _showSnackBar(l10n.reportSubmitted, retry: null);
                  } catch (e) {
                    Navigator.pop(context);
                    _showSnackBar(l10n.errorReportingPost(e.toString()));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.submitButton),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOutCubic),
    );
  }

  void _showDeleteDialog(String postId) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: theme.colorScheme.surfaceContainer,
            title: Text(
              l10n.deletePostTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              l10n.deletePostConfirmation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.cancelButton,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await Provider.of<PostProvider>(
                      context,
                      listen: false,
                    ).deletePost(postId: postId, motherId: motherId!);
                    Navigator.pop(context);
                    _showSnackBar(l10n.deletePostSuccess);
                    await _refreshPosts();
                  } catch (e) {
                    Navigator.pop(context);
                    String errorMessage = l10n.errorDeletingPost(e.toString());
                    if (e.toString().contains('has associated comments')) {
                      errorMessage = l10n.errorDeletingPostWithComments;
                    }
                    _showSnackBar(errorMessage);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.deleteButton),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOutCubic),
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postProvider = Provider.of<PostProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading || motherId == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
            strokeWidth: 3,
          ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor:
            isDarkMode
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          l10n.pageTitleCommunity,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color:
                isDarkMode
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              IconlyLight.search,
              color:
                  isDarkMode
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
            tooltip: l10n.searchPosts,
          ).animate().scale(duration: 300.ms, curve: Curves.easeOutCubic),
          IconButton(
            icon: Icon(
              IconlyLight.message,
              color:
                  isDarkMode
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MessagesScreen(motherId: motherId!),
                  ),
                ),
            tooltip: l10n.viewMessages,
          ).animate().scale(
            duration: 300.ms,
            delay: 100.ms,
            curve: Curves.easeOutCubic,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(
                  label: l10n.createNewPost,
                  child: GestureDetector(
                    onTap: _showCreatePostDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.primary
                                .withOpacity(0.1),
                            backgroundImage: _getImageProvider(
                              _profileImageUrl,
                            ),
                            child:
                                _profileImageUrl == null ||
                                        _getImageProvider(_profileImageUrl) ==
                                            null
                                    ? Text(
                                      motherId![0].toUpperCase(),
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.whatsOnYourMind,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            IconlyLight.edit,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver:
                  postProvider.posts.isEmpty
                      ? SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                IconlyLight.document,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant,
                              ).animate().fadeIn(duration: 300.ms),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noPosts,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ).animate().fadeIn(
                                duration: 300.ms,
                                delay: 100.ms,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshPosts,
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
                        ),
                      )
                      : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final post = postProvider.posts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PostCard(
                                  motherId: motherId,
                                  post: post,
                                  onTap:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) =>
                                                  PostDetailScreen(post: post),
                                        ),
                                      ),
                                  onProfileTap:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => UserProfileScreen(
                                                motherId: post.motherId,
                                                fullName: post.fullName,
                                              ),
                                        ),
                                      ),
                                  onReport:
                                      motherId != post.motherId
                                          ? () => _showReportDialog(post.id)
                                          : null,
                                  onDelete:
                                      motherId == post.motherId
                                          ? () => _showDeleteDialog(post.id)
                                          : null,
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
                                ),
                          );
                        }, childCount: postProvider.posts.length),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
