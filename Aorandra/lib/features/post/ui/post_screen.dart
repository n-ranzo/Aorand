import 'package:flutter/material.dart';

class PostScreen extends StatelessWidget {

  // ---------------------------------------------------------
  // Data
  // ---------------------------------------------------------
  final Map<String, dynamic> postData;

  // ---------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------
  const PostScreen({
    super.key,
    required this.postData,
  });

  // ---------------------------------------------------------
  // UI
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {

    // Safe data extraction
    final String title = postData['title']?.toString() ?? '';
    final String mediaUrl = postData['media_url']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Column(
          children: [

            // Back button
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            const SizedBox(height: 10),

            // Media (Image / Video later)
            if (mediaUrl.isNotEmpty)
              Expanded(
                child: Image.network(
                  mediaUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),

            const SizedBox(height: 10),

            // Title / Caption
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}