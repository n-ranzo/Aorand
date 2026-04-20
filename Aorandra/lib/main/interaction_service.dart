import 'package:supabase_flutter/supabase_flutter.dart';

class InteractionService {
  static final supabase = Supabase.instance.client;

  // ================= LIKE =================
  static Future<bool> toggleLike({
    required String userId,
    required String postId,
    required String ownerId,
  }) async {
    try {
      final existing = await supabase
          .from('likes')
          .select('id')
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('likes')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', postId);

        return false;
      }

      await supabase.from('likes').insert({
        'user_id': userId,
        'post_id': postId,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (userId != ownerId) {
        await supabase.from('notifications').insert({
          'receiver_id': ownerId,
          'sender_id': userId,
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

  // ================= SAVE =================
  static Future<bool> toggleSave({
    required String userId,
    required String postId,
  }) async {
    try {
      final existing = await supabase
          .from('saved_posts')
          .select('id')
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('saved_posts')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', postId);

        return false;
      }

      await supabase.from('saved_posts').insert({
        'user_id': userId,
        'post_id': postId,
      });

      return true;

    } catch (e) {
      print("Save error: $e");
      return false;
    }
  }

  // ================= SHARE =================
  static Future<void> addShare({
    required String postId,
    required String userId,
  }) async {
    try {
      await supabase.from('messages').insert({
        'post_id': postId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Share error: $e");
    }
  }

  // ================= REPOST =================
  static Future<bool> toggleRepost({
    required String userId,
    required String postId,
    required String ownerId,
  }) async {
    try {
      final existing = await supabase
          .from('reposts')
          .select('id')
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('reposts')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', postId);

        return false;
      }

      await supabase.from('reposts').insert({
        'user_id': userId,
        'post_id': postId,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (userId != ownerId) {
        await supabase.from('notifications').insert({
          'receiver_id': ownerId,
          'sender_id': userId,
          'type': 'repost',
          'post_id': postId,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return true;

    } catch (e) {
      print("Repost error: $e");
      return false;
    }
  }

  // ================= FOLLOW =================
  static Future<bool> toggleFollow({
    required String userId,
    required String targetId,
  }) async {
    try {
      final existing = await supabase
          .from('follows')
          .select('id')
          .eq('follower_id', userId)
          .eq('following_id', targetId)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('follows')
            .delete()
            .eq('follower_id', userId)
            .eq('following_id', targetId);

        return false;
      }

      await supabase.from('follows').insert({
        'follower_id': userId,
        'following_id': targetId,
        'created_at': DateTime.now().toIso8601String(),
      });

      await supabase.from('notifications').insert({
        'receiver_id': targetId,
        'sender_id': userId,
        'type': 'follow',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;

    } catch (e) {
      print("Follow error: $e");
      return false;
    }
  }

  // ================= COUNTS (FIXED) =================
  static Future<int> getLikesCount(String postId) async {
    final data = await supabase
        .from('likes')
        .select()
        .eq('post_id', postId);

    return data.length;
  }

  static Future<int> getCommentsCount(String postId) async {
    final data = await supabase
        .from('comments')
        .select()
        .eq('post_id', postId);

    return data.length;
  }

  static Future<int> getSharesCount(String postId) async {
    final data = await supabase
        .from('messages')
        .select()
        .eq('post_id', postId);

    return data.length;
  }

  static Future<int> getRepostsCount(String postId) async {
    final data = await supabase
        .from('reposts')
        .select()
        .eq('post_id', postId);

    return data.length;
  }

  // ================= FOLLOW STATUS =================
  static Future<bool> isFollowing({
    required String userId,
    required String targetId,
  }) async {
    final existing = await supabase
        .from('follows')
        .select('id')
        .eq('follower_id', userId)
        .eq('following_id', targetId)
        .maybeSingle();

    return existing != null;
  }
}