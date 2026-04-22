import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  static final supabase = Supabase.instance.client;

  /// ===============================
  /// GET USER DATA
  /// ===============================
  static Future<Map<String, dynamic>> getUser(String userId) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

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
  /// GET VIDEOS (AORIS)
  /// ===============================
  static Future<List<Map<String, dynamic>>> getVideos(String userId) async {
    final data = await supabase
        .from('posts')
        .select()
        .eq('profile_id', userId)
        .eq('type', 'video');

    return List<Map<String, dynamic>>.from(data);
  }

  /// ===============================
  /// FOLLOW USER
  /// ===============================
  static Future<void> followUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    final targetUser = await getUser(targetUserId);
    final currentUser = await getUser(currentUserId);

    final followers = List.from(targetUser['followersList'] ?? []);
    final following = List.from(currentUser['followingList'] ?? []);

    if (!followers.contains(currentUserId)) {
      followers.add(currentUserId);
    }

    if (!following.contains(targetUserId)) {
      following.add(targetUserId);
    }

    await supabase.from('profiles').update({
      'followersList': followers,
      'followers': (targetUser['followers'] ?? 0) + 1,
    }).eq('id', targetUserId);

    await supabase.from('profiles').update({
      'followingList': following,
      'following': (currentUser['following'] ?? 0) + 1,
    }).eq('id', currentUserId);
  }

  /// ===============================
  /// UNFOLLOW USER
  /// ===============================
  static Future<void> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    final targetUser = await getUser(targetUserId);
    final currentUser = await getUser(currentUserId);

    final followers = List.from(targetUser['followersList'] ?? []);
    final following = List.from(currentUser['followingList'] ?? []);

    followers.remove(currentUserId);
    following.remove(targetUserId);

    await supabase.from('profiles').update({
      'followersList': followers,
      'followers': (targetUser['followers'] ?? 0) - 1,
    }).eq('id', targetUserId);

    await supabase.from('profiles').update({
      'followingList': following,
      'following': (currentUser['following'] ?? 0) - 1,
    }).eq('id', currentUserId);
  }
}