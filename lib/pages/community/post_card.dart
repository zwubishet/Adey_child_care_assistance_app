import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/community/post_model.dart';
import 'package:adde/pages/community/post_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final String? motherId;
  final VoidCallback? onTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onReport;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    this.motherId,
    this.onTap,
    this.onProfileTap,
    this.onReport,
    this.onDelete,
  });

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
    final l10n = AppLocalizations.of(context)!;
    Provider.of<PostProvider>(context, listen: true);

    return Semantics(
      label: l10n.postBy(post.fullName),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: theme.cardTheme.elevation ?? 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: onProfileTap,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                        backgroundImage: _getImageProvider(
                          post.profileImageUrl,
                        ),
                        child:
                            post.profileImageUrl == null ||
                                    _getImageProvider(post.profileImageUrl) ==
                                        null
                                ? Text(
                                  post.fullName.isNotEmpty
                                      ? post.fullName[0].toUpperCase()
                                      : 'U',
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: onProfileTap,
                            child: Text(
                              post.fullName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            post.createdAt.toLocal().toString().substring(
                              0,
                              16,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onReport != null || onDelete != null)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onSelected: (value) {
                          if (value == 'report' && onReport != null) {
                            onReport!();
                          } else if (value == 'delete' && onDelete != null) {
                            onDelete!();
                          }
                        },
                        itemBuilder: (context) {
                          final List<PopupMenuEntry<String>> items = [];
                          if (onReport != null) {
                            items.add(
                              PopupMenuItem(
                                value: 'report',
                                child: Text(l10n.reportPost),
                              ),
                            );
                          }
                          if (onDelete != null) {
                            items.add(
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(l10n.deletePost),
                              ),
                            );
                          }
                          return items;
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      post.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            height: 200,
                            color: theme.colorScheme.surfaceContainer,
                            child: Center(
                              child: Icon(
                                Icons.broken_image,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.comment,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: onTap,
                      tooltip: l10n.viewComments,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
