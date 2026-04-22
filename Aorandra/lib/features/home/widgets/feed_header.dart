import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aorandra/shared/services/user_manager.dart';
import 'package:aorandra/shared/widgets/glass_button.dart';
import 'package:aorandra/core/widgets/time_text.dart';

/// =============================================
/// FEED HEADER WIDGET
/// =============================================
class FeedHeader extends StatelessWidget {
  final Map<String, dynamic> post;

  final VoidCallback? onMenu;
  final VoidCallback? onFollow;
  final VoidCallback? onOpenProfile;

  final bool isFollowing;

  const FeedHeader({
    super.key,
    required this.post,
    this.onMenu,
    this.onFollow,
    this.onOpenProfile,
    this.isFollowing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final userId = post['profile_id']?.toString() ?? '';
    final username = UserManager.instance.getUsername(userId);
    final avatar = UserManager.instance.getAvatar(userId);

    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [

          /// 👤 AVATAR
          GestureDetector(
            onTap: onOpenProfile,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: theme.dividerColor.withOpacity(0.2),
              backgroundImage:
                  avatar.isNotEmpty ? NetworkImage(avatar) : null,
            ),
          ),

          const SizedBox(width: 10),

          /// 👤 USERNAME + TIME
          GestureDetector(
            onTap: onOpenProfile,
            child: Row(
              children: [

                /// Username
                Text(
                  username,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(width: 6),

                /// 🔵 Verification (future)
                // Icon(Icons.verified, size: 16, color: Colors.blue),

                const SizedBox(width: 6),

                /// 🕒 TIME
                TimeText(
                  date: post['created_at'],
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color
                        ?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          /// ➕ FOLLOW
          if (currentUserId != userId)
            GlassButton(
              text: isFollowing ? "Following" : "Follow",
              isActive: isFollowing,
              width: 70,
              height: 24,
              fontSize: 10,
              onPressed: onFollow,
            ),

          const SizedBox(width: 8),

          /// ⋯ MENU
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              color: theme.iconTheme.color,
            ),
            onPressed: onMenu,
          ),
        ],
      ),
    );
  }
}