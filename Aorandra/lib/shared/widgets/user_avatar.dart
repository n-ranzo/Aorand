import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aorandra/shared/services/user_manager.dart';

/// =============================================
/// USER AVATAR (FINAL VERSION - USER MANAGER)
/// Fast + Cached + Realtime via UserManager
/// =============================================
class UserAvatar extends StatelessWidget {
  final String userId;
  final double radius;

  const UserAvatar({
    super.key,
    required this.userId,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double size = radius * 2;

    // حماية
    if (userId.isEmpty) {
      return _buildDefaultAvatar(theme, size);
    }

    return AnimatedBuilder(
      animation: UserManager.instance,
      builder: (context, _) {
        final avatar = UserManager.instance.getAvatar(userId);

        // ================= NO AVATAR =================
        if (avatar.isEmpty) {
          return _buildDefaultAvatar(theme, size);
        }

        // ================= IMAGE =================
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatar,
            width: size,
            height: size,
            fit: BoxFit.cover,

            useOldImageOnUrlChange: false,

            placeholder: (context, url) => Container(
              width: size,
              height: size,
              color: theme.dividerColor.withOpacity(0.1),
            ),

            errorWidget: (context, url, error) =>
                _buildDefaultAvatar(theme, size),
          ),
        );
      },
    );
  }

  /// ================= DEFAULT AVATAR =================
  Widget _buildDefaultAvatar(ThemeData theme, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.dividerColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: theme.iconTheme.color?.withOpacity(0.5),
      ),
    );
  }
}