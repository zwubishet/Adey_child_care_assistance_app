import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/community/comment_model.dart';
import 'package:adde/pages/community/post_model.dart';
import 'package:adde/pages/community/post_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Comment> _comments = [];
  String? motherId;
  String? fullName;
  bool _isLoading = true;
  RealtimeChannel? _commentChannel;
  RealtimeChannel? _likeChannel;
  String? _errorMessage;
  late Post _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _subscribeToComments();
    _subscribeToLikes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchUserData();
    _fetchComments();
  }

  Future<void> _fetchUserData() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showSnackBar(l10n.pleaseLogIn);
        setState(() {
          _errorMessage = l10n.pleaseLogIn;
          _isLoading = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('mothers')
          .select('full_name')
          .eq('user_id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      setState(() {
        motherId = user.id;
        fullName = response?['full_name']?.toString() ?? 'Unknown';
        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar(l10n.errorFetchingUserData(e.toString()));
      setState(() {
        _errorMessage = l10n.errorFetchingUserData(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchComments() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await Supabase.instance.client
          .from('comments')
          .select('*, mothers(full_name, profile_url)')
          .eq('post_id', _currentPost.id)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      setState(() {
        _comments =
            response
                .map<Comment>(
                  (map) => Comment.fromMap(
                    map,
                    map['mothers']['full_name'] ?? 'Unknown',
                  ),
                )
                .toList();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      _showSnackBar(l10n.errorFetchingComments(e.toString()));
      setState(() => _comments = []);
    }
  }

  void _subscribeToComments() {
    _commentChannel =
        Supabase.instance.client
            .channel('comments:${_currentPost.id}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'comments',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'post_id',
                value: _currentPost.id,
              ),
              callback: (payload) {
                _fetchComments();
                _refreshPost();
              },
            )
            .subscribe();
  }

  void _subscribeToLikes() {
    _likeChannel =
        Supabase.instance.client
            .channel('likes:${_currentPost.id}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'likes',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'post_id',
                value: _currentPost.id,
              ),
              callback: (payload) {
                _refreshPost();
              },
            )
            .subscribe();
  }

  Future<void> _addComment() async {
    final l10n = AppLocalizations.of(context)!;
    if (_commentController.text.trim().isEmpty ||
        motherId == null ||
        fullName == null) {
      _showSnackBar(l10n.commentCannotBeEmpty);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('comments')
          .insert({
            'post_id': _currentPost.id,
            'mother_id': motherId,
            'content': _commentController.text.trim(),
          })
          .select('*, mothers(full_name, profile_url)')
          .single()
          .timeout(const Duration(seconds: 10));

      setState(() {
        _comments.insert(0, Comment.fromMap(response, fullName!));
        _commentController.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });

      await _refreshPost();
    } catch (e) {
      _showSnackBar(l10n.errorAddingComment(e.toString()));
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await Supabase.instance.client
          .from('comments')
          .delete()
          .eq('id', commentId)
          .eq('mother_id', motherId!)
          .timeout(const Duration(seconds: 10));
      setState(() {
        _comments.removeWhere((comment) => comment.id == commentId);
      });
      _showSnackBar(l10n.commentDeletedSuccessfully, isSuccess: true);
      await _refreshPost();
    } catch (e) {
      _showSnackBar(l10n.errorDeletingComment(e.toString()));
    }
  }

  Future<void> _refreshPost() async {
    try {
      final post = await Provider.of<PostProvider>(
        context,
        listen: false,
      ).fetchPost(_currentPost.id, motherId ?? '');
      setState(() {
        _currentPost = post;
      });
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context)!.errorFetchingPost);
    }
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
    if (_commentChannel != null) {
      Supabase.instance.client.removeChannel(_commentChannel!);
    }
    if (_likeChannel != null) {
      Supabase.instance.client.removeChannel(_likeChannel!);
    }
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(context),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
            strokeWidth: 3,
          ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _buildAppBar(context),
        body: Center(
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
                  _fetchUserData();
                  _fetchComments();
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
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context),
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _fetchComments();
                    await _refreshPost();
                  },
                  color: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surface,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildPostCard(context)),
                      _buildCommentsSection(context),
                      if (_comments.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    IconlyLight.document,
                                    size: 48,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ).animate().fadeIn(duration: 300.ms),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.noCommentsYet,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ).animate().fadeIn(
                                    duration: 300.ms,
                                    delay: 100.ms,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _buildCommentInput(context),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor:
          isDarkMode ? theme.colorScheme.onPrimary : theme.colorScheme.surface,
      elevation: 0,
      title: Text(
        l10n.postDetailTitle,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color:
              isDarkMode
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
            color: theme.colorScheme.surfaceContainer,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Semantics(
                        label: l10n.profileOf(_currentPost.fullName),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.1),
                          backgroundImage: _getImageProvider(
                            _currentPost.profileImageUrl,
                          ),
                          child:
                              _currentPost.profileImageUrl == null ||
                                      _getImageProvider(
                                            _currentPost.profileImageUrl,
                                          ) ==
                                          null
                                  ? Text(
                                    _currentPost.fullName.isNotEmpty
                                        ? _currentPost.fullName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                  : null,
                        ).animate().scale(
                          duration: 300.ms,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentPost.fullName.isNotEmpty
                                  ? _currentPost.fullName
                                  : 'Unknown',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              timeago.format(_currentPost.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentPost.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentPost.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_currentPost.imageUrl != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _currentPost.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder:
                            (context, child, loadingProgress) =>
                                loadingProgress == null
                                    ? child
                                    : Container(
                                      height: 200,
                                      color:
                                          theme
                                              .colorScheme
                                              .surfaceContainerLowest,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: theme.colorScheme.primary,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              height: 200,
                              color: theme.colorScheme.surfaceContainerLowest,
                              child: Center(
                                child: Icon(
                                  IconlyLight.image,
                                  size: 40,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                      ).animate().fadeIn(
                        duration: 300.ms,
                        curve: Curves.easeOut,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        IconlyLight.chat,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: theme.colorScheme.outlineVariant),
                ],
              ),
            ),
          )
          .animate()
          .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
          .slideY(
            begin: 0.2,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final comment = _comments[_comments.length - 1 - index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              label: l10n.commentBy(comment.fullName),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    backgroundImage: _getImageProvider(comment.profileUrl),
                    child:
                        comment.profileUrl == null ||
                                _getImageProvider(comment.profileUrl) == null
                            ? Text(
                              comment.fullName.isNotEmpty
                                  ? comment.fullName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                            : null,
                  ).animate().scale(
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                    delay: (index * 100).ms,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.shadow.withOpacity(
                                  0.1,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    comment.fullName.isNotEmpty
                                        ? comment.fullName
                                        : 'Unknown',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                  ),
                                  if (comment.motherId == motherId)
                                    Semantics(
                                      label: l10n.deleteCommentBy(
                                        comment.fullName,
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          IconlyLight.delete,
                                          size: 20,
                                          color: theme.colorScheme.error,
                                        ),
                                        onPressed:
                                            () => _deleteComment(comment.id),
                                      ).animate().scale(
                                        duration: 300.ms,
                                        curve: Curves.easeOutCubic,
                                        delay: (index * 100).ms,
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                comment.content,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeago.format(comment.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
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
                        ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: _comments.length),
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: l10n.addCommentHint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
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
          Semantics(
            label: l10n.sendCommentTooltip,
            child: IconButton(
              icon: Icon(
                IconlyLight.send,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              onPressed: _addComment,
              tooltip: l10n.sendCommentTooltip,
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutCubic),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOutCubic);
  }
}
