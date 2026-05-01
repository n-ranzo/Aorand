// lib/screens/profile/profile_screen.dart

import 'dart:io';
import 'package:get/get.dart';
import 'package:aorandra/shared/services/user_manager.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// CONTROLLER
import 'package:aorandra/features/profile/logic/profile_controller.dart';

// WIDGETS
import 'package:aorandra/core/utils/glass_container.dart';

// SCREENS
import 'package:aorandra/features/profile/ui/edit_profile_screen.dart';
import 'package:aorandra/features/settings/ui/settings_screen.dart';
import 'package:aorandra/features/chat/ui/chat_list_screen.dart';
import 'package:aorandra/core/constants/profile_ui.dart';
import 'package:aorandra/features/profile/ui/profile_feed_screen.dart';
import 'package:aorandra/features/profile/ui/aoris_feed_screen.dart';
import 'package:aorandra/shared/services/follow_service.dart';

// ================================
// ENUMS
// ================================

/// Follow relationship states between users
enum FollowState {
  notFollowing,
  requested,
  following,
  blocked,
}

// ================================
// PROFILE SCREEN
// ================================

/// ProfileScreen - Displays user profile with posts, stats, and social actions
///
/// Features:
/// - Profile image upload with Supabase storage
/// - Follow/Unfollow/Block functionality with privacy handling
/// - Tabbed content (Posts, Videos, Reposts, Saved, Liked)
/// - Real-time data streaming from Supabase
/// - External link launching support
/// - Glassmorphism UI elements
class ProfileScreen extends StatefulWidget {
  final String username;
  final String userId;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ================================
  // SERVICES & STATE
  // ================================

  final SupabaseClient _supabase = Supabase.instance.client;
  final FollowService _followService = FollowService.instance;
  late final String _currentUserId;
  bool _isUploadingImage = false;
  bool _isBioExpanded = false;

  // ================================
  // HELPERS
  // ================================

  bool get _isMe => _currentUserId == widget.userId;

  // ================================
  // LIFECYCLE METHODS
  // ================================

  @override
void initState() {
  super.initState();
  _currentUserId = _supabase.auth.currentUser!.id;

  final controller = Get.put(ProfileController());
  controller.loadProfile(widget.userId);

  // 🔥 أهم سطر (حطّو قبل refresh)
  _followService.primeUser(widget.userId);

  // =========================
  // REFRESH
  // =========================

  _followService.refreshUser(
    widget.userId,
    includeFollowState: !_isMe,
    includeStats: true,
  );

  _followService.refreshUser(
    _currentUserId,
    includeFollowState: false,
    includeStats: true,
  );
}

  // ================================
  // IMAGE UPLOAD
  // ================================

  /// Allow user to select and upload a new profile image
  /// Uploads the selected image to Supabase and updates the profile data.
  /// This version is optimized for the Real-time UserAvatar system.
  Future<void> _changeProfileImage() async {
    // 1. Prevent multiple clicks or unauthorized uploads
    if (!_isMe || _isUploadingImage) return;

    final ImagePicker picker = ImagePicker();

    try {
      // 2. Pick the image from gallery
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      final File file = File(pickedFile.path);
      final String userId = _supabase.auth.currentUser!.id;

      // 3. Create a unique path
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '$userId/$fileName';

      // 4. Upload
      await _supabase.storage.from('avatars').upload(
            filePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      // 5. Get URL
      final String imageUrl =
          _supabase.storage.from('avatars').getPublicUrl(filePath);

      // 6. Update DB
      await _supabase.from('profiles').upsert({
        'id': userId,
        'avatar_url': imageUrl,
      });
      // ✅ FIX هنا (SnackBar)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile picture updated successfully!'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              bottom: 100, // ← يرفعه فوق النافبار
              left: 16,
              right: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.black.withValues(alpha: 0.9),
          ),
        );
      }
    } catch (e) {
      debugPrint('UPLOAD ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update image. Please try again.'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: 100,
              left: 16,
              right: 16,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  /// Launch external URL in browser or appropriate app
  Future<void> _openLink(String url) async {
    final Uri uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  // ================================
  // FOLLOW LOGIC
  // ================================

  /// Determine current follow state.
  /// Follow/unfollow comes from [FollowService].
  /// Block and pending requests still use the profiles arrays.
 FollowState _getFollowState(Map<String, dynamic> userData) {
  final List<dynamic> blockedUsers = userData['blockedUsers'] ?? [];
  final List<dynamic> requests = userData['followRequests'] ?? [];

  // ================= BLOCKED =================
  if (blockedUsers.contains(_currentUserId)) {
    return FollowState.blocked;
  }

  // ================= FOLLOW STATE (FIXED) =================
  final hasState = _followService.hasFollowState(widget.userId);

  if (hasState) {
    final isFollowing =
        _followService.followStateOf(widget.userId);

    if (isFollowing) {
      return FollowState.following;
    }
  }

  // ================= REQUESTED =================
  if (requests.contains(_currentUserId)) {
    return FollowState.requested;
  }

  // ================= DEFAULT =================
  return FollowState.notFollowing;
}

  /// Get button text for current follow state
  String _followText(FollowState state) {
    switch (state) {
      case FollowState.notFollowing:
        return 'Follow';
      case FollowState.requested:
        return 'Requested';
      case FollowState.following:
        return 'Following';
      case FollowState.blocked:
        return 'Unblock';
    }
  }

  /// Handle follow button tap based on current state
  Future<void> _handleFollowTap(
    FollowState state,
    Map<String, dynamic> targetData,
  ) async {
    final bool isPrivate = targetData['isPrivate'] ?? false;
    final controller = Get.find<ProfileController>();

    try {
      // ================= UNBLOCK =================
      if (state == FollowState.blocked) {
        final blocked = List.from(targetData['blockedUsers'] ?? []);
        blocked.remove(_currentUserId);

        await _supabase
            .from('profiles')
            .update({'blockedUsers': blocked}).eq('id', widget.userId);

        controller.user['blockedUsers'] = blocked;
        controller.user.refresh();

        return;
      }

      // ================= FOLLOW =================
      if (state == FollowState.notFollowing) {
        if (isPrivate) {
          final requests = List.from(targetData['followRequests'] ?? []);
          if (!requests.contains(_currentUserId)) {
            requests.add(_currentUserId);
          }

          await _supabase
              .from('profiles')
              .update({'followRequests': requests}).eq('id', widget.userId);
          controller.user['followRequests'] = requests;
          controller.user.refresh();
        } else {
          await _followService.toggleFollow(widget.userId);
        }

        return;
      }

      // ================= CANCEL REQUEST =================
      if (state == FollowState.requested) {
        final requests = List.from(targetData['followRequests'] ?? []);
        requests.remove(_currentUserId);

        await _supabase
            .from('profiles')
            .update({'followRequests': requests}).eq('id', widget.userId);
        controller.user['followRequests'] = requests;
        controller.user.refresh();

        return;
      }

      // ================= FOLLOWING =================
      if (state == FollowState.following) {
        _showFollowingOptions();
      }
    } catch (e) {
      debugPrint('FOLLOW ACTION ERROR: $e');
    }
  }

  Future<void> _unfollowUser() async {
    try {
      await _followService.toggleFollow(widget.userId);
    } catch (e) {
      debugPrint('UNFOLLOW ERROR: $e');
    }
  }

  Future<void> _blockUser() async {
  final controller = Get.find<ProfileController>();

  try {
    // 🔥 استخدم toggle بدل removeFollow
    if (_followService.followStateOf(widget.userId)) {
      await _followService.toggleFollow(widget.userId);
    }

    if (_followService.followStateOf(_currentUserId)) {
      await _followService.toggleFollow(_currentUserId);
    }

    // =========================
    // BLOCK LOGIC (كما هو)
    // =========================

    final targetUser = await _supabase
        .from('profiles')
        .select('followRequests, blockedUsers')
        .eq('id', widget.userId)
        .single();

    final requests = List.from(targetUser['followRequests'] ?? [])
      ..remove(_currentUserId);

    final blocked = List.from(targetUser['blockedUsers'] ?? []);

    if (!blocked.contains(_currentUserId)) {
      blocked.add(_currentUserId);
    }

    await _supabase.from('profiles').update({
      'followRequests': requests,
      'blockedUsers': blocked,
    }).eq('id', widget.userId);

    controller.user['followRequests'] = requests;
    controller.user['blockedUsers'] = blocked;
    controller.user.refresh();

    // 🔥 refresh آمن
    await Future.wait([
      _followService.refreshUser(
        widget.userId,
        includeFollowState: false,
        includeStats: true,
      ),
      _followService.refreshUser(
        _currentUserId,
        includeFollowState: false,
        includeStats: true,
      ),
    ]);
  } catch (e) {
    debugPrint('BLOCK ERROR: $e');
  }
}
  /// Show bottom sheet with unfollow/block options
  void _showFollowingOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Use the sheet's own context so Navigator.pop targets exactly this route
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                _sheetAction(
                  text: 'Unfollow',
                  color: Colors.redAccent,
                  // Close the sheet first, THEN run the async action.
                  // This removes the ModalBarrier before any setState fires.
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _unfollowUser();
                  },
                ),
                _sheetAction(
                  text: 'Block',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _blockUser();
                  },
                ),
                _sheetAction(
                  text: 'Cancel',
                  color: Colors.white,
                  onTap: () => Navigator.pop(sheetCtx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build action item for bottom sheet
  Widget _sheetAction({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Center(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      onTap: onTap,
    );
  }

  /// Show friends list bottom sheet (placeholder)
  void _showFriendsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return const SizedBox(
          height: 380,
          child: Center(
            child: Text(
              'Friends list here',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  /// Navigate to chat screen with current user
  void _openMessage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatListScreen(currentUserId: _currentUserId),
      ),
    );
  }

  /// Handle share button tap (placeholder)
  void _onShareTap() {}

  // ================================
  // MAIN BUILD METHOD
  // ================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final controller = Get.find<ProfileController>();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Obx(() {
          /// ================= LOADING =================
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final userData = controller.user;

          /// ================= NO USER =================
          if (userData.isEmpty) {
            return const Center(
              child: Text('User not found'),
            );
          }

          UserManager.instance.setUsers([userData]);

          /// ================= MAIN UI =================
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 5),

                        /// HEADER
                        _buildHeader(userData),

                        const SizedBox(height: 8),

                        /// PROFILE
                        _buildProfile(userData),

                        const SizedBox(height: 6),

                        /// STATS
                        _buildStats(userData),

                        const SizedBox(height: 6),

                        /// BUTTONS
                        _buildButtons(userData),

                        const SizedBox(height: 4),

                        /// BIO
                        _buildBio(userData),

                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),

                /// ================= TABS =================
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    Container(
                      color: theme.scaffoldBackgroundColor,
                      child: _buildTabs(userData),
                    ),
                  ),
                ),
              ];
            },

            /// ================= CONTENT =================
            body: TabBarView(
              children: [
                _buildPosts(),
                _buildAorisGrid(),
                const Center(child: Text('Reposts')),
                const Center(child: Text('Saved')),
                const Center(child: Text('Liked')),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAorisGrid() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('posts').stream(primaryKey: ['id']).map((rows) =>
          rows
              .where((p) =>
                  p['profile_id'] == widget.userId && p['type'] == 'aoris')
              .toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final videos = snapshot.data!;

        if (videos.isEmpty) {
          return const Center(child: Text('No content'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final item = videos[index];
            String thumbnailUrl = '';

            final mediaList = item['media_urls'];
            if (mediaList is List && mediaList.isNotEmpty) {
              final first = mediaList.first.toString();
              thumbnailUrl = first.startsWith('http')
                  ? first
                  : _supabase.storage.from('media').getPublicUrl(first);
            } else if (item['media_url'] != null &&
                item['media_url'].toString().isNotEmpty) {
              final v = item['media_url'].toString();
              thumbnailUrl = v.startsWith('http')
                  ? v
                  : _supabase.storage.from('media').getPublicUrl(v);
            }

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AorisFeedScreen(
                    videos: videos,
                    initialIndex: index,
                  ),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.black12,
                    child: thumbnailUrl.isNotEmpty
                        ? Image.network(
                            thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                          )
                        : const Icon(Icons.videocam),
                  ),
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 18,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPosts() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('posts').stream(primaryKey: ['id']).map((posts) =>
          posts
              .where((post) =>
                  post['profile_id'] == widget.userId &&
                  post['type'] == 'post') // 🔥 التعديل هون
              .toList()),
      builder: (context, snapshot) {
        // Loading state
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!;

        // Empty state
        if (posts.isEmpty) {
          return const Center(child: Text("No content"));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];

            String imageUrl = '';
            bool hasMultiple = false;
            bool hasVideo = false;

            /// ================================
            /// 1. Handle media_urls (List)
            /// ================================
            final mediaList = post['media_urls'];

            if (mediaList is List && mediaList.isNotEmpty) {
              hasMultiple = mediaList.length > 1;

              // Detect if any media is video
              for (var m in mediaList) {
                final value = m.toString().toLowerCase();

                if (value.endsWith('.mp4') ||
                    value.endsWith('.mov') ||
                    value.endsWith('.avi')) {
                  hasVideo = true;
                }
              }

              final first = mediaList.first.toString();

              if (first.startsWith('http')) {
                imageUrl = first;
              } else {
                imageUrl = _supabase.storage.from('media').getPublicUrl(first);
              }
            }

            /// ================================
            /// 2. Fallback to single media_url
            /// ================================
            else if (post['media_url'] != null &&
                post['media_url'].toString().isNotEmpty) {
              final value = post['media_url'].toString();

              if (value.endsWith('.mp4') ||
                  value.endsWith('.mov') ||
                  value.endsWith('.avi')) {
                hasVideo = true;
              }

              if (value.startsWith('http')) {
                imageUrl = value;
              } else {
                imageUrl = _supabase.storage.from('media').getPublicUrl(value);
              }
            }

            /// ================================
            /// Open full feed screen
            /// ================================
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileFeedScreen(
                      posts: posts,
                      initialIndex: index,
                      username: widget.username, // ✅ FIX
                    ),
                  ),
                );
              },
              child: Stack(
                children: [
                  /// ================= IMAGE =================
                  Container(
                    color: Colors.black12,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                          )
                        : const Icon(Icons.image),
                  ),

                  /// ================= ICONS =================
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Row(
                      children: [
                        /// Video icon
                        if (hasVideo)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),

                        /// Multiple images icon
                        if (hasMultiple)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.collections,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================================
  // UI BUILDERS - HEADER
  // ================================

  Widget _buildHeader(Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final bool isPrivate = data['isPrivate'] ?? false;

    final String username = (data['username'] ?? '').toString().trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            // ── Back button (other users only) ──────
            if (!_isMe)
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.arrow_back,
                    color: theme.textTheme.bodyLarge?.color,
                    size: 24,
                  ),
                ),
              ),

            // ── Username + lock ──────────────────────
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      username.isEmpty ? 'user' : username,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isPrivate)
                    Icon(
                      Icons.lock,
                      size: 16,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                ],
              ),
            ),

            // ── Settings (own profile only) ──────────
            if (_isMe)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                child: _buildIcon(Icons.settings),
              ),
          ],
        ),
      ),
    );
  }

  // ================================
  // UI BUILDERS - PROFILE SECTION
  // ================================

  Widget _buildProfile(Map<String, dynamic> data) {
    final theme = Theme.of(context);

    final String imageUrl = (data['avatar_url'] ?? '').toString().trim();

    final String name = (data['name'] ?? '').toString().trim();

    return Transform.translate(
      offset: const Offset(0, -18),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isMe ? _changeProfileImage : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  backgroundImage: imageUrl.isNotEmpty
                      ? NetworkImage(
                          '$imageUrl?v=${DateTime.now().millisecondsSinceEpoch}')
                      : null,
                  child: imageUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 40,
                          color: theme.iconTheme.color,
                        )
                      : null,
                ),

                // loading overlay
                if (_isUploadingImage)
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ================================
  // UI BUILDERS - STATS
  // ================================

  /// Build stats row with posts count (filtered in Dart)
  Widget _buildStats(Map<String, dynamic> userData) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // Fetch all posts and filter by userId in Dart
      stream: _supabase.from('posts').stream(primaryKey: ['id']),
      builder: (context, postSnap) {
        // Count posts for this user only
        final postsCount = postSnap.hasData
            ? postSnap.data!
                .where((post) => post['profile_id'] == widget.userId)
                .length
            : 0;

        return AnimatedBuilder(
          animation: _followService,
          builder: (context, _) => Transform.translate(
            offset: const Offset(0, -22),
            child: Row(
              children: [
                Expanded(child: _Stat(postsCount.toString(), 'posts')),
                Expanded(
                  child: _Stat(
                    _followService.followersCountOf(widget.userId).toString(),
                    'followers',
                  ),
                ),
                Expanded(
                  child: _Stat(
                    _followService.followingCountOf(widget.userId).toString(),
                    'following',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================================
  // UI BUILDERS - ACTION BUTTONS
  // ================================

  Widget _buildButtons(Map<String, dynamic> data) {
    final theme = Theme.of(context);

    Widget buildAddFriendButton() {
      return Transform.translate(
        offset: const Offset(0, -6),
        child: GestureDetector(
          onTap: _showFriendsSheet,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.white24
                    : Colors.black12,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.5 : 0.1,
                  ),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child:
                Icon(Icons.person_add, color: theme.iconTheme.color, size: 26),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _followService,
      builder: (context, _) {
        final followState = _getFollowState(data);
        final isFollowBusy = _followService.isToggling(widget.userId);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Transform.translate(
            offset: const Offset(0, -14),
            child: Row(
              children: [
                if (_isMe) ...[
                  Expanded(
                    child: _buildButton('Edit', () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );

                      if (updated == true) {
                        setState(() {});
                      }
                    }),
                  ),
                  const SizedBox(width: 12),
                  buildAddFriendButton(),
                  const SizedBox(width: 12),
                  Expanded(child: _buildButton('Share', _onShareTap)),
                ] else ...[
                  Expanded(
                    child: _buildButton(
                      _followText(followState),
                      isFollowBusy
                          ? null
                          : () async {
                              await _handleFollowTap(followState, data);
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Transform.translate(
                    offset: const Offset(-4, -6),
                    child: buildAddFriendButton(),
                  ),
                  const SizedBox(width: 12),
                  if (followState == FollowState.following)
                    Expanded(child: _buildButton('Message', _openMessage)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build glass-styled action button
  Widget _buildButton(String text, VoidCallback? onTap) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(ProfileUI.buttonRadius),
        onTap: onTap,
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: GlassContainer(
          height: ProfileUI.buttonHeight,
          radius: ProfileUI.buttonRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================================
  // UI BUILDERS - BIO & LINKS
  // ================================

  Widget _buildBio(Map<String, dynamic> data) {
    final theme = Theme.of(context);

    final String bio = (data['bio'] ?? '').toString();
    final bool isLong = bio.length > 80;

    final rawLinks = data['links'];
    final List<Map<String, dynamic>> links = rawLinks is List
        ? rawLinks
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : [];

    return Transform.translate(
      offset: const Offset(0, -12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInCubic,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= BIO TEXT =================
              if (bio.isNotEmpty)
                Text(
                  bio,
                  maxLines: _isBioExpanded ? null : 2,
                  overflow: _isBioExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

              // ================= SEE MORE / HIDE =================
              if (isLong)
                GestureDetector(
                  onTap: () => setState(() => _isBioExpanded = !_isBioExpanded),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _isBioExpanded ? 'Hide' : 'See more',
                      style: TextStyle(
                        color:
                            theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              // ================= LINKS =================
              if (links.isNotEmpty) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _showLinksSheet(links),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link,
                          size: 14, color: theme.textTheme.bodyMedium?.color),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _buildLinksLabel(links),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _buildLinksLabel(List<Map<String, dynamic>> links) {
    final first = links.first;
    final url =
        (first['url'] as String? ?? '').replaceFirst(RegExp(r'^https?://'), '');
    if (links.length == 1) return url;
    return '$url and ${links.length - 1} more';
  }

  void _showLinksSheet(List<Map<String, dynamic>> links) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Links',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...links.map((link) {
              final url = link['url'] as String? ?? '';
              final title = link['title'] as String? ?? '';
              final displayUrl = url.replaceFirst(RegExp(r'^https?://'), '');

              return ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.textTheme.bodyLarge?.color
                              ?.withValues(alpha: 0.3) ??
                          Colors.white30,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(Icons.link,
                      size: 18, color: theme.textTheme.bodyLarge?.color),
                ),
                title: title.isNotEmpty
                    ? Text(title,
                        style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w500))
                    : null,
                subtitle: Text(displayUrl,
                    style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.6),
                        fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.pop(context);
                  _openLink(url);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ================================
  // UI BUILDERS - TABS
  // ================================

  Widget _buildTabs(Map<String, dynamic> userData) {
    final theme = Theme.of(context);

    final bool showLikedVideos = userData['showLikedVideos'] ?? false;
    final bool showSavedVideos = userData['showSavedVideos'] ?? false;
    final List<dynamic> followers = userData['followersList'] ?? [];

    final bool isOwner = _currentUserId == widget.userId;
    final bool isMutual = followers.contains(_currentUserId);

    return Transform.translate(
      offset: const Offset(0, -10),
      child: TabBar(
        indicatorColor: theme.textTheme.bodyLarge?.color,
        indicatorWeight: 2.5,
        tabs: [
          Tab(icon: Icon(Icons.grid_view, color: theme.iconTheme.color)),
          Tab(icon: Icon(Icons.video_library, color: theme.iconTheme.color)),
          Tab(icon: Icon(Icons.repeat, color: theme.iconTheme.color)),
          Tab(
            icon: Stack(
              children: [
                Icon(Icons.bookmark_border, color: theme.iconTheme.color),
                if (!(showSavedVideos || isOwner || isMutual))
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(Icons.block, size: 14, color: Colors.red),
                  ),
              ],
            ),
          ),
          Tab(
            icon: Stack(
              children: [
                Icon(Icons.favorite_border, color: theme.iconTheme.color),
                if (!(showLikedVideos || isOwner || isMutual))
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(Icons.block, size: 14, color: Colors.red),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build glass-styled icon button
  Widget _buildIcon(IconData icon) {
    final theme = Theme.of(context);

    return GlassContainer(
      height: ProfileUI.headerSize,
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: theme.iconTheme.color),
      ),
    );
  }
}

// ================================
// STAT WIDGET (PRIVATE)
// ================================

/// _Stat - Displays a numeric value with label (posts, followers, following)
class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        Text(
          label,
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _TabBarDelegate(this.child);

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return false;
  }
}
