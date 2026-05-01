import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aorandra/shared/services/user_manager.dart';
import '../data/profile_service.dart';
import 'profile_controller.dart';

/// EditProfileController
/// ---------------------
/// Handles all business logic for the Edit Profile screen.
/// The UI layer (EditProfileScreen) only reads state and calls methods here.
///
/// Responsibilities:
///   - Load current user data (cache-first, then DB)
///   - Upload avatar to Supabase Storage
///   - Validate username (cooldown, availability, format)
///   - Save profile changes to Supabase
class EditProfileController extends GetxController {
  final _supabase = Supabase.instance.client;

  // ================================
  // TEXT CONTROLLERS
  // Owned here so they survive widget rebuilds and are disposed cleanly.
  // ================================
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final bioController = TextEditingController();
  final RxList<Map<String, dynamic>> links = <Map<String, dynamic>>[].obs;// For simplicity, using a single TextField with comma-separated links. Can be refactored to a dynamic list if needed.

  // ================================
  // REACTIVE STATE
  // Observed by the UI via Obx().
  // ================================
  final imageUrl = ''.obs;          // current avatar URL
  final isLoading = false.obs;      // save in progress
  final isUploadingImage = false.obs; // avatar upload in progress

  // ================================
  // LIFECYCLE
  // ================================

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  @override
  void onClose() {
    nameController.dispose();
    usernameController.dispose();
    bioController.dispose();
    super.onClose();
  }

  // ================================
  // LOAD DATA
  // ================================

  /// Populates all text controllers and imageUrl from the user's profile.
  /// Uses UserManager cache first to avoid flickering, then syncs from DB.
  Future<void> loadUserData() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Show cached data immediately (fast path)
      final cached = UserManager.instance.getUser(userId);
      if (cached != null) _applyData(cached);

      // Fetch fresh data from Supabase and update UI + cache
      final data = await ProfileService.getEditableProfile(userId);
      if (data == null) return;

      UserManager.instance.setUser(userId, data);
      _applyData(data);
    } catch (e) {
      debugPrint('EditProfile load error: $e');
    }
  }

  /// Writes fetched data into text controllers and reactive fields.
  void _applyData(Map<String, dynamic> data) {
    nameController.text = data['name'] ?? '';
    usernameController.text = data['username'] ?? '';
    bioController.text = data['bio'] ?? '';
    links.value = List<Map<String, dynamic>>.from(data['links'] ?? []);
    imageUrl.value = data['avatar_url'] ?? '';
  }

  // ================================
  // AVATAR UPLOAD
  // ================================

  /// Opens the gallery picker, uploads the selected image, and updates imageUrl.
  /// No-op if an upload is already in progress.
  Future<void> changeProfileImage() async {
    if (isUploadingImage.value) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    isUploadingImage.value = true;
    try {
      final userId = _supabase.auth.currentUser!.id;
      final url = await ProfileService.uploadAvatar(userId, File(picked.path));
      imageUrl.value = url;
    } catch (e) {
      debugPrint('Avatar upload error: $e');
    } finally {
      isUploadingImage.value = false;
    }
  }

  // ================================
  // USERNAME VALIDATION HELPERS
  // ================================

  /// Returns true if the user is allowed to change their username.
  /// Enforces a 10-day cooldown between changes.
  bool canChangeUsername(String? lastChangeDate) {
    if (lastChangeDate == null) return true;
    final last = DateTime.parse(lastChangeDate);
    return DateTime.now().difference(last).inDays >= 10;
  }

  /// Returns how many days remain before the user can change their username.
  int remainingUsernameDays(String? lastChangeDate) {
    if (lastChangeDate == null) return 0;
    final passed = DateTime.now().difference(DateTime.parse(lastChangeDate)).inDays;
    return (10 - passed).clamp(0, 10);
  }

  /// Strips invalid characters from a username input.
  /// Allowed: lowercase letters, digits, underscores, dots.
  String cleanUsername(String value) {
    return value
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^a-z0-9._]'), '');
  }

  /// Called by _EditFieldScreen before closing.
  /// Validates the field and cleans it in-place (for Username).
  /// Returns an error message string on failure, null on success.
  Future<String?> validateAndCleanField(String title) async {
    if (title != 'Username') return null;

    final userId = _supabase.auth.currentUser!.id;
    final data = UserManager.instance.getUser(userId);
    if (data == null) return 'User not loaded';

    final value = usernameController.text.trim();
    if (value.isEmpty) return 'Username cannot be empty';

    // Cooldown check
    if (!canChangeUsername(data['username_changed_at'])) {
      final days = remainingUsernameDays(data['username_changed_at']);
      return 'You can change your username after $days days';
    }

    // Clean and check availability
    final clean = cleanUsername(value);
    final taken = await ProfileService.isUsernameTaken(clean, userId);
    if (taken && clean != data['username']) return 'Username already taken';

    usernameController.text = clean;
    return null;
  }

  // ================================
  // SAVE PROFILE
  // ================================

  /// Persists all edited fields to Supabase and updates the local cache.
  /// Returns null on success, or an error message string on failure.
  ///
  /// Note: ProfileService.saveProfile handles missing optional columns
  /// (bio, links) automatically via PGRST204 retry logic.
  Future<String?> trySaveProfile() async {
    final userId = _supabase.auth.currentUser!.id;
    isLoading.value = true;

    try {
      // Ensure we have a baseline profile to diff against
      Map<String, dynamic>? data = UserManager.instance.getUser(userId);
      if (data == null) {
        data = await ProfileService.getEditableProfile(userId);
        if (data != null) UserManager.instance.setUser(userId, data);
      }
      if (data == null) return 'User data not found';

      final now = DateTime.now();

      // Start with always-updated fields
      final updates = <String, dynamic>{
        'bio': bioController.text.trim(),
        'links': links.toList(),
        'avatar_url': imageUrl.value,
      };

      // Only include name if it changed
      if (nameController.text.trim() != (data['name'] ?? '')) {
        updates['name'] = nameController.text.trim().isEmpty
            ? null
            : nameController.text.trim();
      }

      // Only include username if it changed — with full validation
      if (usernameController.text.trim() != data['username']) {
        if (!canChangeUsername(data['username_changed_at'])) {
          final days = remainingUsernameDays(data['username_changed_at']);
          return 'You can change your username after $days days';
        }

        final newUsername = usernameController.text.trim();
        final taken = await ProfileService.isUsernameTaken(newUsername, userId);
        if (taken) return 'Username already taken';

        updates['username'] = newUsername;
        updates['username_changed_at'] = now.toIso8601String();
      }

      final res = await ProfileService.saveProfile(userId, updates);
      if (res.isEmpty) return 'Update failed (check RLS permissions)';

      // Keep local cache in sync so other screens reflect changes immediately
      UserManager.instance.updateUser(userId, updates);

      // Update the ProfileController state directly so the profile screen
      // reflects the new values as soon as this screen pops — no extra
      // network round-trip needed.
      if (Get.isRegistered<ProfileController>()) {
        final profileCtrl = Get.find<ProfileController>();
        profileCtrl.user.addAll(updates);
      }

      return null; // success
    } catch (e) {
      debugPrint('Save error: $e');
      return 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
