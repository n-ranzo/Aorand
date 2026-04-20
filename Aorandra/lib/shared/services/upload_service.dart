import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadService {

  // ============================
  // Upload file to Supabase Storage
  // ============================
  /// Uploads any file and returns public URL
  static Future<String> uploadFile(File file, String userId) async {
    final supabase = Supabase.instance.client;

    try {
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}_$userId";

      final extension = file.path.split('.').last.toLowerCase();

      final path = 'media/$userId/$fileName.$extension';

      String contentType;
      if (extension == 'mp4') {
        contentType = 'video/mp4';
      } else if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        contentType = 'image/jpeg';
      } else {
        contentType = 'application/octet-stream';
      }

      await supabase.storage.from('media').upload(
        path,
        file,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );

      final url = supabase.storage.from('media').getPublicUrl(path);

      print("UPLOAD SUCCESS: $url");

      return url;

    } catch (e) {
      print("UPLOAD ERROR: $e");
      rethrow;
    }
  }

  // ============================
  // POST (Feed)
  // ============================
  /// Upload normal post (image or video feed)
  static Future<void> uploadPost(File file, String caption) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      print("User not logged in");
      return;
    }

    try {
      final mediaUrl = await uploadFile(file, user.id);

      await supabase.from('posts').insert({
        'profile_id': user.id,
        'media_urls': [mediaUrl], // important: list
        'caption': caption,
        'type': 'post',
        'created_at': DateTime.now().toIso8601String(),
      });

      print("POST UPLOADED SUCCESS");

    } catch (e) {
      print("POST UPLOAD ERROR: $e");
    }
  }

  // ============================
  // STORY
  // ============================
  /// Upload story (24h content)
  static Future<void> uploadStory(File file) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      print("User not logged in");
      return;
    }

    try {
      final mediaUrl = await uploadFile(file, user.id);

      await supabase.from('stories').insert({
        'userid': user.id,
        'mediaUrl': mediaUrl,
        'username': user.userMetadata?['username'] ?? 'User',
        'userimage': user.userMetadata?['avatar_url'] ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'viewers': [],
      });

      print("STORY SAVED SUCCESS");

    } catch (e) {
      print("STORY SAVE ERROR: $e");
    }
  }

  // ============================
  // AORIS (Reels)
  // ============================
  /// Upload short video (Reels / TikTok style)
  static Future<void> uploadAoris(File file, String description) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      print("User not logged in");
      return;
    }

    try {
      final videoUrl = await uploadFile(file, user.id);

      await supabase.from('aoris').insert({
        'profile_id': user.id,
        'media_url': videoUrl,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
      });

      print("AORIS UPLOADED SUCCESS");

    } catch (e) {
      print("AORIS UPLOAD ERROR: $e");
    }
  }
}