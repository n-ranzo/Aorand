import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// ===============================================
/// VIDEO ITEM (TikTok / Reels Style)
/// ===============================================
/// Features:
/// - Tap to pause / play
/// - Center pause indicator
/// - Mute / unmute button
/// - Auto play when active
/// - Loop video
/// ===============================================

class VideoItem extends StatefulWidget {
  final String file;
  final bool isActive;

  const VideoItem({
    super.key,
    required this.file,
    required this.isActive,
  });

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  late VideoPlayerController _controller;

  bool isPaused = false;
  bool isMuted = false;

  // ===============================================
  // INIT
  // ===============================================
  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.file))
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);

        if (widget.isActive) {
          _controller.play();
        }
      });
  }

  // ===============================================
  // HANDLE PAGE CHANGE (Play / Pause)
  // ===============================================
  @override
  void didUpdateWidget(covariant VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive) {
      _controller.play();
      isPaused = false;
    } else {
      _controller.pause();
    }
  }

  // ===============================================
  // TOGGLE PLAY / PAUSE
  // ===============================================
  void togglePause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      isPaused = true;
    } else {
      _controller.play();
      isPaused = false;
    }
    setState(() {});
  }

  // ===============================================
  // TOGGLE MUTE
  // ===============================================
  void toggleMute() {
    isMuted = !isMuted;
    _controller.setVolume(isMuted ? 0 : 1);
    setState(() {});
  }

  // ===============================================
  // DISPOSE
  // ===============================================
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ===============================================
  // BUILD UI
  // ===============================================
  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return GestureDetector(
      onTap: togglePause,
      child: Stack(
        alignment: Alignment.center,
        children: [

          // =====================================
          // VIDEO PLAYER
          // =====================================
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),

          // =====================================
          // CONTROLS (PAUSE + MUTE)
          // =====================================
          if (isPaused)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ▶️ PLAY BUTTON
                GestureDetector(
                  onTap: togglePause,
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 20),

                // 🔊 MUTE BUTTON
                GestureDetector(
                  onTap: toggleMute,
                  child: Icon(
                    isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}