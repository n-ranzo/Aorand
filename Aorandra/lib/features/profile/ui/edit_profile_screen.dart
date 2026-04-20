// lib/screens/profile/edit_profile_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/glass_container.dart';
import 'package:aorandra/shared/services/user_manager.dart';

// ================================
// EDIT PROFILE SCREEN
// ================================

/// EditProfileScreen - Allows users to edit their profile information
/// 
/// Features:
/// - Profile image upload with Supabase storage
/// - Edit name, username, bio, and links
/// - Rate limiting for name (5 days) and username (10 days) changes
/// - Username availability checking
/// - Glassmorphism UI elements
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // ================================
  // SERVICES & CONTROLLERS
  // ================================

  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _linksController = TextEditingController();

  // ================================
  // STATE VARIABLES
  // ================================

  String? _imageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  // ================================
  // LIFECYCLE METHODS
  // ================================

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _linksController.dispose();
    super.dispose();
  }

  // ================================
  // DATA LOADING
  // ================================

  /// Load current user data from Supabase
 
Future<void> _loadUserData() async {
  try {
    // Get current user ID
    final userId = _supabase.auth.currentUser!.id;

    // ================= TRY CACHE FIRST =================
    final cachedUser = UserManager.instance.getUser(userId);

    if (cachedUser != null) {
      _applyUserData(cachedUser);
      
    }

    // ================= FETCH FROM DATABASE =================
    final data = await _supabase
        .from('profiles')
        .select('id, username, avatar_url, bio, links, name')
        .eq('id', userId)
        .maybeSingle();

    // If no data found, stop safely
    if (data == null) {
      debugPrint('User profile not found');
      return;
    }

    // ================= SAVE TO CACHE =================
    UserManager.instance.setUser(userId, data);

    // ================= APPLY DATA TO UI =================
    _applyUserData(data);

  } catch (e) {
    debugPrint('LOAD ERROR: $e');
  }
}



// ================= APPLY DATA =================
void _applyUserData(Map data) {
  _nameController.text = data['name'] ?? '';
  _usernameController.text = data['username'] ?? '';
  _bioController.text = data['bio'] ?? '';
  _linksController.text = data['links'] ?? '';
  _imageUrl = data['avatar_url'] ?? '';

  if (mounted) setState(() {});
}

  // ================================
  // IMAGE UPLOAD
  // ================================

  /// Allow user to select and upload a new profile image
  Future<void> _changeProfileImage() async {
    if (_isUploadingImage) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final file = File(picked.path);
      final userId = _supabase.auth.currentUser!.id;
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to Supabase Storage
      await _supabase.storage.from('avatars').upload(path, file);

      // Get public URL
      final url = _supabase.storage.from('avatars').getPublicUrl(path);

      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      debugPrint('UPLOAD ERROR: $e');

      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  // ================================
  // SAVE PROFILE
  // ================================

  /// Save all profile changes to Supabase
Future<void> _saveProfile() async {
  // Get current user ID
  final userId = _supabase.auth.currentUser!.id;

  // Prevent running if widget is disposed
  if (!mounted) return;

  // Show loading indicator
  setState(() => _isLoading = true);

  try {
    // ================= FETCH CURRENT USER DATA =================
    Map<String, dynamic>? data =
        UserManager.instance.getUser(userId);

    // If not cached → fetch from database
    if (data == null) {
      data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      // Save to cache
      UserManager.instance.setUser(userId, data);
    }

    // ================= PREPARE UPDATE OBJECT =================
    final updates = <String, dynamic>{
      'bio': _bioController.text.trim(),
      'links': _linksController.text.trim(),
      'avatar_url': _imageUrl,
    };

    final now = DateTime.now();

    // ================= HANDLE NAME UPDATE (NO LIMIT) =================
    if (_nameController.text.trim() != (data['name'] ?? '')) {
      // Allow empty name (null)
      updates['name'] = _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim();
    }

    // ================= HANDLE USERNAME UPDATE =================
    if (_usernameController.text.trim() != data['username']) {
      final lastChange = data['username_changed_at'];

      // Enforce 10-day cooldown (KEEP THIS)
      if (lastChange != null) {
        final lastDate = DateTime.parse(lastChange);
        final daysDiff = now.difference(lastDate).inDays;

        if (daysDiff < 10) {
          final remaining = 10 - daysDiff;
          _showSnackBar(
              'You can change your username after $remaining days');
          setState(() => _isLoading = false);
          return;
        }
      }

      final newUsername = _usernameController.text.trim();

      // Check if username is already taken
      final taken = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', newUsername)
          .maybeSingle();

      if (taken != null && taken['id'] != userId) {
        _showSnackBar('Username already taken');
        setState(() => _isLoading = false);
        return;
      }

      updates['username'] = newUsername;
      updates['username_changed_at'] =
          now.toIso8601String();
    }

    // ================= APPLY UPDATE TO DATABASE =================
    final res = await _supabase
        .from('profiles')
        .update(updates)
        .eq('id', userId)
        .select();

    // Debug: print result
    print("UPDATE RESULT: $res");

    // If no rows returned → update failed (likely RLS issue)
    if (res.isEmpty) {
      throw Exception("Update failed (RLS or no matching row)");
    }

    // ================= UPDATE LOCAL CACHE =================
    UserManager.instance.updateUser(userId, updates);

    // Small delay to ensure UI sync
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // Close screen and return success
    Navigator.pop(context, true);

  } catch (e) {
    // Log error for debugging
    debugPrint('SAVE ERROR: $e');

    // Show error to user
    _showSnackBar('ERROR: $e');
  }

  // Stop loading indicator
  if (mounted) {
    setState(() => _isLoading = false);
  }
}




  /// Display a snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ================================
  // UI BUILDERS - MAIN LAYOUT
  // ================================

 @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor,
    body: SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(),

                const SizedBox(height: 6),

                // Profile Section
                _buildProfileSection(),

                const SizedBox(height: 12),

                // Fields Section
                _buildFieldsSection(),

                const SizedBox(height: 14),

                // Save Button
                _buildSaveButton(),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildHeader() {
  final theme = Theme.of(context);

  return Row(
    children: [
      BackButton(color: theme.iconTheme.color),
      const Expanded(
        child: Center(
          child: Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      const SizedBox(width: 40),
    ],
  );
}
  // ================================
  // UI BUILDERS - PROFILE SECTION
  // ================================

  Widget _buildProfileSection() {
    final theme = Theme.of(context);

    return GlassContainer(
      radius: 25,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _changeProfileImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundImage:
                        _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                  ),
                  if (_isUploadingImage) const CircularProgressIndicator(),
                  if (_imageUrl == null)
                    Icon(Icons.camera_alt, color: theme.iconTheme.color),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Edit photo',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================
  // UI BUILDERS - FIELDS SECTION
  // ================================

  Widget _buildFieldsSection() {
    return Column(
      children: [
        _buildGlassTile('Name', _nameController),
        _buildGlassTile('Username', _usernameController),
        _buildGlassTile('Bio', _bioController),
        _buildGlassTile('Links', _linksController),
      ],
    );
  }

  Widget _buildGlassTile(String title, TextEditingController controller) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () => _openFieldEditor(title, controller),
        child: GlassContainer(
          height: 70,
          radius: 25,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.text.isEmpty
                            ? 'Add $title'
                            : controller.text,
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Open the field editor screen for a specific field
  Future<void> _openFieldEditor(
    String title,
    TextEditingController controller,
  ) async {
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditFieldScreen(
          title: title,
          controller: controller,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  // ================================
  // UI BUILDERS - SAVE BUTTON
  // ================================

  Widget _buildSaveButton() {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _saveProfile,
      child: GlassContainer(
        height: 60,
        radius: 25,
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : Text(
                  'Save',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
        ),
      ),
    );
  }
}

// ================================
// FIELD EDITOR SCREEN (PRIVATE)
// ================================

/// _EditFieldScreen - Dedicated screen for editing a single profile field
/// 
/// Features:
/// - Rate limiting validation for name (5 days) and username (10 days)
/// - Username availability checking
/// - Input sanitization for usernames
/// - Consistent glassmorphism UI
class _EditFieldScreen extends StatelessWidget {
  final String title;
  final TextEditingController controller;

  const _EditFieldScreen({
    required this.title,
    required this.controller,
  });
  // ================================
  // USERNAME CHANGE VALIDATION
  // ================================

  /// Check if username can be changed (10-day cooldown)
  bool _canChangeUsername(String? lastChangeDate) {
    if (lastChangeDate == null) return true;

    final last = DateTime.parse(lastChangeDate);
    final now = DateTime.now();

    return now.difference(last).inDays >= 10;
  }

  /// Calculate remaining days until username can be changed
  int _remainingUsernameDays(String? lastChangeDate) {
    if (lastChangeDate == null) return 0;

    final last = DateTime.parse(lastChangeDate);
    final now = DateTime.now();

    final passed = now.difference(last).inDays;

    return (10 - passed).clamp(0, 10);
  }

  // ================================
  // USERNAME AVAILABILITY CHECK
  // ================================

  /// Check if a username is already taken in the database
  Future<bool> _isUsernameTaken(String username) async {
  final supabase = Supabase.instance.client;

  final currentUserId = supabase.auth.currentUser?.id;

  final res = await supabase
      .from('profiles') 
      .select('id')
      .eq('username', username)
      .maybeSingle();

  // ================= CHECK =================
  if (res == null) return false;

  // IMPORTANT: ignore current user
  return res['id'] != currentUserId;
}

  // ================================
  // MAIN BUILD METHOD
  // ================================

  @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final supabase = Supabase.instance.client;

  return Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor,

    // ================= APP BAR =================
    appBar: AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: true,

      leadingWidth: 100,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 14,
            ),
          ),
        ),
      ),

      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: () async {

              final userId = supabase.auth.currentUser!.id;

              // ================= CACHE =================
              final data = UserManager.instance.getUser(userId);

              if (data == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User not loaded")),
                );
                return;
              }

              if (!context.mounted) return;

              final newValue = controller.text.trim();

              // ================= EMPTY USERNAME =================
              if (title == 'Username' && newValue.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Username cannot be empty'),
                  ),
                );
                return;
              }
              // ================= USERNAME VALIDATION =================
              if (title == 'Username') {
                final canChange =
                    _canChangeUsername(data['username_changed_at']);

                if (!canChange) {
                  final days = _remainingUsernameDays(
                      data['username_changed_at']);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'You can change your username after $days days',
                      ),
                    ),
                  );
                  return;
                }

                // ================= CLEAN USERNAME =================
                final clean = newValue
                    .toLowerCase()
                    .replaceAll(' ', '')
                    .replaceAll(RegExp(r'[^a-z0-9._]'), '');

                final taken = await _isUsernameTaken(clean);

                if (!context.mounted) return;

                if (taken && clean != data['username']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Username already taken'),
                    ),
                  );
                  return;
                }

                controller.text = clean;
              }

              Navigator.pop(context, true);
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    ),

    // ================= BODY =================
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          // ================= INPUT =================
          GlassContainer(
            height: title == 'Bio' ? 140 : 70,
            radius: 25,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        // TITLE
                        Text(
                          title,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // TEXT FIELD
                        TextField(
                          controller: controller,
                          autofocus: true,
                          maxLines: title == 'Bio' ? 3 : 1,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Add $title',
                            hintStyle: TextStyle(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.5),
                            ),
                          ),

                          // ================= REAL-TIME CLEAN =================
                          onChanged: (value) {
                            if (title == 'Username') {
                              final clean = value
                                  .toLowerCase()
                                  .replaceAll(' ', '')
                                  .replaceAll(
                                      RegExp(r'[^a-z0-9._]'), '');

                              if (clean != value) {
                                controller.value = TextEditingValue(
                                  text: clean,
                                  selection:
                                      TextSelection.collapsed(
                                    offset: clean.length,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ================= HELPERS =================
          if (title == 'Name')
            const Text(
              'You can change your name every 5 days',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),

          if (title == 'Username')
            const Text(
              'You can change your username every 10 days',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
        ],
      ),
    ),
  );
}
}