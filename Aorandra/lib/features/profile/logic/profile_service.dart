import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// =============================================
/// PROFILE SERVICE
/// Handles image picking, storage uploading, and 
/// database updates for the user profile.
/// =============================================
class ProfileService {
  final _supabase = Supabase.instance.client;

  /// Picks an image from gallery, uploads it, and updates the profile table.
  Future<void> updateProfilePicture(BuildContext context) async {
    final picker = ImagePicker();
    
    // 1. Pick an image from gallery
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50, // To reduce file size for faster upload
    );

    if (image == null) return;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      
      // Creating a unique filename using timestamp
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      // 2. Upload the file to Supabase Storage (Bucket name: 'avatars')
      await _supabase.storage.from('avatars').upload(filePath, file);

      // 3. Generate the public URL
      final String publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      // 4. Update the 'profiles' table with the new URL
      await _supabase.from('profiles').update({
        'avatar_url': publicUrl,
      }).eq('id', user.id);

      // Success feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
      
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}