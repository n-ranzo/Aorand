import 'package:flutter/material.dart';
import 'feed_header.dart';
import 'feed_media.dart';
import 'feed_actions.dart';
import 'feed_caption.dart';

class FeedItem extends StatelessWidget {
  final Map<String, dynamic> post;

  /// HEADER callbacks
  final void Function(String postId, String userId, String caption) onOpenMenu;
  final void Function(String userId) onFollow;
  final void Function(String username, String userId) onOpenProfile;

  /// ACTIONS callbacks
  final void Function(String postId) onOpenComments;
  final void Function(Map<String, dynamic> post) onShare;

  /// 🔥 NEW (SAVE)
  final void Function(String postId) onSave;
  final Map<String, bool> savedPosts;

  final Map<String, bool> followingUsers;

  const FeedItem({
    super.key,
    required this.post,
    required this.onOpenMenu,
    required this.onFollow,
    required this.onOpenProfile,
    required this.onOpenComments,
    required this.onShare,
    required this.onSave,
    required this.savedPosts,
    required this.followingUsers,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> mediaList =
        post['media_urls'] is List ? post['media_urls'] : [];

    final userId = post['profile_id']?.toString() ?? '';
    final postId = post['id']?.toString() ?? '';
    final caption = post['caption'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// ================= HEADER =================
        FeedHeader(
          post: post,
          onMenu: () => onOpenMenu(postId, userId, caption),
          onFollow: () => onFollow(userId),
          onOpenProfile: () =>
              onOpenProfile(post['username'] ?? '', userId),
          isFollowing: followingUsers[userId] == true,
        ),

        /// ================= MEDIA =================
        FeedMedia(mediaList: mediaList),

        const SizedBox(height: 10),

        /// ================= ACTIONS =================
        FeedActions(
          post: post,
          onOpenComments: onOpenComments,
          onShare: onShare,

          /// 🔥 NEW
          onSave: onSave,
          savedPosts: savedPosts,
        ),

        const SizedBox(height: 6),

        /// ================= CAPTION =================
        FeedCaption(post: post),

        const SizedBox(height: 12),
      ],
    );
  }
}