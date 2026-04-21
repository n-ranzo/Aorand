import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aorandra/features/home/logic/home_controller.dart';
import 'package:aorandra/shared/services/user_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:aorandra/core/widgets/time_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/widgets/glass_button.dart';

/// =============================================
/// FEED WIDGET
/// Displays list of posts (like Instagram/TikTok feed)
/// Handles UI only (no business logic)
/// =============================================
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

 
  // ================= PAGE CONTROL =================
  final Map<String, PageController> pageControllers;
  final Map<String, ValueNotifier<int>> pageIndexes;


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


  // ================= UTIL =================

    const FeedWidget({
    super.key,
    required this.postsFuture,
    required this.scrollController,
    required this.likedPosts,
    required this.savePosts,
    required this.likesCount,
    required this.commentsCount,
    required this.pageControllers,
    required this.pageIndexes,
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
  final theme = Theme.of(context);

  return Positioned.fill(
    child: FutureBuilder<List<dynamic>>(
      future: postsFuture,
      builder: (context, snapshot) {

        // ================= LOADING STATE =================
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ================= ERROR STATE =================
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading feed'));
        }

        final posts = snapshot.data ?? [];

        // ================= EMPTY STATE =================
        if (posts.isEmpty) {
          return const Center(child: Text("No posts"));
        }

        // ================= LAYOUT CALCULATIONS =================
        final width = MediaQuery.of(context).size.width;
        final height = width / (4 / 5); // aspect ratio 4:5

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

                  // ================= USER DATA =================
                  final userId = post['profile_id']?.toString() ?? '';
                  final postId = post['id']?.toString() ?? '';

                  final username =
                      UserManager.instance.getUsername(userId);
                  final avatar =
                      UserManager.instance.getAvatar(userId);

                  final currentUserId =
                      Supabase.instance.client.auth.currentUser?.id;

                  // Skip invalid posts
                  if (userId.isEmpty || postId.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // ================= MEDIA =================
                  final List<dynamic> mediaList =
                 post['media_urls'] is List ? post['media_urls'] : [];

                  final controller = pageControllers.putIfAbsent(
                    postId,
                    () => PageController(),
                  );

                  final currentPage = pageIndexes.putIfAbsent(
                    postId,
                    () => ValueNotifier<int>(0),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ================= HEADER =================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: theme.dividerColor.withOpacity(0.2),
                              backgroundImage: avatar.isNotEmpty
                                  ? NetworkImage(avatar)
                                  : null,
                            ),

                            const SizedBox(width: 10),

                           GestureDetector(
                             onTap: () => onOpenProfile(username, userId),
                             child: Row(
                               children: [
                                 Text(
                                   username,
                                   style: TextStyle(
                                     color: theme.textTheme.bodyLarge?.color,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),

                                const SizedBox(width: 6),

                                TimeText(
                                  date: post['created_at'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                             ),
                           ),

                            const Spacer(),

                          Row(
                             children: [

                              /// FOLLOW BUTTON
                              if (currentUserId != userId)
                                GlassButton(
                                  text: followingUsers[userId] == true ? "Following" : "Follow",
                                  isActive: followingUsers[userId] == true,

                                  width: 70,
                                  height: 24,
                                  fontSize: 10,

                                  onPressed: () => onFollow(userId),
                                ),

                               const SizedBox(width: 8),

                              /// MENU BUTTON
                              IconButton(
                                icon: Icon(Icons.more_horiz,
                                    color: theme.iconTheme.color),
                                onPressed: () => onOpenMenu(
                                  postId,
                                  userId,
                                  post['caption'] ?? '',
                               ),
                             ),
                           ],
                         )
                       ],
                     ),
                   ),

                      // ================= MEDIA =================
                      SizedBox(
                        width: width,
                        height: height,
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: controller,
                              itemCount: mediaList.length,
                              onPageChanged: (i) => currentPage.value = i,
                              itemBuilder: (context, i) {
                                final url = mediaList[i].toString().toLowerCase();
                                final isVideo = url.endsWith('.mp4') || url.endsWith('.mov');

                                if (isVideo) {
                                  return _FeedVideoPlayer(url: mediaList[i].toString());
                                }

                                return CachedNetworkImage(
                                   imageUrl: mediaList[i],
                                   fit: BoxFit.cover,
                                   placeholder: (context, url) =>
                                       Container(color: Colors.black12),
                                   errorWidget: (context, url, error) =>
                                       const Icon(Icons.error),
                                );
                              },
                            ),

                            if (mediaList.length > 1)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: ValueListenableBuilder<int>(
                                  valueListenable: currentPage,
                                  builder: (_, page, __) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${page + 1}/${mediaList.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ================= ACTIONS =================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [

                            /// LIKE
                           GestureDetector(
                             onTap: () => onLike(post),
                             child: Row(
                               children: [
                                 Icon(
                                   likedPosts[postId] == true
                                       ? Icons.favorite
                                       : Icons.favorite_border,
                                   color: likedPosts[postId] == true
                                       ? Colors.red
                                       : theme.iconTheme.color,
                               ),
                               const SizedBox(width: 5),
                               Text(
                                 '${likesCount[postId] ?? post['likes'] ?? 0}',
                                 style: TextStyle(
                                   color: theme.textTheme.bodyMedium?.color,
                                 ),
                               ),
                             ],
                           ),
                         ),

                            const SizedBox(width: 14),

                            /// COMMENT
                            GestureDetector(
                              onTap: () async {
                                await onOpenComments(postId);
                                onLoadComments();
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.mode_comment_outlined,
                                      color: theme.iconTheme.color),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${commentsCount[postId] ?? 0}',
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 14),

                            /// SHARE
                            GestureDetector(
                              onTap: () => onShare(post),
                              child: Row(
                                children: [
                                  Icon(Icons.send,
                                      color: theme.iconTheme.color),
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

                            const Spacer(),

                            /// SAVE
                            GestureDetector(
                              onTap: () => onSave(postId),
                              child: Icon(
                                savePosts[postId] == true
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: theme.iconTheme.color,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ================= LIKES COUNT =================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${likesCount[postId] ?? post['likes'] ?? 0} likes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),

                      // ================= CAPTION =================
                      if ((post['caption'] ?? '').toString().trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: RichText(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$username ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                TextSpan(
                                  text: post['caption'],
                                  style: TextStyle(
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 4),
                    ],
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
class _FeedVideoPlayer extends StatefulWidget {
  final String url;

  const _FeedVideoPlayer({required this.url});

  @override
  State<_FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<_FeedVideoPlayer> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        _controller!.setLooping(true);
        _controller!.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

 bool isMuted = true;
bool isPaused = false;

@override
Widget build(BuildContext context) {
  // Show loader while video is initializing
  if (_controller == null || !_controller!.value.isInitialized) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  return GestureDetector(
    // Toggle play/pause on tap
    onTap: () {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        isPaused = true;
      } else {
        _controller!.play();
        isPaused = false;
      }
      setState(() {});
    },

    child: Stack(
      alignment: Alignment.center,
      children: [

        // Video fills entire container (fix skinny issue)
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),

        // Play icon overlay (clean, no circle)
        if (isPaused)
          const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 80,
          ),

        // Mute / unmute button (soft dark background like Instagram)
        Positioned(
          bottom: 14,
          right: 8,
          child: GestureDetector(
            onTap: () {
              if (isMuted) {
                _controller!.setVolume(1);
                isMuted = false;
              } else {
                _controller!.setVolume(0);
                isMuted = true;
              }
              setState(() {});
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25), // 👈 خفيف جداً
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}