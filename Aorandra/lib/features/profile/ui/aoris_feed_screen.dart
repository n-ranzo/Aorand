import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import 'package:aorandra/shared/controllers/like_controller.dart';
import 'package:aorandra/shared/services/follow_service.dart';
import 'package:aorandra/features/aoris/ui/widgets/aoris_overlay_widgets.dart';

class AorisFeedScreen extends StatefulWidget {
  final List<Map<String, dynamic>> videos;
  final int initialIndex;

  const AorisFeedScreen({
    super.key,
    required this.videos,
    required this.initialIndex,
  });

  @override
  State<AorisFeedScreen> createState() => _AorisFeedScreenState();
}

class _AorisFeedScreenState extends State<AorisFeedScreen> {
  late final PageController _pageController;
  late final LikeController _likeController;
  late final HeartColorController _heartColorCtrl;
  late int _currentIndex;

  final Set<String> _savedVideos = {};
  late final String _currentUserId;

  bool _showLikeAnim = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _likeController = Get.find<LikeController>();

    if (!Get.isRegistered<HeartColorController>()) {
      Get.put(HeartColorController());
    }
    _heartColorCtrl = Get.find<HeartColorController>();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    for (final video in widget.videos) {
      final postId = video['id']?.toString() ?? '';
      if (postId.isEmpty) continue;
      if (_likeController.likesCount[postId] == null) {
        _likeController.loadLikeState(
            profileId: _currentUserId, postId: postId);
        _likeController.loadLikesCount(postId);
      }
    }

    FollowService.instance.primeUsers(
      widget.videos
          .map((video) => video['profile_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _resolveUrl(Map<String, dynamic> item) {
    final mediaList = item['media_urls'];
    if (mediaList is List && mediaList.isNotEmpty) {
      return mediaList.first.toString();
    }
    return item['media_url']?.toString() ?? '';
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
    if (_likeController.likedPosts[postId] != true) {
      _likeController.toggleLike(
        profileId: _currentUserId,
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
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.videos.length,
        onPageChanged: (i) => setState(() {
          _currentIndex = i;
          _showLikeAnim = false;
        }),
        itemBuilder: (context, index) {
          final video = widget.videos[index];
          final postId = video['id']?.toString() ?? '';
          final ownerId = video['profile_id']?.toString() ?? '';
          final isMe = ownerId == _currentUserId;
          final isActive = index == _currentIndex;

          return Stack(
            fit: StackFit.expand,
            children: [
              _AorisItem(
                videoUrl: _resolveUrl(video),
                isActive: isActive,
                onDoubleTap: () => _handleDoubleTap(video),
              ),
              const AorisTopGradient(),
              const AorisBottomGradient(),
              Obx(() => DoubleTapLikeAnimation(
                    visible: _showLikeAnim && isActive,
                    color: _heartColorCtrl.color.value,
                    onComplete: () => setState(() => _showLikeAnim = false),
                  )),
              AorisRightActions(
                video: video,
                isMe: isMe,
                isSaved: _savedVideos.contains(postId),
                onToggleSave: () => setState(() {
                  _savedVideos.contains(postId)
                      ? _savedVideos.remove(postId)
                      : _savedVideos.add(postId);
                }),
                onShare: () {},
                onRepost: () {},
                onOpenComments: () => openAorisComments(context, video['id']),
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
              _buildBackButton(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPad + 8,
      left: 12,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: const BoxDecoration(
            color: Colors.black38,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ─── Video item with double-tap support ──────────────────────────────────────

class _AorisItem extends StatefulWidget {
  final String videoUrl;
  final bool isActive;
  final VoidCallback onDoubleTap;

  const _AorisItem({
    required this.videoUrl,
    required this.isActive,
    required this.onDoubleTap,
  });

  @override
  State<_AorisItem> createState() => _AorisItemState();
}

class _AorisItemState extends State<_AorisItem> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    if (widget.videoUrl.isEmpty) return;
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _ctrl = ctrl;
    try {
      await ctrl.initialize();
      ctrl.setLooping(true);
      if (mounted) {
        setState(() => _initialized = true);
        if (widget.isActive) ctrl.play();
      }
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  void didUpdateWidget(_AorisItem old) {
    super.didUpdateWidget(old);
    if (old.isActive == widget.isActive) return;
    if (widget.isActive) {
      _paused = false;
      _ctrl?.play();
    } else {
      _ctrl?.pause();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _togglePause() {
    if (_ctrl == null || !_initialized) return;
    setState(() {
      _paused = !_paused;
      _paused ? _ctrl!.pause() : _ctrl!.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePause,
      onDoubleTap: widget.onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_initialized && _ctrl != null)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _ctrl!.value.size.width,
                height: _ctrl!.value.size.height,
                child: VideoPlayer(_ctrl!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                  color: Colors.white54, strokeWidth: 2),
            ),
          if (_paused)
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pause, color: Colors.white, size: 48),
              ),
            ),
        ],
      ),
    );
  }
}
