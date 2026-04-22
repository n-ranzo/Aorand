import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aorandra/shared/controllers/like_controller.dart';

/// =============================================
/// FEED ACTIONS WIDGET
/// =============================================
class FeedActions extends StatelessWidget {
  final Map<String, dynamic> post;

  final Function(String postId) onOpenComments;
  final Function(Map<String, dynamic> post) onShare;

  /// 🔥 NEW (SAVE)
  final Function(String postId) onSave;
  final Map<String, bool> savedPosts;

  const FeedActions({
    super.key,
    required this.post,
    required this.onOpenComments,
    required this.onShare,
    required this.onSave,
    required this.savedPosts,
  });

  @override
  Widget build(BuildContext context) {
    final likeController = Get.find<LikeController>();
    final theme = Theme.of(context);

    // ================= DATA =================
    final postId = post['id']?.toString() ?? '';
    final userId = post['profile_id']?.toString() ?? '';
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id;

    final isMyPost = currentUserId == userId;
    final isSaved = savedPosts[postId] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ================= ACTION ROW =================
          Row(
            children: [

              /// ❤️ LIKE
              GestureDetector(
                onTap: () {
                  if (currentUserId == null) return;

                  likeController.toggleLike(
                    profileId: currentUserId,
                    postId: postId,
                    ownerId: userId,
                  );
                },
                child: Obx(() => Row(
                  children: [
                    Icon(
                      likeController.likedPosts[postId] == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: likeController.likedPosts[postId] == true
                          ? Colors.red
                          : theme.iconTheme.color,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${likeController.likesCount[postId] ?? 0}',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                )),
              ),

              const SizedBox(width: 16),

              /// 💬 COMMENT
              GestureDetector(
                onTap: () => onOpenComments(postId),
                child: Row(
                  children: [
                    Icon(Icons.mode_comment_outlined,
                        color: theme.iconTheme.color),
                    const SizedBox(width: 5),
                    Text(
                      '${post['comments'] ?? 0}',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              /// 📤 SHARE
              GestureDetector(
                onTap: () => onShare(post),
                child: Row(
                  children: [
                    Icon(Icons.send, color: theme.iconTheme.color),
                    const SizedBox(width: 5),
                    Text(
                      '${post['shares'] ?? 0}',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              /// 🔁 REPOST (hidden for my posts)
              if (!isMyPost)
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: repost logic
                      },
                      child: Row(
                        children: [
                          Icon(Icons.repeat,
                              color: theme.iconTheme.color),
                          const SizedBox(width: 5),
                          Text(
                            '${post['reposts'] ?? 0}',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),

              const Spacer(),

              /// 🔖 SAVE (WORKING)
              GestureDetector(
                onTap: () => onSave(postId),
                child: Icon(
                  isSaved
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: theme.iconTheme.color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// 🔥 LIKES TEXT
          Obx(() {
            final count = likeController.likesCount[postId] ?? 0;

            return Text(
              '$count likes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            );
          }),
        ],
      ),
    );
  }
}