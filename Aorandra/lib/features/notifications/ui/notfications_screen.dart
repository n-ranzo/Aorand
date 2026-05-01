import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aorandra/shared/services/follow_service.dart';
import 'package:aorandra/shared/services/user_manager.dart';
import 'package:aorandra/features/profile/ui/profile_screen.dart';
import 'package:aorandra/features/profile/ui/profile_feed_screen.dart';
import 'package:aorandra/features/profile/ui/aoris_feed_screen.dart';

// ════════════════════════════════════════════════════════════
// NOTIFICATIONS SCREEN
// ════════════════════════════════════════════════════════════
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _markAllRead();
  }

  Future<void> _markAllRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('receiver_id', userId)
        .eq('is_read', false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: user == null
          ? _buildLoading(theme)
          : SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, theme),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _supabase
                          .from('notifications')
                          .stream(primaryKey: ['id'])
                          .eq('receiver_id', user.id)
                          .order('created_at', ascending: false),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return _buildLoading(theme);

                        final notifications = snapshot.data!;

                        // Pre-fetch any uncached senders
                        for (final n in notifications) {
                          final senderId = n['sender_id'];
                          if (senderId != null &&
                              UserManager.instance.getUser(senderId) == null) {
                            UserManager.instance.fetchAndCache(senderId);
                          }
                        }

                        if (notifications.isEmpty) return _buildEmpty(theme);

                        final now = DateTime.now();
                        final last7 = notifications.where((n) {
                          final d = DateTime.tryParse(n['created_at'] ?? '');
                          return d != null && now.difference(d).inDays <= 7;
                        }).toList();
                        final last30 = notifications.where((n) {
                          final d = DateTime.tryParse(n['created_at'] ?? '');
                          return d != null &&
                              now.difference(d).inDays > 7 &&
                              now.difference(d).inDays <= 30;
                        }).toList();
                        final older = notifications.where((n) {
                          final d = DateTime.tryParse(n['created_at'] ?? '');
                          return d != null && now.difference(d).inDays > 30;
                        }).toList();

                        return ListView(
                          padding: const EdgeInsets.only(bottom: 32),
                          children: [
                            if (last7.isNotEmpty) ...[
                              _sectionLabel('This week', theme),
                              ...last7.map((n) => _NotificationTile(notif: n)),
                            ],
                            if (last30.isNotEmpty) ...[
                              _sectionLabel('This month', theme),
                              ...last30.map((n) => _NotificationTile(notif: n)),
                            ],
                            if (older.isNotEmpty) ...[
                              _sectionLabel('Older', theme),
                              ...older.map((n) => _NotificationTile(notif: n)),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios_new,
                color: theme.iconTheme.color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Notifications',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) => Center(
        child: CircularProgressIndicator(color: theme.iconTheme.color),
      );

  Widget _buildEmpty(ThemeData theme) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none,
                size: 56, color: theme.iconTheme.color?.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'No notifications yet',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );

  Widget _sectionLabel(String title, ThemeData theme) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════
// NOTIFICATION TILE
// ════════════════════════════════════════════════════════════
class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notif;

  const _NotificationTile({required this.notif});

  // ── Tap handler ─────────────────────────────────────────
  Future<void> _handleTap(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final type = notif['type'];
    final senderId = notif['sender_id']?.toString() ?? '';
    final postId = notif['post_id']?.toString();
    final notifId = notif['id']?.toString() ?? '';

    // Mark as read
    if (notifId.isNotEmpty && notif['is_read'] == false) {
      supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notifId);
    }

    final user = UserManager.instance.getUser(senderId);
    final username = user?['username']?.toString() ?? 'User';

    // Follow types → open profile
    if (type == 'follow' ||
        type == 'follow_request' ||
        type == 'follow_accept') {
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProfileScreen(username: username, userId: senderId),
        ),
      );
      return;
    }

    // Like / comment → open post
    if (postId != null && postId.isNotEmpty) {
      final post = await supabase
          .from('posts')
          .select()
          .eq('id', postId)
          .maybeSingle();

      if (post == null || !context.mounted) return;

      if (post['type'] == 'aoris') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AorisFeedScreen(
              videos: [Map<String, dynamic>.from(post)],
              initialIndex: 0,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileFeedScreen(
              posts: [Map<String, dynamic>.from(post)],
              initialIndex: 0,
              username: username,
            ),
          ),
        );
      }
    }
  }

  // ── Accept follow request ────────────────────────────────
  Future<void> _acceptFollow(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final senderId = notif['sender_id']?.toString() ?? '';
    if (senderId.isEmpty) return;

    // SECURITY DEFINER RPC bypasses RLS (follower_id = sender ≠ auth.uid())
    await supabase.rpc('accept_follow_request', params: {
      'p_sender_id': senderId,
    });

    await supabase.from('notifications').delete().eq('id', notif['id']);

    await supabase.from('notifications').insert({
      'receiver_id': senderId,
      'sender_id': currentUserId,
      'type': 'follow_accept',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Refresh follower/following counts for both users
    unawaited(FollowService.instance.refreshUser(
      currentUserId,
      includeFollowState: false,
      includeStats: true,
    ));
    unawaited(FollowService.instance.refreshUser(
      senderId,
      includeFollowState: false,
      includeStats: true,
    ));
  }

  Future<void> _deleteNotif() async {
    await Supabase.instance.client
        .from('notifications')
        .delete()
        .eq('id', notif['id']);
  }

  // ── Time ago ─────────────────────────────────────────────
  String _timeAgo(String? raw) {
    if (raw == null) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w';
    return '${diff.inDays ~/ 30}mo';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = notif['type'] ?? '';
    final isRead = notif['is_read'] ?? true;
    final time = _timeAgo(notif['created_at']?.toString());

    return AnimatedBuilder(
      animation: UserManager.instance,
      builder: (context, _) {
        final sender = UserManager.instance.getUser(
            notif['sender_id']?.toString() ?? '');
        final username = sender?['username']?.toString() ?? 'User';
        final avatar = sender?['avatar_url']?.toString() ?? '';

        // ── Notification text ──────────────────────────────
        String actionText;
        IconData typeIcon;
        Color iconColor;

        switch (type) {
          case 'like':
            actionText = 'liked your post';
            typeIcon = Icons.favorite;
            iconColor = Colors.red;
            break;
          case 'comment':
            actionText = 'commented on your post';
            typeIcon = Icons.mode_comment;
            iconColor = Colors.blue;
            break;
          case 'follow':
            actionText = 'started following you';
            typeIcon = Icons.person_add;
            iconColor = Colors.green;
            break;
          case 'follow_accept':
            actionText = 'accepted your follow request';
            typeIcon = Icons.check_circle;
            iconColor = Colors.green;
            break;
          case 'follow_request':
            actionText = 'requested to follow you';
            typeIcon = Icons.person_add_alt_1;
            iconColor = Colors.orange;
            break;
          default:
            actionText = type;
            typeIcon = Icons.notifications;
            iconColor = Colors.grey;
        }

        return InkWell(
          onTap: type == 'follow_request'
              ? null
              : () => _handleTap(context),
          child: Container(
            color: isRead
                ? Colors.transparent
                : theme.colorScheme.primary.withValues(alpha: 0.06),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Unread dot ────────────────────────────
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRead
                        ? Colors.transparent
                        : theme.colorScheme.primary,
                  ),
                ),

                // ── Avatar ────────────────────────────────
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          theme.iconTheme.color?.withValues(alpha: 0.1),
                      backgroundImage: avatar.isNotEmpty
                          ? NetworkImage(avatar)
                          : null,
                      child: avatar.isEmpty
                          ? Icon(Icons.person,
                              color:
                                  theme.iconTheme.color?.withValues(alpha: 0.5))
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: iconColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 1.5,
                          ),
                        ),
                        child:
                            Icon(typeIcon, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // ── Text ──────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$username ',
                              style: TextStyle(
                                color: theme.textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              text: actionText,
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (time.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          time,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Follow request actions ─────────────────
                if (type == 'follow_request')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _actionButton(
                        label: 'Accept',
                        filled: true,
                        color: theme.colorScheme.primary,
                        onTap: () => _acceptFollow(context),
                      ),
                      const SizedBox(width: 8),
                      _actionButton(
                        label: 'Delete',
                        filled: false,
                        color: theme.textTheme.bodyMedium?.color ??
                            Colors.grey,
                        onTap: _deleteNotif,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton({
    required String label,
    required bool filled,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          border: filled ? null : Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
