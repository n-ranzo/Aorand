import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static String _key(String type) => "search_history$type";

  static Future<List<String>> getHistory(String type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key(type)) ?? [];
  }

  static Future<void> addSearch(String type, String query) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> history = prefs.getStringList(_key(type)) ?? [];

    history.remove(query);
    history.insert(0, query);

    if (history.length > 10) {
      history = history.sublist(0, 10);
    }

    await prefs.setStringList(_key(type), history);
  }

  static Future<void> removeItem(String type, String query) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> history = prefs.getStringList(_key(type)) ?? [];

    history.remove(query);

    await prefs.setStringList(_key(type), history);
  }

  static Future<void> clearHistory(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(type));
  }
}