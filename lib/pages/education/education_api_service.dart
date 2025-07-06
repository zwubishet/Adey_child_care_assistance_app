import 'package:supabase_flutter/supabase_flutter.dart';

class EducationApiService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<dynamic>> fetchArticles() async {
    final response = await supabase
        .from("education_articles")
        .select("*")
        .order("created_at", ascending: false);
    return response;
  }

  Future<void> addArticle(String title, String summary, String content) async {
    await supabase.from("education_articles").insert({
      "title": title,
      "summary": summary,
      "content": content,
    });
  }

  Future<void> updateArticle(
    String id,
    String title,
    String summary,
    String content,
  ) async {
    await supabase
        .from("education_articles")
        .update({"title": title, "summary": summary, "content": content})
        .eq("id", id);
  }

  Future<void> deleteArticle(String id) async {
    await supabase.from("education_articles").delete().eq("id", id);
  }
}
