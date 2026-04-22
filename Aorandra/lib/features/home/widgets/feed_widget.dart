import 'package:aorandra/features/home/widgets/feed_item.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:aorandra/features/home/logic/home_controller.dart';
import 'package:aorandra/shared/services/user_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aorandra/shared/controllers/like_controller.dart';

class FeedWidget extends StatelessWidget {
  // ================= DATA =================
  final Future<List<dynamic>> postsFuture;
  final ScrollController scrollController;

  // ================= STATE =================
  final Map<String, bool> likedPosts;
  final Map<String, bool> savePosts;
  final Map<String, int> likesCount;
  final Map<String, int> commentsCount;
  final Map<String, bool> followingUsers;

  // ================= ACTIONS =================
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadComments;

  final Future<void> Function(String userId) onFollow;
  final Future<void> Function(Map<String, dynamic> post) onLike;
  final Future<void> Function(String postId) onSave;
  final Future<void> Function(String postId) onOpenComments;
  final void Function(Map<String, dynamic> post) onShare;
  final void Function(String username, String userId) onOpenProfile;
  final void Function(String postId, String userId, String caption) onOpenMenu;

  const FeedWidget({
    super.key,
    required this.postsFuture,
    required this.scrollController,
    required this.likedPosts,
    required this.savePosts,
    required this.likesCount,
    required this.commentsCount,
    required this.onRefresh,
    required this.onLoadComments,
    required this.onLike,
    required this.onSave,
    required this.onOpenComments,
    required this.onShare,
    required this.onOpenProfile,
    required this.onOpenMenu,
    required this.onFollow,
    required this.followingUsers,
  });

  @override
  Widget build(BuildContext context) {
    final likeController = Get.find<LikeController>();

    return Positioned.fill(
      child: FutureBuilder<List<dynamic>>(
        future: postsFuture,
        builder: (context, snapshot) {

          /// ================= LOADING =================
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// ================= ERROR =================
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading feed'));
          }

          final posts = snapshot.data ?? [];

          /// ================= EMPTY =================
          if (posts.isEmpty) {
            return const Center(child: Text("No posts"));
          }

          return AnimatedBuilder(
            animation: UserManager.instance,
            builder: (context, _) {

              return RefreshIndicator(
                onRefresh: onRefresh,
                color: Colors.white,
                backgroundColor: Colors.black,
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    top: HomeController.headerTop + 80,
                    bottom: 120,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {

                    final post = Map<String, dynamic>.from(posts[index]);

                    final userId = post['profile_id']?.toString() ?? '';
                    final postId = post['id']?.toString() ?? '';

                    final currentUserId =
                        Supabase.instance.client.auth.currentUser?.id;

                    /// Skip invalid posts
                    if (userId.isEmpty || postId.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    /// Load like state once
                    if (currentUserId != null &&
                        likeController.likesCount[postId] == null) {

                      likeController.loadLikeState(
                        profileId: currentUserId,
                        postId: postId,
                      );

                      likeController.loadLikesCount(postId);
                    }

                    /// ================= FEED ITEM =================
                    return FeedItem(
                      post: post,

                      onOpenMenu: onOpenMenu,
                      onFollow: onFollow,
                      onOpenProfile: onOpenProfile,

                      onOpenComments: (postId) async {
                        await onOpenComments(postId);
                        onLoadComments();
                      },

                      onShare: onShare,

                      /// 🔥 SAVE
                      onSave: onSave,
                      savedPosts: savePosts,

                      followingUsers: followingUsers,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}