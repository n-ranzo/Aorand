import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aorandra/features/home/widgets/feed_item.dart';
import 'package:aorandra/shared/controllers/like_controller.dart';
import 'package:aorandra/shared/services/follow_service.dart';
import 'package:aorandra/shared/services/user_manager.dart';

/// =============================================
/// PROFILE FEED SCREEN
/// Vertical scrolling feed — opens when tapping a post from the profile grid
/// =============================================
class ProfileFeedScreen extends StatefulWidget {
  final List<dynamic> posts;
  final int initialIndex;
  final String username;

  const ProfileFeedScreen({
    super.key,
    required this.posts,
    required this.initialIndex,
    required this.username,
  });

  @override
  State<ProfileFeedScreen> createState() => _ProfileFeedScreenState();
}

class _ProfileFeedScreenState extends State<ProfileFeedScreen> {
  late final ScrollController _scrollController;
  late final LikeController _likeController;
  late final String _ownerUserId;

  final Map<String, bool> _savedPosts = {};

  @override
  void initState() {
    super.initState();
    _likeController = Get.find<LikeController>();
    _scrollController = ScrollController();
    _ownerUserId = widget.posts.isNotEmpty
        ? (widget.posts.first['profile_id']?.toString() ?? '')
        : '';

    _loadLikeStates();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitial());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadLikeStates() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    final seenOwners = <String>{};

    for (final raw in widget.posts) {
      final post = Map<String, dynamic>.from(raw);
      final postId = post['id']?.toString() ?? '';
      final ownerId = post['profile_id']?.toString() ?? '';

      if (postId.isEmpty) continue;

      if (_likeController.likesCount[postId] == null) {
        _likeController.loadLikeState(profileId: currentUserId, postId: postId);
        _likeController.loadLikesCount(postId);
      }

      if (ownerId.isNotEmpty && seenOwners.add(ownerId)) {
        UserManager.instance.fetchAndCache(ownerId);
      }
    }

    FollowService.instance.primeUsers(seenOwners);
  }

  void _scrollToInitial() {
    if (!_scrollController.hasClients || widget.initialIndex == 0) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final estimatedPostHeight = (screenWidth * 5 / 4) + 120;
    _scrollController.jumpTo(widget.initialIndex * estimatedPostHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// ================= FEED =================
          ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 56,
              bottom: 32,
            ),
            itemCount: widget.posts.length,
            itemBuilder: (context, index) {
              final post = Map<String, dynamic>.from(widget.posts[index]);
              final postId = post['id']?.toString() ?? '';
              final userId = post['profile_id']?.toString() ?? '';

              if (postId.isEmpty || userId.isEmpty)
                return const SizedBox.shrink();

              return FeedItem(
                post: post,
                savedPosts: _savedPosts,
                onOpenMenu: (postId, userId, caption) => _showPostMenu(postId),
                onOpenProfile: (username, userId) {},
                onOpenComments: (postId) async {},
                onShare: (post) {},
                onSave: (postId) async {
                  setState(() {
                    _savedPosts[postId] = !(_savedPosts[postId] ?? false);
                  });
                },
              );
            },
          ),

          /// ================= HEADER =================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 4,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Posts',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AnimatedBuilder(
                animation: UserManager.instance,
                builder: (_, __) => Text(
                  UserManager.instance.getUsername(_ownerUserId),
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPostMenu(String postId) {
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
            _menuItem('Report'),
            _menuItem('Copy Link'),
            _menuItem('Delete', isDanger: true),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(String text, {bool isDanger = false}) {
    return ListTile(
      title: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isDanger ? Colors.red : Colors.white,
            fontSize: 16,
          ),
        ),
      ),
      onTap: () => Navigator.pop(context),
    );
  }
}
