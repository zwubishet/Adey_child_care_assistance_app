import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'name_model.dart';

class NameProvider with ChangeNotifier {
  List<Name> _names = [];
  List<Name> get names => _names;

  Future<void> fetchNames() async {
    try {
      final response = await Supabase.instance.client
          .from('baby_names')
          .select()
          .order('name', ascending: true);

      _names = response.map<Name>((map) => Name.fromMap(map)).toList();
      print('Fetched ${_names.length} names');
      notifyListeners();
    } catch (e) {
      print('Error fetching names: $e');
      throw Exception('Failed to fetch names: $e');
    }
  }
}
