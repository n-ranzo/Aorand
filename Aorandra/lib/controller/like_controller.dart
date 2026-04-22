import 'package:get/get.dart';
import '../shared/services/like_service.dart';

/// ======================================================
/// LIKE CONTROLLER
/// ------------------------------------------------------
/// This controller is responsible for:
/// - Managing like state across the entire app
/// - Holding liked posts (true/false per post)
/// - Holding likes count per post
/// - Connecting UI with backend (LikeService)
///
/// IMPORTANT:
/// - This is a GLOBAL controller (one instance for whole app)
/// - UI should NEVER call Supabase directly
/// - UI only talks to this controller
/// ======================================================
class LikeController extends GetxController {

  /// ======================================================
  /// STATE
  /// ======================================================

  /// Map<postId, isLiked>
  final RxMap<String, bool> likedPosts = <String, bool>{}.obs;

  /// Map<postId, likesCount>
  final RxMap<String, int> likesCount = <String, int>{}.obs;

  /// Prevent spamming
  final RxSet<String> loadingLikes = <String>{}.obs;

  /// ======================================================
  /// LOAD SINGLE POST LIKE STATE
  /// ======================================================
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
      print("Error loading like state: $e");
    }
  }

  /// ======================================================
  /// LOAD LIKES COUNT
  /// ======================================================
  Future<void> loadLikesCount(String postId) async {
    try {
      final count = await LikeService.getLikesCount(postId);
      likesCount[postId] = count;
    } catch (e) {
      print("Error loading likes count: $e");
    }
  }

  /// ======================================================
  /// TOGGLE LIKE (Optimistic UI)
  /// ======================================================
  Future<void> toggleLike({
    required String profileId,
    required String postId,
    required String ownerId,
  }) async {

    if (loadingLikes.contains(postId)) return;
    loadingLikes.add(postId);

    final bool isLiked = likedPosts[postId] ?? false;

    /// 🔥 UI FIRST
    likedPosts[postId] = !isLiked;

    likesCount[postId] =
        (likesCount[postId] ?? 0) + (isLiked ? -1 : 1);

    try {
      final result = await LikeService.toggleLike(
        profileId: profileId,
        postId: postId,
        ownerId: ownerId,
      );

      /// 🔥 الحل الأساسي (منع الرجوع الأبيض)
      if (result != isLiked) {
        likedPosts[postId] = result;
      }

    } catch (e) {
      print("Toggle like error: $e");

      /// rollback
      likedPosts[postId] = isLiked;
      likesCount[postId] =
          (likesCount[postId] ?? 0) + (isLiked ? 1 : -1);
    }

    loadingLikes.remove(postId);
  }

  /// ======================================================
  /// CLEAR CACHE
  /// ======================================================
  void clearLikes() {
    likedPosts.clear();
    likesCount.clear();
    loadingLikes.clear(); 
  }
}