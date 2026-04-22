import 'package:flutter/material.dart';
import 'package:aorandra/shared/services/user_manager.dart';

/// =============================================
/// FEED CAPTION WIDGET
/// - Username + caption
/// - Expand / collapse (like Instagram)
/// =============================================
class FeedCaption extends StatefulWidget {
  final Map<String, dynamic> post;

  const FeedCaption({
    super.key,
    required this.post,
  });

  @override
  State<FeedCaption> createState() => _FeedCaptionState();
}

class _FeedCaptionState extends State<FeedCaption> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final userId = widget.post['profile_id']?.toString() ?? '';
    final username = UserManager.instance.getUsername(userId);

    final caption = widget.post['caption'] ?? '';

    /// ❌ إذا ما في كابشن لا تعرض شي
    if (caption.toString().trim().isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            isExpanded = !isExpanded;
          });
        },
        child: RichText(
          maxLines: isExpanded ? null : 2,
          overflow:
              isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          text: TextSpan(
            children: [

              /// 👤 USERNAME
              TextSpan(
                text: '$username ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),

              /// 📝 CAPTION
              TextSpan(
                text: caption,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),

              /// 🔥 "more / less"
              if (caption.length > 80)
                TextSpan(
                  text: isExpanded ? '  less' : '... more',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}