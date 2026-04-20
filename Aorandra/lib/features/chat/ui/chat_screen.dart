import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:aorandra/shared/services/user_manager.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String chatId;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.chatId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final supabase = Supabase.instance.client;

  double headerHeight = 85;
  double inputHeight = 55;
  double inputBottomSpace = 20;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  bool isTyping = false;

  String username = "";
  String userTag = "";

  late String chatId;

  @override
  void initState() {
    super.initState();

    chatId = widget.chatId;
    loadUser();

    messageController.addListener(() {
      setState(() {
        isTyping = messageController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // ===============================
  // LOAD USER
  // ===============================
 Future<void> loadUser() async {
  final user = UserManager.instance.getUser(widget.otherUserId);

  if (user != null) {
    setState(() {
      username = user['username'] ?? "";
      userTag = user['userTag'] ?? "";
    });
    return;
  }

  // fallback إذا مش موجود بالكاش
  final data = await supabase
      .from('profiles')
      .select('id, username, userTag, avatar_url')
      .eq('id', widget.otherUserId)
      .maybeSingle();

  if (data != null && mounted) {
  
    UserManager.instance.setUser(widget.otherUserId, data);

    setState(() {
      username = data['username'] ?? "";
      userTag = data['userTag'] ?? "";
    });
  }
}

  // ===============================
  // SEND MESSAGE
  // ===============================
  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    final text = messageController.text.trim();
    messageController.clear();

    await supabase.from('messages').insert({
      "chat_id": chatId,
      "text": text,
      "sender_id": widget.currentUserId,
      "created_at": DateTime.now().toIso8601String(),
    });
  }

  Future<void> sendImage(ImageSource source) async {
  final picker = ImagePicker();
  final file = await picker.pickImage(source: source);

  if (file == null) return;

  final bytes = await File(file.path).readAsBytes();
  final fileName = DateTime.now().millisecondsSinceEpoch.toString();

  await supabase.storage
      .from('chat')
      .uploadBinary('images/$fileName.jpg', bytes);

  final url = supabase.storage
      .from('chat')
      .getPublicUrl('images/$fileName.jpg');

  await supabase.from('messages').insert({
    "chat_id": chatId,
    "image": url,
    "sender_id": widget.currentUserId,
    "created_at": DateTime.now().toIso8601String(),
  });
}

  // ===============================
  // MEDIA MENU
  // ===============================
  void _openMediaMenu() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _mediaButton(Icons.camera_alt, "Camera"),
            _mediaButton(Icons.photo, "Gallery"),
          ],
        ),
      );
    },
  );
}

 Widget _mediaButton(IconData icon, String label) {
  return GestureDetector(
    onTap: () {
      Navigator.pop(context);

      if (label == "Camera") {
        sendImage(ImageSource.camera);
      } else if (label == "Gallery") {
        sendImage(ImageSource.gallery);
      }
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.white10,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}

  // ===============================
  // MAIN UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            _buildHeader(theme, isDark),
            _buildMessages(theme),
            _buildInputBar(theme, isDark),
          ],
        ),
      ),
    );
  }

  // ===============================
  // MESSAGES
  // ===============================
  Widget _buildMessages(ThemeData theme) {
    return Expanded(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('messages')
            .stream(primaryKey: ['id'])
            .eq('chat_id', chatId)
            .order('created_at', ascending: true), // ✅ FIX

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.textTheme.bodyLarge?.color,
              ),
            );
          }

          final docs = snapshot.data!;

          return ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              final isMe = data["sender_id"] == widget.currentUserId;

              return isMe
                  ? _rightMessage(data, theme)
                  : _leftMessage(data, theme);
            },
          );
        },
      ),
    );
  }

  // ===============================
  // HEADER
  // ===============================
  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      height: headerHeight + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 10,
        right: 10,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          ),

          CircleAvatar(
            radius: 20,
            backgroundColor: isDark ? Colors.white24 : Colors.black12,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username,
                    style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color)),
                Text(userTag,
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54)),
              ],
            ),
          ),

          // CALL BUTTONS
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.call, color: theme.iconTheme.color),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.videocam, color: theme.iconTheme.color),
          ),
        ],
      ),
    );
  }

  // ===============================
  // MESSAGE LEFT
  // ===============================
Widget _leftMessage(Map data, ThemeData theme) {
  final text = data["text"];
  final image = data["image"];
  final isDark = theme.brightness == Brightness.dark;

  return Align(
    alignment: Alignment.centerLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // 📸 IMAGE (قابلة للفتح)
        if (image != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImage(imageUrl: image),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  image,
                  width: 220,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

        // 💬 TEXT
        if (text != null)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
      ],
    ),
  );
}

  // ===============================
  // MESSAGE RIGHT
  // ===============================
Widget _rightMessage(Map data, ThemeData theme) {
  final text = data["text"];
  final image = data["image"];

  return Align(
    alignment: Alignment.centerRight,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [

        // 📸 IMAGE (قابلة للفتح)
        if (image != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImage(imageUrl: image),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  image,
                  width: 220,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

        // 💬 TEXT
        if (text != null)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent, 
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              text,
              style: const TextStyle(color: Colors.white),
            ),
          ),
      ],
    ),
  );
}
  // ===============================
  // INPUT BAR
  // ===============================
  Widget _buildInputBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        10,
        0,
        10,
        MediaQuery.of(context).padding.bottom + inputBottomSpace,
      ),
      child: Row(
        children: [

          
          GestureDetector(
            onTap: _openMediaMenu,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ),
              child: Icon(
                Icons.add,
                color: theme.iconTheme.color,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // INPUT
          Expanded(
            child: Container(
              height: inputHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ),
              child: Row(
                children: [

                  // 🎤 MIC
                  Icon(
                    Icons.mic,
                    color: theme.iconTheme.color?.withOpacity(0.6),
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: TextField(
                      controller: messageController,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: "Message...",
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.white54
                              : Colors.black45,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  if (isTyping)
                    IconButton(
                      onPressed: sendMessage,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // 📸 IMAGE + ZOOM
          Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),

          // ❌ CLOSE BUTTON
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}