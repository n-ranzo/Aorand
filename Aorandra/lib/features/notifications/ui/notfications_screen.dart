import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aorandra/shared/services/user_manager.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final theme = Theme.of(context);

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
                      stream: supabase
                          .from('notifications')
                          .stream(primaryKey: ['id'])
                          .eq('profile_id', user.id)
                          .order('created_at', ascending: false),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return _buildLoading(theme);
                        }

                        final notifications = snapshot.data!;

                        if (notifications.isEmpty) {
                          return _empty(theme);
                        }

                        final now = DateTime.now();

                        final last7 = notifications.where((n) {
                          final date =
                              DateTime.parse(n["created_at"]);
                          return now.difference(date).inDays <= 7;
                        }).toList();

                        final last30 = notifications.where((n) {
                          final date =
                              DateTime.parse(n["created_at"]);
                          return now.difference(date).inDays > 7 &&
                              now.difference(date).inDays <= 30;
                        }).toList();

                        return ListView(
                          padding: const EdgeInsets.only(bottom: 30),
                          children: [
                            if (last7.isNotEmpty) ...[
                              _section("Last 7 days"),
                              ...last7.map(
                                (n) => NotificationTile(notif: n),
                              ),
                            ],
                            if (last30.isNotEmpty) ...[
                              _section("Last 30 days"),
                              ...last30.map(
                                (n) => NotificationTile(notif: n),
                              ),
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
            "Notifications",
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

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: CircularProgressIndicator(
        color: theme.iconTheme.color,
      ),
    );
  }

  Widget _empty(ThemeData theme) {
    return Center(
      child: Text(
        "No notifications yet",
        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ================= TILE =================

class NotificationTile extends StatelessWidget {
  final Map notif;

  const NotificationTile({super.key, required this.notif});

 @override
Widget build(BuildContext context) {
  final supabase = Supabase.instance.client;
  final theme = Theme.of(context);

  return AnimatedBuilder(
    animation: UserManager.instance,
    builder: (context, _) {

      // ================= GET USER FROM CACHE =================
      final user = UserManager.instance.getUser(notif['sender_id']);

      final username = user?['username'] ?? "User";
      final avatar = user?['avatar_url'] ?? "";

      final type = notif["type"];

      // ================= FOLLOW REQUEST =================
      if (type == "follow_request") {
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: avatar.isNotEmpty
                ? NetworkImage(avatar)
                : null,
            child: avatar.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(
            "$username requested to follow you",
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ACCEPT
              TextButton(
                onPressed: () async {
                  final currentUser =
                      supabase.auth.currentUser?.id;

                  await supabase.from('followers').insert({
                    'follower_id': notif['sender_id'],
                    'following_id': currentUser,
                  });

                  await supabase
                      .from('notifications')
                      .delete()
                      .eq('id', notif['id']);

                  await supabase.from('notifications').insert({
                    'receiver_id': notif['sender_id'], 
                    'sender_id': currentUser,
                    'type': 'follow_accept',
                    'created_at':
                        DateTime.now().toIso8601String(),
                  });
                },
                child: const Text("Accept"),
              ),

              // DELETE
              TextButton(
                onPressed: () async {
                  await supabase
                      .from('notifications')
                      .delete()
                      .eq('id', notif['id']);
                },
                child: const Text("Delete"),
              ),
            ],
          ),
        );
      }

      // ================= NORMAL NOTIFICATIONS =================

      String text = "";

      if (type == "like") {
        text = "liked your post";
      } else if (type == "comment") {
        text = "commented on your post";
      } else if (type == "follow") {
        text = "started following you";
      } else if (type == "follow_accept") {
        text = "accepted your follow request";
      }

      return ListTile(
        leading: CircleAvatar(
          backgroundImage: avatar.isNotEmpty
              ? NetworkImage(avatar)
              : null,
          child: avatar.isEmpty
              ? const Icon(Icons.person)
              : null,
        ),
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "$username ",
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: text,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
}