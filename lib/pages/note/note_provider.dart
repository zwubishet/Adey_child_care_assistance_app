import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'note_model.dart';

class NoteProvider with ChangeNotifier {
  List<Note> _notes = [];

  List<Note> get notes => _notes;

  /// Fetches notes from Supabase for the current authenticated user.
  Future<void> fetchNotes() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await Supabase.instance.client
          .from('journal_notes')
          .select()
          .eq('mother_id', user.id)
          .order('updated_at', ascending: false);

      _notes = response.map<Note>((map) => Note.fromMap(map)).toList();
      print('Fetched ${_notes.length} notes for userId: ${user.id}');
      notifyListeners();
    } catch (e) {
      print('Error fetching notes: $e');
      throw Exception('Failed to fetch notes: $e');
    }
  }

  /// Creates a new note and adds it to the top of the list.
  Future<void> createNote({
    required String title,
    required String content,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response =
          await Supabase.instance.client
              .from('journal_notes')
              .insert({
                'mother_id': user.id,
                'title': title,
                'content': content,
              })
              .select()
              .single();

      _notes.insert(0, Note.fromMap(response));
      print('Created note ID: ${response['id']}');
      notifyListeners();
    } catch (e) {
      print('Error creating note: $e');
      throw Exception('Failed to create note: $e');
    }
  }

  /// Updates an existing note and refreshes it in the list.
  Future<void> updateNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response =
          await Supabase.instance.client
              .from('journal_notes')
              .update({'title': title, 'content': content})
              .eq('id', noteId)
              .eq('mother_id', user.id)
              .select()
              .single();

      final index = _notes.indexWhere((note) => note.id == noteId);
      if (index != -1) {
        _notes[index] = Note.fromMap(response);
        print('Updated note ID: $noteId');
        notifyListeners();
      }
    } catch (e) {
      print('Error updating note: $e');
      throw Exception('Failed to update note: $e');
    }
  }

  /// Deletes a note by ID and removes it from the list.
  Future<void> deleteNote(String noteId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await Supabase.instance.client
          .from('journal_notes')
          .delete()
          .eq('id', noteId)
          .eq('mother_id', user.id);

      _notes.removeWhere((note) => note.id == noteId);
      print('Deleted note ID: $noteId');
      notifyListeners();
    } catch (e) {
      print('Error deleting note: $e');
      throw Exception('Failed to delete note: $e');
    }
  }
}
