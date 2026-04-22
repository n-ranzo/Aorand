import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// FEED UI
import 'package:aorandra/features/home/widgets/feed_widget.dart';

// CONTROLLERS & SERVICES
import 'package:aorandra/controller/like_controller.dart';
import 'package:aorandra/shared/services/user_manager.dart';

/// =============================================
/// PROFILE FEED SCREEN
/// Displays full feed like Instagram when opening a post from profile
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

  // ================= CONTROLLERS =================
  final ScrollController _scrollController = ScrollController();

  final LikeController likeController = Get.find();

  // ================= STATE =================
  final Map<String, bool> likedPosts = {};
  final Map<String, bool> savedPosts = {};
  final Map<String, int> likesCount = {};
  final Map<String, int> commentsCount = {};
  final Map<String, bool> followingUsers = {};

  final Map<String, PageController> pageControllers = {};
  final Map<String, ValueNotifier<int>> pageIndexes = {};

  @override
void initState() {
  super.initState();

  Future.delayed(const Duration(milliseconds: 300), () {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(widget.initialIndex * 500);
    }
  });
}

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [

          /// ================= FEED =================
          FeedWidget(
            postsFuture: Future.value(widget.posts),
            scrollController: _scrollController,

            likedPosts: likedPosts,
            savePosts: savedPosts,
            likesCount: likesCount,
            commentsCount: commentsCount,
            followingUsers: followingUsers,

            pageControllers: pageControllers,
            pageIndexes: pageIndexes,

            /// ================= ACTIONS =================

            onRefresh: () async {},

            onLoadComments: () {},

            onLike: (post) async {
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId == null) return;

              likeController.toggleLike(
                profileId: userId,
                postId: post['id'],
                ownerId: post['profile_id'],
              );
            },

            onSave: (postId) async {
              savedPosts[postId] = !(savedPosts[postId] ?? false);
              setState(() {});
            },

            onOpenComments: (postId) async {
              // TODO: open comments screen
            },

            onShare: (post) {
              // TODO: share logic
            },

            onOpenProfile: (username, userId) {
              // TODO: open profile
            },

            onOpenMenu: (postId, userId, caption) {
              _showPostMenu(postId);
            },

            onFollow: (userId) async {
              followingUsers[userId] = !(followingUsers[userId] ?? false);
              setState(() {});
            },
          ),

          /// ================= HEADER =================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                ),
                child: Row(
                  children: [

                    /// BACK BUTTON
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back,
                        color: theme.iconTheme.color,
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// TITLE + USERNAME
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Posts",
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.username,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= POST MENU =================
  void _showPostMenu(String postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              _menuItem("Report"),
              _menuItem("Copy Link"),
              _menuItem("Delete", isDanger: true),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// ================= MENU ITEM =================
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