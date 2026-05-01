import 'package:flutter/material.dart';
import 'feed_header.dart';
import 'feed_media.dart';
import 'feed_actions.dart';
import 'feed_caption.dart';

class FeedItem extends StatelessWidget {
  final Map<String, dynamic> post;

  /// HEADER callbacks
  final void Function(String postId, String userId, String caption) onOpenMenu;
  final void Function(String username, String userId) onOpenProfile;

  /// ACTIONS callbacks
  final void Function(String postId) onOpenComments;
  final void Function(Map<String, dynamic> post) onShare;

  /// 🔥 NEW (SAVE)
  final void Function(String postId) onSave;
  final Map<String, bool> savedPosts;

  const FeedItem({
    super.key,
    required this.post,
    required this.onOpenMenu,
    required this.onOpenProfile,
    required this.onOpenComments,
    required this.onShare,
    required this.onSave,
    required this.savedPosts,
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
          onOpenProfile: () => onOpenProfile(post['username'] ?? '', userId),
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
