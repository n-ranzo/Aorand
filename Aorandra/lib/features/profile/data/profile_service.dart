import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aorandra/shared/services/follow_service.dart';

class ProfileService {
  static final supabase = Supabase.instance.client;

  /// ===============================
  /// GET USER DATA
  /// ===============================
  static Future<Map<String, dynamic>> getUser(String userId) async {
    final data =
        await supabase.from('profiles').select().eq('id', userId).single();

    return data;
  }

  /// ===============================
  /// GET POSTS (IMAGES)
  /// ===============================
  static Future<List<Map<String, dynamic>>> getPosts(String userId) async {
    final data = await supabase
        .from('posts')
        .select()
        .eq('profile_id', userId)
        .eq('type', 'image');

    return List<Map<String, dynamic>>.from(data);
  }

  /// ===============================
  /// GET AORIS (VIDEOS)
  /// ===============================
  static Future<List<Map<String, dynamic>>> getVideos(String userId) async {
    final data = await supabase
        .from('posts')
        .select()
        .eq('profile_id', userId)
        .eq('type', 'aoris');

    return List<Map<String, dynamic>>.from(data);
  }

  /// ===============================
  /// FOLLOW USER
  /// ===============================
  static Future<bool> followUser({
    required String currentUserId,
    required String targetUserId,
  }) {
    return FollowService.instance.toggleFollow(targetUserId);
  }

  /// ===============================
  /// GET EDITABLE PROFILE
  /// ===============================
  /// Fetches profile fields needed for the edit screen.
  /// Falls back to a minimal select if optional columns (bio, links) are
  /// not yet present in the Supabase schema cache (PGRST204).
  static Future<Map<String, dynamic>?> getEditableProfile(String userId) async {
    try {
      return await supabase
          .from('profiles')
          .select(
              'id, username, avatar_url, bio, links, name, username_changed_at')
          .eq('id', userId)
          .maybeSingle();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204') {
        // Optional columns missing from schema — fetch core fields only
        return await supabase
            .from('profiles')
            .select('id, username, avatar_url, name, username_changed_at')
            .eq('id', userId)
            .maybeSingle();
      }
      rethrow;
    }
  }

  /// ===============================
  /// UPLOAD AVATAR
  /// ===============================
  static Future<String> uploadAvatar(String userId, File file) async {
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('avatars').upload(path, file);
    return supabase.storage.from('avatars').getPublicUrl(path);
  }

  /// ===============================
  /// CHECK USERNAME AVAILABILITY
  /// ===============================
  static Future<bool> isUsernameTaken(
      String username, String currentUserId) async {
    final res = await supabase
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    if (res == null) return false;
    return res['id'] != currentUserId;
  }

  /// ===============================
  /// SAVE PROFILE
  /// ===============================
  /// Sends the updates map to Supabase.
  /// If a column is missing from the schema cache (PGRST204), it is stripped
  /// from the payload and the request is retried automatically.
  static const _optionalColumns = ['bio', 'links'];

  static Future<List<Map<String, dynamic>>> saveProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      return await supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204') {
        // Strip every optional column that might be absent from the schema
        final safeUpdates = Map<String, dynamic>.from(updates)
          ..removeWhere((key, _) => _optionalColumns.contains(key));

        if (safeUpdates.isEmpty) return [];

        return await supabase
            .from('profiles')
            .update(safeUpdates)
            .eq('id', userId)
            .select();
      }
      rethrow;
    }
  }

  /// ===============================
  /// UNFOLLOW USER
  /// ===============================
  static Future<void> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  }) {
    return FollowService.instance.toggleFollow(targetUserId);
  }
}
