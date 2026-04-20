import 'package:supabase_flutter/supabase_flutter.dart';

class HomeService {
  final supabase = Supabase.instance.client;

  // ================================
  // FETCH POSTS
  // ================================
  Future<List<Map<String, dynamic>>> fetchPosts() async {
    try {
      final posts = await supabase
          .from('posts')
          .select()
          .eq('type', 'post')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(posts);
    } catch (e) {
      print("FETCH POSTS ERROR: $e");
      return [];
    }
  }

  // ================================
  // FETCH USERS (PROFILE DATA)
  // ================================
  Future<List<Map<String, dynamic>>> fetchUsers(List profileIds) async {
    if (profileIds.isEmpty) return [];

    try {
      final users = await supabase
          .from('profiles')
          .select('id, username, avatar_url')
          .inFilter('id', profileIds);

      return List<Map<String, dynamic>>.from(users);
    } catch (e) {
      print("FETCH USERS ERROR: $e");
      return [];
    }
  }

  // ================================
  // FETCH LIKES
  // ================================
  Future<List<Map<String, dynamic>>> fetchLikes(List postIds) async {
    if (postIds.isEmpty) return [];

    try {
      final likes = await supabase
          .from('likes')
          .select('post_id')
          .inFilter('post_id', postIds);

      return List<Map<String, dynamic>>.from(likes);
    } catch (e) {
      print("FETCH LIKES ERROR: $e");
      return [];
    }
  }

  // ================================
  // FETCH COMMENTS COUNT
  // ================================
  Future<List<Map<String, dynamic>>> fetchComments() async {
    try {
      final comments = await supabase
          .from('comments')
          .select('post_id');

      return List<Map<String, dynamic>>.from(comments);
    } catch (e) {
      print("FETCH COMMENTS ERROR: $e");
      return [];
    }
  }

  // ================================
  // FETCH SAVED POSTS
  // ================================
  Future<List<Map<String, dynamic>>> fetchSavedPosts(String profileId) async {
    try {
      final saved = await supabase
          .from('saved_posts')
          .select('post_id')
          .eq('profile_id', profileId);

      return List<Map<String, dynamic>>.from(saved);
    } catch (e) {
      print("FETCH SAVED ERROR: $e");
      return [];
    }
  }

  // ================================
  // FULL FEED (🔥 هذا أهم شي)
  // ================================
  Future<Map<String, dynamic>> fetchFullFeed(String userId) async {
    try {
      final posts = await fetchPosts();

      if (posts.isEmpty) {
        return {
          "posts": [],
          "users": {},
          "likesCount": {},
          "commentsCount": {},
          "savedPosts": {},
        };
      }

      // ================= IDS =================
      final postIds = posts.map((p) => p['id']).toList();

      final profileIds = posts
          .map((p) => p['profile_id'])
          .where((id) => id != null)
          .toSet()
          .toList();

      // ================= FETCH ALL =================
      final results = await Future.wait([
        fetchUsers(profileIds),
        fetchLikes(postIds),
        fetchComments(),
        fetchSavedPosts(userId),
      ]);

      final users = results[0] as List;
      final likes = results[1] as List;
      final comments = results[2] as List;
      final saved = results[3] as List;

      // ================= USERS MAP =================
      final Map<String, dynamic> usersMap = {
        for (var u in users)
          u['id'].toString(): u
      };

      // ================= LIKES COUNT =================
      final Map<String, int> likesCount = {};
      for (var l in likes) {
        final id = l['post_id'].toString();
        likesCount[id] = (likesCount[id] ?? 0) + 1;
      }

      // ================= COMMENTS COUNT =================
      final Map<String, int> commentsCount = {};
      for (var c in comments) {
        final id = c['post_id'].toString();
        commentsCount[id] = (commentsCount[id] ?? 0) + 1;
      }

      // ================= SAVED POSTS =================
      final Map<String, bool> savedPosts = {
        for (var s in saved)
          s['post_id'].toString(): true
      };

      return {
        "posts": posts,
        "users": usersMap,
        "likesCount": likesCount,
        "commentsCount": commentsCount,
        "savedPosts": savedPosts,
      };
    } catch (e) {
      print("FULL FEED ERROR: $e");

      return {
        "posts": [],
        "users": {},
        "likesCount": {},
        "commentsCount": {},
        "savedPosts": {},
      };
    }
  }

  // ================================
  // TOGGLE LIKE
  // ================================
  Future<void> toggleLike({
    required String postId,
    required String profileId,
  }) async {
    try {
      final existing = await supabase
          .from('likes')
          .select('id')
          .eq('post_id', postId)
          .eq('profile_id', profileId)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('likes')
            .delete()
            .eq('post_id', postId)
            .eq('profile_id', profileId);
      } else {
        await supabase.from('likes').insert({
          'post_id': postId,
          'profile_id': profileId,
        });
      }
    } catch (e) {
      print("LIKE ERROR: $e");
    }
  }

  // ================================
  // TOGGLE SAVE
  // ================================
  Future<void> toggleSave({
    required String postId,
    required String profileId,
  }) async {
    try {
      final existing = await supabase
          .from('saved_posts')
          .select()
          .eq('profile_id', profileId)
          .eq('post_id', postId)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('saved_posts')
            .delete()
            .eq('profile_id', profileId)
            .eq('post_id', postId);
      } else {
        await supabase.from('saved_posts').insert({
          'profile_id': profileId,
          'post_id': postId,
        });
      }
    } catch (e) {
      print("SAVE ERROR: $e");
    }
  }

  // ================================
  // SHARES COUNT
  // ================================
  Future<int> getSharesCount(String postId) async {
    try {
      final data = await supabase
          .from('messages')
          .select('id')
          .eq('post_id', postId);

      return data.length;
    } catch (e) {
      print("SHARES ERROR: $e");
      return 0;
    }
  }
}