import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoryScreen extends StatefulWidget {
  final List<String> stories;
  final int startIndex;
  final bool isMyStory;
  final String username;
  final String? userProfileImage;
  final String storyDocId;
  final List<Map<String, dynamic>> viewers;

  const StoryScreen({
    super.key,
    required this.stories,
    this.startIndex = 0,
    this.isMyStory = false,
    required this.username,
    this.userProfileImage,
    required this.storyDocId,
    required this.viewers,
  });

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final supabase = Supabase.instance.client;

  int currentIndex = 0;
  double progress = 0.0;
  Timer? timer;

  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();

    currentIndex =
        widget.startIndex.clamp(0, widget.stories.length - 1);

    _startProgress();
  }

  // ---------------- STORY TIMER ----------------
  void _startProgress() {
    timer?.cancel();
    progress = 0;

    timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      setState(() {
        progress += 0.01;

        if (progress >= 1) {
          _nextStory();
        }
      });
    });
  }

  void _nextStory() {
    if (!mounted) return;

    if (currentIndex < widget.stories.length - 1) {
      setState(() => currentIndex++);
      _startProgress();
    } else {
      timer?.cancel();

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  void _previousStory() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
      _startProgress();
    }
  }

  // ---------------- OPTIONS ----------------
  void _openStoryOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _optionItem("Delete story", Colors.red, _deleteStory),
              _optionItem("Archive", Colors.white, _archiveStory),
              _optionItem("Highlight", Colors.white, _highlightStory),
              _optionItem("Save", Colors.white, _saveStory),
              _optionItem("Story settings", Colors.white, _storySettings),
              const SizedBox(height: 10),
              _optionItem("Cancel", Colors.grey, () {
                Navigator.pop(context);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _optionItem(String text, Color color, VoidCallback onTap) {
    return ListTile(
      title: Center(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      onTap: onTap,
    );
  }

  // ---------------- ACTIONS ----------------
  void _deleteStory() async {
    Navigator.pop(context);

    try {
      await supabase
          .from('stories')
          .delete()
          .eq('id', widget.storyDocId);

      Navigator.pop(context);
    } catch (e) {
      print("DELETE ERROR: $e");
    }
  }

  void _archiveStory() async {
    Navigator.pop(context);

    try {
      await supabase
          .from('stories')
          .update({'archived': true})
          .eq('id', widget.storyDocId);
    } catch (e) {
      print("ARCHIVE ERROR: $e");
    }
  }

  void _highlightStory() {
    Navigator.pop(context);
    print("HIGHLIGHT");
  }

  void _saveStory() {
    Navigator.pop(context);
    print("SAVE: ${widget.stories[currentIndex]}");
  }

  void _storySettings() {
    Navigator.pop(context);
    print("SETTINGS");
  }

  // ---------------- BUILD UI ----------------
  @override
  Widget build(BuildContext context) {
    final storyUrl = widget.stories[currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => timer?.cancel(),
        onLongPressEnd: (_) => _startProgress(),
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;

          if (details.globalPosition.dx < width / 2) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        storyUrl,
                        fit: BoxFit.cover,
                        loadingBuilder:
                            (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;

                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder:
                            (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.white),
                          );
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),

              _buildHeader(),

              Positioned(
                bottom: 20,
                left: 10,
                right: 10,
                child: widget.isMyStory
                    ? _buildMyStoryActions()
                    : _buildViewerActions(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader() {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Column(
        children: [
          Row(
            children: List.generate(widget.stories.length, (index) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: index < currentIndex
                        ? 1
                        : (index == currentIndex ? progress : 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    widget.userProfileImage != null
                        ? NetworkImage(widget.userProfileImage!)
                        : null,
                backgroundColor: Colors.white24,
              ),
              const SizedBox(width: 8),
              Text(
                widget.username,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),

              if (widget.isMyStory)
                IconButton(
                  onPressed: _openStoryOptions,
                  icon: const Icon(Icons.more_vert,
                      color: Colors.white),
                ),

              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close,
                    color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- VIEWER ACTIONS ----------------
  Widget _buildViewerActions() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _replyController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Send message...",
              hintStyle: const TextStyle(color: Colors.white54),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide:
                    const BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide:
                    const BorderSide(color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: () {
            print("LIKE CLICKED");
          },
          icon: const Icon(Icons.favorite_border,
              color: Colors.white, size: 28),
        ),
      ],
    );
  }

  // ---------------- MY STORY ----------------
  Widget _buildMyStoryActions() {
    return GestureDetector(
      onTap: _openViewers,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            const Icon(Icons.remove_red_eye,
                color: Colors.white70),
            const SizedBox(width: 10),
            Text(
              "${widget.viewers.length} views",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_up,
                color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _openViewers() {
    timer?.cancel();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Viewers",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: ListView.builder(
                itemCount: widget.viewers.length,
                itemBuilder: (context, i) {
                  final viewer = widget.viewers[i];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage(viewer["image"] ?? ""),
                    ),
                    title: Text(
                      viewer["username"],
                      style:
                          const TextStyle(color: Colors.white),
                    ),
                    trailing: viewer["liked"] == true
                        ? const Icon(Icons.favorite,
                            color: Colors.red)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).then((value) => _startProgress());
  }

  @override
  void dispose() {
    timer?.cancel();
    _replyController.dispose();
    super.dispose();
  }
}