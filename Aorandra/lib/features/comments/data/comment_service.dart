import 'package:supabase_flutter/supabase_flutter.dart';

class CommentService {
  final supabase = Supabase.instance.client;

  // ======================
  // GET COMMENTS
  // ======================
  Future<List> getComments(String postId) async {
    final data = await supabase
        .from("comments")
        .select('''
          *,
          profiles (
            id,
            username,
            avatar_url
          )
        ''')
        .eq("post_id", postId)
        .order("created_at", ascending: true);

    return data;
  }

  // ======================
  // ADD COMMENT
  // ======================
  Future<void> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from("comments").insert({
      "post_id": postId,
      "profile_id": user.id,
      "content": content,
      "parent_comment_id": parentId,
    });
  }

  // ======================
  // UPDATE COMMENT (EDIT)
  // ======================
  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    await supabase
        .from("comments")
        .update({
          "content": content,
        })
        .eq("id", commentId);
  }

  // ======================
  // DELETE COMMENT
  // ======================
  Future<void> deleteComment(String commentId) async {
    await supabase
        .from("comments")
        .delete()
        .eq("id", commentId);
  }

  // ======================
  // LIKE COMMENT
  // ======================
  Future<void> likeComment({
    required Map comment,
    required String userId,
  }) async {
    List likedBy = comment["liked_by"] is List
        ? List.from(comment["liked_by"])
        : [];

    List dislikedBy = comment["disliked_by"] is List
        ? List.from(comment["disliked_by"])
        : [];

    if (likedBy.contains(userId)) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
      dislikedBy.remove(userId);
    }

    await supabase
        .from("comments")
        .update({
          "liked_by": likedBy,
          "disliked_by": dislikedBy,
          "likes_count": likedBy.length,
          "dislikes_count": dislikedBy.length,
        })
        .eq("id", comment["id"]);
  }

  // ======================
  // DISLIKE COMMENT
  // ======================
  Future<void> dislikeComment({
    required Map comment,
    required String userId,
  }) async {
    List likedBy = comment["liked_by"] is List
        ? List.from(comment["liked_by"])
        : [];

    List dislikedBy = comment["disliked_by"] is List
        ? List.from(comment["disliked_by"])
        : [];

    if (dislikedBy.contains(userId)) {
      dislikedBy.remove(userId);
    } else {
      dislikedBy.add(userId);
      likedBy.remove(userId);
    }

    await supabase
        .from("comments")
        .update({
          "liked_by": likedBy,
          "disliked_by": dislikedBy,
          "likes_count": likedBy.length,
          "dislikes_count": dislikedBy.length,
        })
        .eq("id", comment["id"]);
  }

  // ======================
  // BLOCK USER
  // ======================
  Future<void> blockUser(String userId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from("blocks").insert({
      "blocker_id": user.id,
      "blocked_id": userId,
      "created_at": DateTime.now().toIso8601String(),
    });
  }

  // ======================
  // REPORT COMMENT
  // ======================
  Future<void> reportComment(String commentId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from("reports").insert({
      "comment_id": commentId,
      "reporter_id": user.id,
      "created_at": DateTime.now().toIso8601String(),
    });
  }

  // ======================
  // UPDATE COMMENTS COUNT
  // ======================
  Future<void> updateCommentsCount(String postId) async {
    final all = await supabase
        .from("comments")
        .select()
        .eq("post_id", postId);

    await supabase
        .from("posts")
        .update({
          "comments": all.length,
        })
        .eq("id", postId);
  }
}