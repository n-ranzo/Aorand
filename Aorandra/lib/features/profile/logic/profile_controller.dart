import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/profile_service.dart';

class ProfileController extends GetxController {

  final supabase = Supabase.instance.client;

  /// ================================
  /// STATE
  /// ================================

  /// User data
  final RxMap<String, dynamic> user = <String, dynamic>{}.obs;

  /// Image posts
  final RxList<Map<String, dynamic>> posts = <Map<String, dynamic>>[].obs;

  /// Video posts (Aoris)
  final RxList<Map<String, dynamic>> videos = <Map<String, dynamic>>[].obs;

  /// Loading state
  final RxBool isLoading = true.obs;

  /// Current tab index
  final RxInt currentTab = 0.obs;


  /// ================================
  /// LOAD PROFILE
  /// ================================
  Future<void> loadProfile(String userId) async {
    try {
      isLoading.value = true;

      final userData = await ProfileService.getUser(userId);
      final postData = await ProfileService.getPosts(userId);
      final videoData = await ProfileService.getVideos(userId);

      user.value = userData;
      posts.value = postData;
      videos.value = videoData;

    } catch (e) {
      print("Profile load error: $e");
    }

    isLoading.value = false;
  }


  /// ================================
  /// REFRESH PROFILE
  /// ================================
  Future<void> refreshProfile(String userId) async {
    await loadProfile(userId);
  }


  /// ================================
  /// FOLLOW USER
  /// ================================
  Future<void> follow({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      await ProfileService.followUser(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );

      /// Update UI instantly
      user['followers'] = (user['followers'] ?? 0) + 1;

    } catch (e) {
      print("Follow error: $e");
    }
  }


  /// ================================
  /// UNFOLLOW USER
  /// ================================
  Future<void> unfollow({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      await ProfileService.unfollowUser(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );

      /// Update UI instantly
      user['followers'] =
          ((user['followers'] ?? 0) - 1).clamp(0, 999999);

    } catch (e) {
      print("Unfollow error: $e");
    }
  }


  /// ================================
  /// CHECK IF FOLLOWING
  /// ================================
  bool isFollowing(String currentUserId) {
    final followersList = user['followersList'] ?? [];
    return followersList.contains(currentUserId);
  }


  /// ================================
  /// CHANGE TAB
  /// ================================
  void changeTab(int index) {
    currentTab.value = index;
  }


  /// ================================
  /// CLEAR DATA (on logout)
  /// ================================
  void clearProfile() {
    user.clear();
    posts.clear();
    videos.clear();
    isLoading.value = true;
    currentTab.value = 0;
  }
}