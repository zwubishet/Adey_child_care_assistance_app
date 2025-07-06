import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> _favoriteEntries = [];
  bool _isLoading = false;
  bool _hasError = false;
  Set<int> expandedEntries = {};
  String? _lastLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.localeOf(context).languageCode;
    if (_favoriteEntries.isEmpty || _lastLocale != currentLocale || _hasError) {
      _fetchFavoriteEntries();
      _lastLocale = currentLocale;
    }
  }

  Future<void> _fetchFavoriteEntries() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;
    final titleField = currentLocale == 'am' ? 'title_am' : 'title_en';
    final textField = currentLocale == 'am' ? 'text_am' : 'text_en';

    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser == null) {
        throw Exception('User is not authenticated');
      }

      final response = await supabase
          .from('info1')
          .select(
            'id, created_at, image, day, time, is_favorite, type, $titleField, $textField',
          )
          .eq('is_favorite', true)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      setState(() {
        _favoriteEntries =
            List<Map<String, dynamic>>.from(response).map((entry) {
              return {
                'id': entry['id'],
                'created_at': entry['created_at'],
                'image': entry['image'],
                'day': entry['day'],
                'time': entry['time'],
                'is_favorite': entry['is_favorite'] ?? false,
                'type': entry['type'],
                'title': entry[titleField] ?? l10n.noTitle,
                'text': entry[textField] ?? l10n.noContent,
              };
            }).toList();
      });
    } catch (e) {
      debugPrint('Error fetching favorite entries: $e');
      if (!mounted) return;

      setState(() => _hasError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorLoadingEntries(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: l10n.retryButton,
            onPressed: _fetchFavoriteEntries,
            textColor: Theme.of(context).colorScheme.onError,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite(String entryId, bool currentStatus) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final supabase = Supabase.instance.client;
      final newStatus = !currentStatus;

      await supabase
          .from('info1')
          .update({'is_favorite': newStatus})
          .eq('id', entryId)
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;

      setState(() {
        final entryIndex = _favoriteEntries.indexWhere(
          (entry) => entry['id'] == entryId,
        );
        if (entryIndex != -1) {
          if (newStatus) {
            _favoriteEntries[entryIndex]['is_favorite'] = true;
          } else {
            _favoriteEntries.removeAt(entryIndex);
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus ? l10n.addedToFavorites : l10n.removedFromFavorites,
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorUpdatingFavorite(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context, l10n),
      body: Stack(
        children: [
          _buildGradientBackground(context),
          RefreshIndicator(
            onRefresh: _fetchFavoriteEntries,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: _buildBody(context, l10n),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return AppBar(
      title: Text(
        l10n.favoriteEntriesTitle,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color:
              Theme.of(context).brightness == Brightness.light
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
        ),
      ),
      backgroundColor:
          Theme.of(context).brightness == Brightness.light
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onPrimary,
      elevation: Theme.of(context).appBarTheme.elevation,
      actions: [
        IconButton(
          icon: Hero(
            tag: 'favorite_icon',
            child: Icon(
              Icons.refresh,
              color:
                  Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
            ),
          ),
          onPressed: _fetchFavoriteEntries,
          tooltip: l10n.refresh,
        ),
      ],
    );
  }

  Widget _buildGradientBackground(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.15),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_isLoading) {
      return Center(
        child: AnimatedOpacity(
          opacity: _isLoading ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (_hasError) {
      return _buildErrorState(context, l10n);
    }

    if (_favoriteEntries.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return ListView.builder(
      itemCount: _favoriteEntries.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _buildEntryCard(context, index, l10n),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: AnimatedOpacity(
        opacity: _hasError ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.errorLoadingEntries('Failed to load favorites'),
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchFavoriteEntries,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.retryButton,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: AnimatedOpacity(
        opacity: _favoriteEntries.isEmpty ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 60,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noFavoriteEntries,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(
    BuildContext context,
    int index,
    AppLocalizations l10n,
  ) {
    final entry = _favoriteEntries[index];
    final isExpanded = expandedEntries.contains(index);
    final isFavorite = entry['is_favorite'] ?? false;

    Uint8List? imageBytes;
    if (entry['image'] != null && entry['image'].isNotEmpty) {
      final imageStr = entry['image'];
      if (imageStr.startsWith('data:image')) {
        final base64Str = imageStr.split(',').last;
        try {
          imageBytes = base64Decode(base64Str);
        } catch (e) {
          debugPrint("Image decoding error: $e");
        }
      }
    }

    return AnimatedScale(
      scale: isExpanded ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: Theme.of(context).cardTheme.elevation ?? 2,
        color: Theme.of(context).cardTheme.color,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                expandedEntries.remove(index);
              } else {
                expandedEntries.add(index);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageBytes != null)
                  Hero(
                    tag: 'image_${entry['id']}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        imageBytes,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              height: 200,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image, size: 50),
                            ),
                      ),
                    ),
                  ),
                if (imageBytes != null) const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry['title'] ?? l10n.noTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    AnimatedScale(
                      scale: isFavorite ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color:
                              isFavorite
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                        ),
                        onPressed:
                            () => _toggleFavorite(
                              entry['id'].toString(),
                              isFavorite,
                            ),
                        tooltip:
                            isFavorite ? l10n.removeFavorite : l10n.addFavorite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Text(
                    entry['text'] ?? l10n.noContent,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: isExpanded ? null : 3,
                    overflow:
                        isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          expandedEntries.remove(index);
                        } else {
                          expandedEntries.add(index);
                        }
                      });
                    },
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      child: Text(isExpanded ? l10n.showLess : l10n.showMore),
                    ),
                  ),
                ),
                Text(
                  l10n.postedAt(
                    DateFormat.yMMMd(
                      Localizations.localeOf(context).languageCode,
                    ).format(DateTime.parse(entry['created_at'])),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
