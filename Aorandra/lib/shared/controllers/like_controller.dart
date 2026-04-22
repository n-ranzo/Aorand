import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/interactions/like_service.dart';

/// ======================================================
/// LIKE CONTROLLER
/// ------------------------------------------------------
/// Handles:
/// - Global like state across app
/// - Likes count per post
/// - Optimistic UI updates
/// - Sync with backend (Supabase)
///
/// IMPORTANT:
/// - Single instance across app
/// - UI must NOT call Supabase directly
/// ======================================================
class LikeController extends GetxController {

  /// ================= STATE =================

  /// Map<postId, isLiked>
  final RxMap<String, bool> likedPosts = <String, bool>{}.obs;

  /// Map<postId, likesCount>
  final RxMap<String, int> likesCount = <String, int>{}.obs;

  /// Prevent spam tapping
  final RxSet<String> loadingLikes = <String>{}.obs;

  /// ================= LOAD SINGLE POST =================

  Future<void> loadLikeState({
    required String profileId,
    required String postId,
  }) async {
    try {
      final isLiked = await LikeService.isLiked(
        profileId: profileId,
        postId: postId,
      );

      likedPosts[postId] = isLiked;
    } catch (e) {
      debugPrint("Load like state error: $e");
    }
  }

  /// ================= LOAD COUNT =================

  Future<void> loadLikesCount(String postId) async {
    try {
      final count = await LikeService.getLikesCount(postId);
      likesCount[postId] = count;
    } catch (e) {
      debugPrint("Load likes count error: $e");
    }
  }

  /// ================= TOGGLE LIKE =================

  Future<void> toggleLike({
    required String profileId,
    required String postId,
    required String ownerId,
  }) async {

    /// Prevent double tapping
    if (loadingLikes.contains(postId)) return;
    loadingLikes.add(postId);

    final bool previousLiked = likedPosts[postId] ?? false;

    /// 🔥 OPTIMISTIC UI UPDATE
    likedPosts[postId] = !previousLiked;

    likesCount[postId] =
        (likesCount[postId] ?? 0) + (previousLiked ? -1 : 1);

    try {
      final result = await LikeService.toggleLike(
        profileId: profileId,
        postId: postId,
        ownerId: ownerId,
      );

      /// 🔥 SYNC WITH SERVER (important)
      if (result != likedPosts[postId]) {
        likedPosts[postId] = result;

        likesCount[postId] =
            (likesCount[postId] ?? 0) + (result ? 1 : -1);
      }

    } catch (e) {
      debugPrint("Toggle like error: $e");

      /// 🔁 ROLLBACK
      likedPosts[postId] = previousLiked;

      likesCount[postId] =
          (likesCount[postId] ?? 0) + (previousLiked ? 1 : -1);
    }

    loadingLikes.remove(postId);
  }

  /// ================= CLEAR CACHE =================

  void clearLikes() {
    likedPosts.clear();
    likesCount.clear();
    loadingLikes.clear();
  }
}