import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/services/upload_service.dart';

class EditScreen extends StatefulWidget {
  final List<File>? videos;
  final List<File>? images;
  final String type;

  const EditScreen({
    super.key,
    this.videos,
    this.images,
    required this.type,
  });

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  VideoPlayerController? _controller;

  int currentIndex = 0;
  bool isVideo = false;
  bool isLoading = false;

  late List<File> media;

  final TextEditingController captionController = TextEditingController();

  String selectedMusic = '';
  String selectedFilter = 'None';

  bool get isPostMode => widget.type == "post";
  bool get isStoryMode => widget.type == "story";
  bool get isAorisMode => widget.type == "aoris";

  @override
void initState() {
  super.initState();

  media = [
    ...?widget.images,
    ...?widget.videos,
  ];

  _loadMedia();
}

  void _loadMedia() {
    if (media.isEmpty) return;

  _controller?.dispose();
  _controller = null;

  final file = media[currentIndex];

  isVideo =
      file.path.toLowerCase().contains(".mp4") ||
      file.path.toLowerCase().contains(".mov");

  if (isVideo) {
    _controller = VideoPlayerController.file(file)
      ..initialize().then((_) {
        if (!mounted) return;
        _controller!.setLooping(true);
        _controller!.play();
        setState(() {});
      });
  } else {
    if (mounted) setState(() {});
  }
}

  void _changeMedia(int index) {
    if (index == currentIndex) return;
    setState(() {
      currentIndex = index;
    });
    _loadMedia();
  }

  @override
  void dispose() {
    _controller?.dispose();
    captionController.dispose();
    super.dispose();
  }

Future<void> _uploadFinalPost() async {
  // ============================
  // Start loading state
  // ============================
  setState(() => isLoading = true);

  try {
    // ============================
    // Initialize Supabase client
    // ============================
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    // ============================
    // Check if user is logged in
    // ============================
    if (user == null) {
      throw Exception("User not logged in");
    }

    final userId = user.id;

    // ============================
    // Fetch user data from database
    // ============================
    final userData = await supabase
        .from('profiles') 
        .select('username, avatar_url') 
        .eq('id', userId)
        .single();

    // ============================
    // Extract username & avatar
    // ============================
    final username = userData['username'] ?? "User";
    final userImage = userData['avatar_url'] ?? ""; 

    // ============================
    // Upload all selected media
    // ============================
    final List<String> uploadedUrls = [];

    for (final file in media) {
      // Validate file existence
      if (!file.existsSync()) {
        throw Exception("File not found: ${file.path}");
      }

      // Upload file and store URL
      final url = await UploadService.uploadFile(file, userId);
      uploadedUrls.add(url);
    }

    // ============================
    // STORY MODE
    // ============================
    if (isStoryMode) {
      for (final url in uploadedUrls) {
        await supabase.from("stories").insert({
          "profile_id": userId,
          "media_url": url,
          "created_at": DateTime.now().toUtc().toIso8601String(),
          "username": username,
          "avatar_url": userImage,
          "viewers": [],
        });
      }
    }

    // ============================
    // AORIS MODE
    // ============================
    else if (isAorisMode) {
      for (final url in uploadedUrls) {
        await supabase.from("aoris").insert({
          "profile_id": userId,
          "media_url": url,
          "created_at": DateTime.now().toUtc().toIso8601String(),
        });
      }
    }

    // ============================
    // ✅ POST MODE
    // ============================
    else {
      await supabase.from("posts").insert({
        "profile_id": userId,
        "media_url": uploadedUrls.first, // First media (cover)
        "media_urls": uploadedUrls,      // All media
        "caption": captionController.text.trim(),
        "music": selectedMusic,
        "filter": selectedFilter,
        "type": "post", // Important for filtering posts later
        "created_at": DateTime.now().toUtc().toIso8601String(),
      });
    }

    // ============================
    // Show success message
    // ============================
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isStoryMode
              ? "Story uploaded"
              : isAorisMode
                  ? "Aoris uploaded"
                  : "Post uploaded",
        ),
      ),
    );

    // ============================
    // Navigate back to home
    // ============================
    Navigator.popUntil(context, (route) => route.isFirst);

  } catch (e) {
    // ============================
    // Error handling
    // ============================
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Upload failed\n$e")),
    );
  }

  // ============================
  // Stop loading state
  // ============================
  if (mounted) {
    setState(() => isLoading = false);
  }
}

  Widget _glassCard({
    required Widget child,
    double radius = 24,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _topCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _glassCard(
        radius: 100,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  Widget _toolButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          _glassCard(
            radius: 22,
            child: SizedBox(
              width: 74,
              height: 74,
              child: Icon(
                icon,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    final file = media[currentIndex];

    return _glassCard(
      radius: 28,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: AspectRatio(
          aspectRatio: isPostMode ? 4 / 5 : 9 / 16,
          child: isVideo
              ? (_controller != null && _controller!.value.isInitialized)
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller!.value.size.width,
                            height: _controller!.value.size.height,
                            child: VideoPlayer(_controller!),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: _glassCard(
                            radius: 20,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: const Text(
                              "VIDEO",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      file,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _glassCard(
                        radius: 20,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: const Text(
                          "PHOTO",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMediaCounter() {
    if (!isPostMode || media.length <= 1) {
      return const SizedBox();
    }

    return _glassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        "${currentIndex + 1}/${media.length}",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildThumbnails() {
    if (!isPostMode || media.length <= 1) {
      return const SizedBox();
    }

    return SizedBox(
      height: 84,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: media.length,
        itemBuilder: (context, index) {
          final file = media[index];
          final thumbIsVideo = 
          file.path.toLowerCase().contains(".mp4") ||
          file.path.toLowerCase().contains(".mov");
          final isActive = currentIndex == index;

          return GestureDetector(
            onTap: () => _changeMedia(index),
            child: Container(
              width: 62,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.10),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    thumbIsVideo
                        ? Container(
                            color: Colors.white.withValues(alpha: 0.06),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 26,
                            ),
                          )
                        : Image.file(file, fit: BoxFit.cover),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCaptionField() {
    if (!isPostMode) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: _glassCard(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: TextField(
          controller: captionController,
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: "Add a caption...",
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTools() {

  // ================= STORY =================
  if (isStoryMode) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _toolButton(Icons.music_note, "Audio", () {
            setState(() => selectedMusic = "Story audio");
          }),
          const SizedBox(width: 14),
          _toolButton(Icons.text_fields, "Text", () {}),
          const SizedBox(width: 14),
          _toolButton(Icons.auto_fix_high, "Sticker", () {}),
          const SizedBox(width: 14),
          _toolButton(Icons.filter, "Filter", () {
            setState(() => selectedFilter = "Story Filter");
          }),
          const SizedBox(width: 14),
          _toolButton(Icons.brush_outlined, "Draw", () {}),
        ],
      ),
    );
  }

  // ================= AORIS =================
  else if (isAorisMode) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _toolButton(Icons.music_note, "Audio", () {
            setState(() => selectedMusic = "Aoris audio");
          }),
          const SizedBox(width: 14),
          _toolButton(Icons.text_fields, "Text", () {}),
          const SizedBox(width: 14),
          _toolButton(Icons.filter, "Filter", () {
            setState(() => selectedFilter = "Aoris Filter");
          }),
          const SizedBox(width: 14),
          _toolButton(Icons.speed, "Speed", () {}), 
          const SizedBox(width: 14),
          _toolButton(Icons.cut, "Trim", () {}), 
        ],
      ),
    );
  }

  // ================= POST =================
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Row(
      children: [
        _toolButton(Icons.music_note, "Audio", () {
          setState(() => selectedMusic = "Selected audio");
        }),
        const SizedBox(width: 14),
        _toolButton(Icons.text_fields, "Text", () {}),
        const SizedBox(width: 14),
        _toolButton(Icons.layers, "Overlay", () {}),
        const SizedBox(width: 14),
        _toolButton(Icons.filter, "Filter", () {
          setState(() => selectedFilter = "Cool Filter");
        }),
        const SizedBox(width: 14),
        _toolButton(Icons.tune, "Adjust", () {}),
      ],
    ),
  );
}

  Widget _buildModeBadge() {
    final text = isPostMode ? "POST EDIT" : "STORY EDIT";

    return _glassCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06090F),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _topCircleButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  _buildModeBadge(),
                  const Spacer(),
                  GestureDetector(
                    onTap: isLoading ? null : _uploadFinalPost,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF5663FF),
                            Color(0xFF4051FF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              children: [
                                Text(
                                  "Share",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward, color: Colors.white),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: _buildMediaPreview(),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: _buildMediaCounter(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            _buildThumbnails(),

            if (isPostMode) const SizedBox(height: 14),

            _buildCaptionField(),

            SizedBox(height: isPostMode ? 18 : 12),

            _buildTools(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}