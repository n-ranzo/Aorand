import 'package:get/get.dart';

import 'package:aorandra/shared/controllers/like_controller.dart';
import 'package:flutter/material.dart';

import 'widgets/video_item.dart';
import 'widgets/aoris_overlay_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aorandra/shared/services/follow_service.dart';
import 'package:aorandra/shared/services/user_manager.dart';

class AorisScreen extends StatefulWidget {
  final List<String> videos;
  final Function(Map videos) onShare;

  const AorisScreen({
    super.key,
    required this.videos,
    required this.onShare,
  });

  @override
  State<AorisScreen> createState() => _AorisScreenState();
}

class _AorisScreenState extends State<AorisScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  late final AnimationController _floatingController;
  late final HeartColorController _heartColorCtrl;

  // ── State ────────────────────────────────────────
  Set<String> savedVideo = {};
  List<Map<String, dynamic>> videos = [];
  bool isLoading = true;
  bool _showLikeAnim = false;

  // ── Lifecycle ────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    if (!Get.isRegistered<HeartColorController>()) {
      Get.put(HeartColorController());
    }
    _heartColorCtrl = Get.find<HeartColorController>();

    loadVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────

  Future<void> loadVideos() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    final videoData = await supabase
        .from('posts')
        .select()
        .eq('type', 'aoris')
        .order('created_at', ascending: false);

    setState(() {
      videos = List<Map<String, dynamic>>.from(videoData);
      isLoading = false;
    });

    final likeController = Get.find<LikeController>();
    for (var video in videos) {
      final postId = video['id'].toString();
      if (likeController.likesCount[postId] == null) {
        likeController.loadLikeState(profileId: userId, postId: postId);
        likeController.loadLikesCount(postId);
      }
    }

    FollowService.instance.primeUsers(
      videos
          .map((video) => video['profile_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty),
    );
  }

  Future<void> refreshFeed() async {
    setState(() => isLoading = true);
    await loadVideos();
  }

  Future<int> _getSharesCount(String videoId) async {
    final data = await Supabase.instance.client
        .from('messages')
        .select('id')
        .eq('post_id', videoId);
    return data.length;
  }

  void _handleDoubleTap(Map<String, dynamic> video) {
    final postId = video['id'].toString();
    final likeCtrl = Get.find<LikeController>();
    if (likeCtrl.likedPosts[postId] != true) {
      likeCtrl.toggleLike(
        profileId: Supabase.instance.client.auth.currentUser!.id,
        postId: postId,
        ownerId: video['profile_id'].toString(),
      );
    }
    setState(() => _showLikeAnim = true);
  }

  Future<void> _deletePost(Map<String, dynamic> video) async {
    Navigator.pop(context);
    final postId = video['id']?.toString() ?? '';
    if (postId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this video?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await Supabase.instance.client.from('posts').delete().eq('id', postId);
      await loadVideos();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (videos.isEmpty)
            const Center(
              child: Text(
                'No videos yet',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: videos.length,
              onPageChanged: (index) => setState(() {
                _currentIndex = index;
                _showLikeAnim = false;
              }),
              itemBuilder: (context, index) {
                final video = videos[index];
                final postId = video['id']?.toString() ?? '';
                final ownerId = video['profile_id']?.toString() ?? '';
                final isMe =
                    ownerId == Supabase.instance.client.auth.currentUser!.id;
                final isActive = index == _currentIndex;

                return Stack(
                  children: [
                    VideoItem(
                      file: video['media_url'],
                      isActive: isActive,
                      onDoubleTap: () => _handleDoubleTap(video),
                    ),
                    const AorisTopGradient(),
                    const AorisBottomGradient(),
                    Obx(() => DoubleTapLikeAnimation(
                          visible: _showLikeAnim && isActive,
                          color: _heartColorCtrl.color.value,
                          onComplete: () =>
                              setState(() => _showLikeAnim = false),
                        )),
                    AorisRightActions(
                      video: video,
                      isMe: isMe,
                      isSaved: savedVideo.contains(postId),
                      onToggleSave: () => setState(() {
                        savedVideo.contains(postId)
                            ? savedVideo.remove(postId)
                            : savedVideo.add(postId);
                      }),
                      onShare: () => widget.onShare(video),
                      onRepost: () {},
                      onOpenComments: () =>
                          openAorisComments(context, video['id']),
                      onThreeDots: () => showAorisMenu(
                        context: context,
                        isMe: isMe,
                        onDelete: () => _deletePost(video),
                      ),
                      getSharesCount: _getSharesCount,
                    ),
                    AorisBottomInfo(
                      video: video,
                      isMe: isMe,
                    ),
                    AorisMusicVinyl(video: video),
                  ],
                );
              },
            ),
          _buildTopBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        children: [
          GestureDetector(
            onTap: refreshFeed,
            child: const Icon(Icons.refresh, color: Colors.white, size: 26),
          ),
          const Spacer(),
          const Text(
            'Aoris',
            style: TextStyle(
              fontFamily: 'PacificoFont',
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child:
                const Icon(Icons.tune_rounded, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}
