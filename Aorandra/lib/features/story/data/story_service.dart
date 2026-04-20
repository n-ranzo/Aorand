import 'package:supabase_flutter/supabase_flutter.dart';

class StoryService {
  final supabase = Supabase.instance.client;

  // ============================================
  // FETCH STORIES (ONLY LAST 24 HOURS)
  // ============================================
  Future<List<Map<String, dynamic>>> fetchStories() async {
    try {
      final data = await supabase
          .from('stories')
          .select();

      final now = DateTime.now();

      // ================= FILTER (24h only) =================
      final validStories = data.where((story) {
        final createdAt =
            DateTime.tryParse(story['created_at'] ?? '');

        if (createdAt == null) return false;

        return createdAt.isAfter(
          now.subtract(const Duration(hours: 24)),
        );
      }).toList();

      return List<Map<String, dynamic>>.from(validStories);
    } catch (e) {
      print("FETCH STORIES ERROR: $e");
      return [];
    }
  }

  // ============================================
  // 🔥 IMPORTANT FIX (DO NOT REMOVE)
  // This keeps your UI working without breaking anything
  // ============================================
  Future<List<Map<String, dynamic>>> getProcessedStoriesRaw() async {
    final data = await fetchStories();
    return List<Map<String, dynamic>>.from(data);
  }

  // ============================================
  // GROUP STORIES BY USER
  // ============================================
  Map<String, List<Map<String, dynamic>>> groupStoriesByUser(
    List<Map<String, dynamic>> stories,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var story in stories) {
      final userId = story['profile_id']?.toString();
      if (userId == null) continue;

      grouped.putIfAbsent(userId, () => []);
      grouped[userId]!.add(story);
    }

    return grouped;
  }

  // ============================================
  // GET MY STORIES
  // ============================================
  List<Map<String, dynamic>> getMyStories(
    Map<String, List<Map<String, dynamic>>> grouped,
    String? myId,
  ) {
    if (myId == null) return [];

    return grouped[myId] ?? [];
  }

  // ============================================
  // GET OTHER USERS STORIES
  // ============================================
  List<MapEntry<String, List<Map<String, dynamic>>>> getOtherStories(
    Map<String, List<Map<String, dynamic>>> grouped,
    String? myId,
  ) {
    final copy = Map<String, List<Map<String, dynamic>>>.from(grouped);

    if (myId != null) {
      copy.remove(myId);
    }

    return copy.entries.toList();
  }
}