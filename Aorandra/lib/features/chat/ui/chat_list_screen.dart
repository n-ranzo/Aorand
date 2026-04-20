import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import 'new_message_screen.dart';
import 'package:aorandra/shared/services/user_manager.dart';

class ChatListScreen extends StatefulWidget {
  final String currentUserId;

  const ChatListScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final supabase = Supabase.instance.client;

  double headerHeight = 80;
  double searchHeight = 50;

  final TextEditingController searchController = TextEditingController();

  String username = "";
  String searchText = "";

  @override
  void initState() {
    super.initState();
    loadCurrentUser();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadCurrentUser() async {
  final data = await supabase
      .from('profiles') 
      .select('username')
      .eq('id', widget.currentUserId)
      .maybeSingle();

  if (data != null) {
    setState(() {
      username = data['username'] ?? "";
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: theme.scaffoldBackgroundColor,
          child: Column(
            children: [
              _buildHeader(theme),
              _buildSearch(theme, isDark),
              _buildChatList(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      height: headerHeight + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 15,
        right: 15,
      ),
      child: Row(
        children: [
          Text(
            username.isEmpty ? "Loading..." : username,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewMessageScreen(
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
            },
            icon: Icon(
              Icons.edit,
              color: theme.iconTheme.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        height: searchHeight,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: searchController,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(ThemeData theme, bool isDark) {
    return Expanded(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('chats')
            .select()
            .contains('participants', [widget.currentUserId]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.textTheme.bodyLarge?.color,
              ),
            );
          }

          final chats = snapshot.data!;

          if (chats.isEmpty) {
            return _emptyState(isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              return _chatItem(chats[index], theme, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _chatItem(
  Map<String, dynamic> chatData,
  ThemeData theme,
  bool isDark,
) {
  final List participants = chatData['participants'];

  final otherUserId = participants.firstWhere(
    (id) => id != widget.currentUserId,
  );

  final user = UserManager.instance.getUser(otherUserId);

  final username = user?['username'] ?? "User";
  final avatar = user?['avatar_url'] ?? "";

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            currentUserId: widget.currentUserId,
            otherUserId: otherUserId,
            chatId: chatData['id'],
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor:
                isDark ? Colors.white24 : Colors.black12,
            backgroundImage:
                avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              username,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _emptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 60,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(height: 15),
          Text(
            "No messages yet",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}