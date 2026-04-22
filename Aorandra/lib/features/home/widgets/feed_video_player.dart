import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FeedVideoPlayer extends StatefulWidget {
  final String url;

  const FeedVideoPlayer({super.key, required this.url});

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  VideoPlayerController? _controller;

  bool isMuted = true;
  bool isPaused = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;

        _controller!
          ..setLooping(true)
          ..setVolume(0)
          ..play();

        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Loading
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GestureDetector(
      /// Play / Pause
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

          /// VIDEO
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

          /// PLAY ICON
          if (isPaused)
            const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 80,
            ),

          /// MUTE BUTTON
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
                  color: Colors.black.withOpacity(0.25),
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