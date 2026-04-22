import 'package:flutter/material.dart';

class ProfilePostsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final int initialIndex;

  const ProfilePostsScreen({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<ProfilePostsScreen> createState() => _ProfilePostsScreenState();
}

class _ProfilePostsScreenState extends State<ProfilePostsScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      initialPage: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.posts.length,
        itemBuilder: (context, index) {
          final post = widget.posts[index];

          final List media = post['media_urls'] ?? [];

          final String? imageUrl =
              media.isNotEmpty ? media[0] : null;

          return Stack(
            children: [
              /// ================= MEDIA =================
              Positioned.fill(
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
              ),

              /// ================= GRADIENT =================
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              /// ================= BACK BUTTON =================
              Positioned(
                top: 50,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),

              /// ================= USER INFO =================
              Positioned(
                bottom: 40,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['username'] ?? 'user',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post['caption'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}