import 'package:supabase_flutter/supabase_flutter.dart';

/// =============================================
/// LIKE SERVICE
/// Handles all like-related operations globally
/// =============================================
class LikeService {
  static final SupabaseClient supabase = Supabase.instance.client;

  /// =============================================
  /// TOGGLE LIKE (Like / Unlike)
  /// Returns:
  /// true  = liked
  /// false = unliked
  /// =============================================
  static Future<bool> toggleLike({
    required String profileId,
    required String postId,
    required String ownerId,
  }) async {
    try {
      /// Check if already liked
      final existing = await supabase
          .from('likes')
          .select('id')
          .eq('profile_id', profileId)
          .eq('post_id', postId)
          .maybeSingle();

      /// ================= UNLIKE =================
      if (existing != null) {
        await supabase
            .from('likes')
            .delete()
            .eq('profile_id', profileId)
            .eq('post_id', postId);

        return false;
      }

      /// ================= LIKE =================
      await supabase.from('likes').insert({
        'profile_id': profileId,
        'post_id': postId,
        'created_at': DateTime.now().toIso8601String(),
      });

      /// ================= NOTIFICATION =================
      if (profileId != ownerId) {
        await supabase.from('notifications').insert({
          'receiver_id': ownerId,
          'sender_id': profileId,
          'type': 'like',
          'post_id': postId,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return true;

    } catch (e) {
      print('Like error: $e');
      return false;
    }
  }

  /// =============================================
  /// GET LIKES COUNT (optimized)
  /// =============================================
  static Future<int> getLikesCount(String postId) async {
  final data = await supabase
      .from('likes')
      .select('id')
      .eq('post_id', postId);

  return data.length;
}

  /// =============================================
  /// CHECK IF USER LIKED POST
  /// =============================================
  static Future<bool> isLiked({
    required String profileId,
    required String postId,
  }) async {
    final existing = await supabase
        .from('likes')
        .select('id')
        .eq('profile_id', profileId)
        .eq('post_id', postId)
        .maybeSingle();

    return existing != null;
  }

  /// =============================================
  /// GET ALL LIKED POSTS (BULK - IMPORTANT)
  /// Returns Set of postIds
  /// =============================================
  static Future<Set<String>> getLikedPosts({
    required String profileId,
    required List<String> postIds,
  }) async {
    if (postIds.isEmpty) return {};

    final data = await supabase
        .from('likes')
        .select('post_id')
        .eq('profile_id', profileId)
        .inFilter('post_id', postIds);

    return data
        .map<String>((e) => e['post_id'].toString())
        .toSet();
  }

  /// =============================================
  /// GET LIKES COUNT FOR MULTIPLE POSTS
  /// Returns Map<postId, count>
  /// =============================================
  static Future<Map<String, int>> getLikesCountBulk(
    List<String> postIds,
  ) async {
    if (postIds.isEmpty) return {};

    final data = await supabase
        .from('likes')
        .select('post_id')
        .inFilter('post_id', postIds);

    final Map<String, int> counts = {};

    for (var item in data) {
      final postId = item['post_id'].toString();
      counts[postId] = (counts[postId] ?? 0) + 1;
    }

    return counts;
  }
}