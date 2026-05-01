import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aorandra/shared/controllers/like_controller.dart';
import 'package:aorandra/shared/services/follow_service.dart';
import 'package:aorandra/shared/services/user_manager.dart';
import 'package:aorandra/shared/widgets/glass_button.dart';
import 'package:aorandra/features/comments/ui/comments_screen.dart';

// ════════════════════════════════════════════════════════════
// HEART COLOR CONTROLLER
// ════════════════════════════════════════════════════════════
class HeartColorController extends GetxController {
  static const List<Color> palette = [
    Color(0xFFFF3B30),
    Color(0xFF007AFF),
    Color(0xFFBF5AF2),
    Color(0xFFFFCC00),
    Color(0xFF34C759),
  ];

  final Rx<Color> color = const Color(0xFFFF3B30).obs;

  void select(Color c) => color.value = c;

  void showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Obx(
        () => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Heart Color',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: palette.map((c) {
                    final selected = color.value == c;
                    return GestureDetector(
                      onTap: () {
                        select(c);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: selected ? 48 : 40,
                        height: selected ? 48 : 40,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// DOUBLE-TAP LIKE ANIMATION
// ════════════════════════════════════════════════════════════
class DoubleTapLikeAnimation extends StatefulWidget {
  final bool visible;
  final Color color;
  final VoidCallback onComplete;

  const DoubleTapLikeAnimation({
    super.key,
    required this.visible,
    required this.color,
    required this.onComplete,
  });

  @override
  State<DoubleTapLikeAnimation> createState() => _DoubleTapLikeAnimationState();
}

class _DoubleTapLikeAnimationState extends State<DoubleTapLikeAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _scale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
      TweenSequenceItem(
        tween:
            Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_ctrl);
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_ctrl);

    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onComplete();
    });
  }

  @override
  void didUpdateWidget(DoubleTapLikeAnimation old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && !_ctrl.isAnimating) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Icon(
                Icons.favorite,
                color: widget.color,
                size: 110,
                shadows: const [
                  Shadow(color: Colors.black45, blurRadius: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// RIGHT ACTIONS
// ════════════════════════════════════════════════════════════
class AorisRightActions extends StatelessWidget {
  final Map<String, dynamic> video;
  final bool isMe;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onShare;
  final VoidCallback onRepost;
  final VoidCallback onOpenComments;
  final VoidCallback onThreeDots;
  final Future<int> Function(String) getSharesCount;

  const AorisRightActions({
    super.key,
    required this.video,
    required this.isMe,
    required this.isSaved,
    required this.onToggleSave,
    required this.onShare,
    required this.onRepost,
    required this.onOpenComments,
    required this.onThreeDots,
    required this.getSharesCount,
  });

  @override
  Widget build(BuildContext context) {
    final postId = video['id'].toString();
    final likeCtrl = Get.find<LikeController>();
    final heartCtrl = Get.find<HeartColorController>();

    return Positioned(
      right: 10,
      bottom: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── ⋯ Three dots ──────────────────────────
          GestureDetector(
            onTap: onThreeDots,
            child: const Icon(Icons.more_vert, color: Colors.white, size: 26),
          ),

          const SizedBox(height: 20),

          // ── ❤️ Like ──────────────────────────────
          GestureDetector(
            onTap: () {
              if (likeCtrl.loadingLikes.contains(postId)) return;
              likeCtrl.toggleLike(
                profileId: Supabase.instance.client.auth.currentUser!.id,
                postId: postId,
                ownerId: video['profile_id'].toString(),
              );
            },
            onLongPress: () => heartCtrl.showPicker(context),
            child: Obx(() {
              final isLiked = likeCtrl.likedPosts[postId] == true;
              final count = likeCtrl.likesCount[postId] ?? 0;
              return Column(
                children: [
                  Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? heartCtrl.color.value : Colors.white,
                    size: 26,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              );
            }),
          ),

          const SizedBox(height: 14),

          // ── 💬 Comments ───────────────────────────
          GestureDetector(
            onTap: onOpenComments,
            child: Column(
              children: [
                const Icon(Icons.mode_comment_outlined,
                    color: Colors.white, size: 26),
                const SizedBox(height: 4),
                FutureBuilder(
                  future: Supabase.instance.client
                      .from('comments')
                      .select()
                      .eq('post_id', postId),
                  builder: (_, snapshot) {
                    final count =
                        snapshot.hasData ? (snapshot.data as List).length : 0;
                    return Text(
                      '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── 🔁 Repost (not mine) ──────────────────
          if (!isMe) ...[
            GestureDetector(
              onTap: onRepost,
              child: Column(
                children: [
                  const Icon(Icons.repeat, color: Colors.white, size: 26),
                  const SizedBox(height: 4),
                  Text(
                    '${video['reposts_count'] ?? 0}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── 📤 Share ──────────────────────────────
          GestureDetector(
            onTap: onShare,
            child: Column(
              children: [
                const Icon(Icons.send_rounded, color: Colors.white, size: 26),
                const SizedBox(height: 4),
                FutureBuilder<int>(
                  future: getSharesCount(postId),
                  builder: (_, snapshot) {
                    final shares = snapshot.data ?? 0;
                    return Text(
                      '$shares',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── 🔖 Save ───────────────────────────────
          GestureDetector(
            onTap: onToggleSave,
            child: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved
                  ? const Color.fromARGB(255, 155, 7, 39)
                  : Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// BOTTOM INFO
// ════════════════════════════════════════════════════════════
class AorisBottomInfo extends StatelessWidget {
  final Map<String, dynamic> video;
  final bool isMe;

  const AorisBottomInfo({
    super.key,
    required this.video,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final ownerId = video['profile_id']?.toString() ?? '';
    final followService = FollowService.instance;
    final userManager = UserManager.instance;

    if (ownerId.isNotEmpty) {
      userManager.fetchAndCache(ownerId);
      if (!isMe) followService.primeUser(ownerId);
    }

    return Positioned(
      left: 16,
      right: 88,
      bottom: 56,
      child: AnimatedBuilder(
        animation: Listenable.merge([userManager, followService]),
        builder: (context, _) {
          final username = userManager.getUsername(ownerId);
          final avatar = userManager.getAvatar(ownerId);
          final isFollowing = followService.followStateOf(ownerId);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1.2,
                      ),
                      image: avatar.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(avatar),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: avatar.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (!isMe)
                    GlassButton(
                      text: isFollowing ? 'Following' : 'Follow',
                      isActive: isFollowing,
                      isLoading: followService.isToggling(ownerId),
                      width: 70,
                      height: 24,
                      fontSize: 10,
                      onPressed: followService.isToggling(ownerId)
                          ? null
                          : () => followService.toggleFollow(ownerId),
                    )
                  else
                    const SizedBox(width: 70),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                video['description']?.toString() ??
                    video['caption']?.toString() ??
                    '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// MUSIC VINYL  (self-contained animation)
// ════════════════════════════════════════════════════════════
class AorisMusicVinyl extends StatefulWidget {
  final Map<String, dynamic> video;

  const AorisMusicVinyl({super.key, required this.video});

  @override
  State<AorisMusicVinyl> createState() => _AorisMusicVinylState();
}

class _AorisMusicVinylState extends State<AorisMusicVinyl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicImage = widget.video['music_image']?.toString();

    return Positioned(
      right: 16,
      bottom: 40,
      child: SizedBox(
        width: 60,
        height: 60,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Transform.rotate(
            angle: _ctrl.value * math.pi * 2,
            child: child,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF232323),
                      Color(0xFF111111),
                      Colors.black,
                    ],
                  ),
                ),
              ),
              ...List.generate(4, (i) {
                final size = 40.0 - (i * 6);
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                );
              }),
              if (musicImage != null && musicImage.isNotEmpty)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(musicImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white54,
                    size: 18,
                  ),
                ),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// GRADIENT OVERLAYS
// ════════════════════════════════════════════════════════════
class AorisTopGradient extends StatelessWidget {
  const AorisTopGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 180,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}

class AorisBottomGradient extends StatelessWidget {
  const AorisBottomGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 240,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// THREE DOTS MENU
// ════════════════════════════════════════════════════════════
void showAorisMenu({
  required BuildContext context,
  required bool isMe,
  required VoidCallback onDelete,
  VoidCallback? onReport,
  VoidCallback? onNotInterested,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1C1C1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          if (isMe) ...[
            _aorisMenuTile(
              context,
              'Delete',
              Icons.delete_outline,
              Colors.redAccent,
              onDelete,
            ),
            _aorisMenuTile(
              context,
              'Edit',
              Icons.edit_outlined,
              Colors.white,
              () => Navigator.pop(context),
            ),
            _aorisMenuTile(
              context,
              'Copy Link',
              Icons.link,
              Colors.white,
              () => Navigator.pop(context),
            ),
          ] else ...[
            _aorisMenuTile(
              context,
              'Report',
              Icons.flag_outlined,
              Colors.redAccent,
              onReport ?? () => Navigator.pop(context),
            ),
            _aorisMenuTile(
              context,
              'Not Interested',
              Icons.do_not_disturb_alt_outlined,
              Colors.white,
              onNotInterested ?? () => Navigator.pop(context),
            ),
            _aorisMenuTile(
              context,
              'Copy Link',
              Icons.link,
              Colors.white,
              () => Navigator.pop(context),
            ),
          ],
          const Divider(color: Colors.white12, height: 1),
          _aorisMenuTile(
            context,
            'Cancel',
            Icons.close,
            Colors.white54,
            () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Widget _aorisMenuTile(
  BuildContext context,
  String label,
  IconData icon,
  Color color,
  VoidCallback onTap,
) {
  return ListTile(
    leading: Icon(icon, color: color),
    title: Text(label, style: TextStyle(color: color, fontSize: 15)),
    onTap: onTap,
  );
}

// ════════════════════════════════════════════════════════════
// COMMENTS SHEET HELPER
// ════════════════════════════════════════════════════════════
Future<void> openAorisComments(BuildContext context, dynamic postId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      snap: true,
      snapSizes: const [0.65, 0.95],
      builder: (_, scrollController) => CommentsScreen(
        postId: postId,
        scrollController: scrollController,
      ),
    ),
  );
}
