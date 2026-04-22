import 'package:supabase_flutter/supabase_flutter.dart';

class ShareService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> sendPost({
    required String senderId,
    required String postId,
    required Set<String> users,
    required String message,
  }) async {
    // Validation
    if (senderId.isEmpty) {
      print("senderId is empty");
      return;
    }

    if (postId.isEmpty) {
      print("postId is empty");
      return;
    }

    if (users.isEmpty) {
      print("users list is empty");
      return;
    }

    try {
      print("Starting share...");
      print("Sender: $senderId");
      print("Post: $postId");
      print("Users: $users");

      for (final receiverId in users) {
        final response = await supabase
            .from('messages')
            .insert({
              'sender_id': senderId,
              'receiver_id': receiverId,
              'post_id': postId,
              'text': message,
              'created_at': DateTime.now().toIso8601String(),
            })
            .select();

        print("Sent to: $receiverId");
        print("DB response: $response");
      }

      print("Share completed");
    } catch (e) {
      print("Share error: $e");
    }
  }
}