import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoryItem extends StatelessWidget {
  final String imageUrl;
  final String username;

  final bool isMe;
  final bool hasStory;
  final bool isViewed;

  const StoryItem({
    super.key,
    required this.imageUrl,
    required this.username,
    this.isMe = false,
    this.hasStory = false,
    this.isViewed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // ================= STORY AVATAR =================
        GestureDetector(
          onTap: () {
            print(username);
          },

          child: Stack(
            children: [

              // ================= NO STORY (YOU) =================
              if (isMe && !hasStory)
                _buildNoStory(),

              // ================= NORMAL STORY =================
              if (!isMe || hasStory)
                _buildStoryCircle(),

              // ================= ADD BUTTON =================
              if (isMe)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _buildAddButton(),
                ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // ================= USERNAME =================
        Text(
          username,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // ================= NO STORY =================
  Widget _buildNoStory() {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.grey.shade800,
      backgroundImage:
          imageUrl.isNotEmpty ? CachedNetworkImageProvider(imageUrl) : null,
      child: imageUrl.isEmpty
          ? const Icon(Icons.person, color: Colors.white)
          : null,
    );
  }

  // ================= STORY =================
  Widget _buildStoryCircle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,

        // viewed → gray border
        // not viewed → gradient border
        gradient: isViewed
            ? null
            : const SweepGradient(
                colors: [
                  Color.fromARGB(255, 204, 42, 99),
                  Color.fromARGB(255, 5, 116, 110),
                  Color.fromARGB(255, 4, 133, 94),
                  Color.fromARGB(255, 179, 121, 83),
                  Color.fromARGB(255, 170, 23, 126),
                  Color(0xFF3B024D),
                  Color(0xFF640221),
                ],
              ),
        border: isViewed
            ? Border.all(color: const Color(0xFF555555), width: 3)
            : null,
      ),

      child: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.black,
        child: CircleAvatar(
          radius: 27,
          backgroundImage:
              imageUrl.isNotEmpty ? CachedNetworkImageProvider(imageUrl) : null,
          child: imageUrl.isEmpty
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  // ================= ADD BUTTON =================
  Widget _buildAddButton() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.12),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.add,
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}