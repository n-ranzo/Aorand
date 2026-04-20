// ============================
// PREVIEW SCREEN
// Shows media before editing/upload
// ============================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../shared/services/upload_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_screen.dart';

class PreviewScreen extends StatefulWidget {
  final List<File> videos;
  final String type; // "post" or "story"

  const PreviewScreen({
    super.key,
    required this.videos,
    required this.type,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  VideoPlayerController? _controller;
  int currentIndex = 0;
  bool isVideo = true;
  bool isLoading = false;

  // ============================
  // INIT
  // ============================

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  // ============================
  // LOAD MEDIA (IMAGE / VIDEO)
  // ============================

  void _loadMedia() {
    // Dispose old controller before loading new media
    _controller?.dispose();

    final file = widget.videos[currentIndex];

    // Detect if file is video
    isVideo = file.path.endsWith(".mp4");

    if (isVideo) {
      // Initialize video player
      _controller = VideoPlayerController.file(file)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _controller!.play(); // Auto play
            _controller!.setLooping(true); // Loop video
          }
        });
    } else {
      // Just rebuild for image
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ============================
  // CHANGE MEDIA
  // ============================

  void _changeMedia(int index) {
    setState(() {
      currentIndex = index;
    });
    _loadMedia();
  }

  // ============================
  // MEDIA VIEW (MAIN FIX)
  // ============================

  Widget _buildMedia() {
    final file = widget.videos[currentIndex];

    // ============================
    // Build media widget (video/image)
    // ============================
    final media = isVideo
        ? (_controller != null && _controller!.value.isInitialized)
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              )
            : const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
        : Image.file(
            file,
            fit: BoxFit.cover,
          );

    // ============================
    // POST MODE (4:5 + centered)
    // ============================
    if (widget.type == "post") {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 100),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: media,
            ),
          ),
        ),
      );
    }

    // ============================
    // STORY MODE (fullscreen)
    // ============================
    return Positioned.fill(child: media);
  }

  // ============================
  // UPLOAD FUNCTION
  // ============================

  // ignore: unused_element
  Future<void> _upload() async {
  setState(() => isLoading = true);

  try {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    // Ensure user is logged in
    if (user == null) throw Exception("User not logged in");

    final userId = user.id;

    // ============================
    // FETCH USER FROM PROFILES (FIXED)
    // ============================
    final userData = await supabase
        .from('profiles') 
        .select('username, avatar_url') 
        .eq('id', userId)
        .single();

    final username = userData['username'] ?? "User";
    final userImage = userData['avatar_url'] ?? ""; 

    List<String> uploadedUrls = [];

    // ============================
    // UPLOAD FILES
    // ============================
    for (var file in widget.videos) {
      final url = await UploadService.uploadFile(file, userId);
      uploadedUrls.add(url);
    }

    print("TYPE: ${widget.type}");

    // ============================
    // STORY
    // ============================
    if (widget.type == "story") {
      for (var url in uploadedUrls) {
        await supabase.from("stories").insert({
          "profile_id": userId,
          "media_url": url,
          "created_at": DateTime.now().toIso8601String(),
          "username": username,
          "avatar_url": userImage,
          "viewers": [],
        });
      }
    }

    // ============================
    // AORIS
    // ============================
    else if (widget.type == "aoris") {
      for (var url in uploadedUrls) {
        await supabase.from("aoris").insert({
          "profile_id": userId,
          "media_url": url,
          "created_at": DateTime.now().toIso8601String(),
        });
      }
    }

    // ============================
    // POST
    // ============================
    else if (widget.type == "post") {
      await supabase.from("posts").insert({
        "profile_id": userId,
        "media_url": uploadedUrls.first,
        "media_urls": uploadedUrls,
        "type": "post",
      });
    }

    // ============================
    // UNKNOWN TYPE
    // ============================
    else {
      throw Exception("Unknown type: ${widget.type}");
    }

    Navigator.pop(context);

  } catch (e) {
    print("UPLOAD ERROR: $e");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Upload Failed \n$e")),
    );
  }

  if (mounted) setState(() => isLoading = false);
}

  // ============================
  // UI
  // ============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ============================
          // MEDIA DISPLAY
          // ============================
          _buildMedia(),

          // ============================
          // CLOSE BUTTON
          // ============================
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          // ============================
          // NEXT BUTTON (GO TO EDIT)
          // ============================
          Positioned(
            bottom: 40,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditScreen(
                      videos: widget.videos,
                      type: widget.type,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Text(
                      "Next",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, color: Colors.black),
                  ],
                ),
              ),
            ),
          ),

          // ============================
          // MEDIA THUMBNAILS LIST
          // ============================
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.videos.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _changeMedia(index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 60,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: currentIndex == index
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.videocam,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}