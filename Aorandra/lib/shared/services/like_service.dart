import 'package:supabase_flutter/supabase_flutter.dart';

class LikeService {
  static final supabase = Supabase.instance.client;

  /// ===============================
  /// TOGGLE LIKE (using profile_id)
  /// ===============================
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
      print("Like error: $e");
      return false;
    }
  }

  /// ===============================
  /// GET LIKES COUNT
  /// ===============================
  static Future<int> getLikesCount(String postId) async {
    final data = await supabase
        .from('likes')
        .select('id')
        .eq('post_id', postId);

    return data.length;
  }

  /// ===============================
  /// CHECK IF USER LIKED
  /// ===============================
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
}