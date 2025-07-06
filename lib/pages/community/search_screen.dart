import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/community/post_model.dart';
import 'package:adde/pages/community/post_detail_screen.dart';
import 'package:adde/pages/community/user_profile_screen.dart';
import 'package:adde/pages/community/post_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<Post> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchPosts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from('posts')
          .select('*, mothers(full_name)')
          .ilike('title', '%$query%')
          .order('created_at', ascending: false);
      setState(() {
        _searchResults =
            response.map<Post>((map) {
              return Post.fromMap(
                map,
                map['mothers']['full_name'] ?? 'Unknown',
              );
            }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorSearchingPosts(e.toString()),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: l10n.searchPosts,
            border: InputBorder.none,
          ),
          onChanged: _searchPosts,
        ),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final post = _searchResults[index];
          return PostCard(
            post: post,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
              );
            },
            onProfileTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => UserProfileScreen(
                        motherId: post.motherId,
                        fullName: post.fullName,
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
