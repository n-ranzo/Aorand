import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoriesBar extends StatelessWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context) {
  final user = Supabase.instance.client.auth.currentUser;
  final supabase = Supabase.instance.client;

  return Container(
    width: 90,
    padding: const EdgeInsets.symmetric(vertical: 20),
    decoration: BoxDecoration(
      color: const Color(0xFF2A0000),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Column(
      children: [

        // =========================
        // MY STORY
        // =========================
        _myStory(user),

        const SizedBox(height: 20),

        // =========================
        // REAL USERS LIST (SUPABASE)
        // =========================
        Expanded(
          child: StreamBuilder(
            stream: supabase
                .from('profiles') 
                .stream(primaryKey: ['id']),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const SizedBox();
              }

              final users = snapshot.data as List<dynamic>;

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userData = users[index];

                  return _storyItem(
                    name: userData["username"] ?? "User",
                    imageUrl: userData["avatar_url"] ?? "", 
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
  // =========================
  // MY STORY
  // =========================
  Widget _myStory(User? user) {
    return Column(
      children: [
        Stack(
          children: [

            CircleAvatar(
              radius: 28,
              backgroundImage: user?.userMetadata?['avatar_url'] != null
                  ? NetworkImage(user!.userMetadata!['avatar_url'])
                  : null,
              backgroundColor: Colors.white,
            ),

            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black,
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add,
                    size: 10,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        const Text(
          "My Story",
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // =========================
  // STORY ITEM
  // =========================
  Widget _storyItem({
    required String name,
    required String imageUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [

          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF3A0000),
              backgroundImage:
                  imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}