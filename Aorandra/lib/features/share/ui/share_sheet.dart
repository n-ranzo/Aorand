import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:aorandra/shared/services/user_manager.dart';
import 'package:aorandra/shared/widgets/user_avatar.dart';

class ShareSheet extends StatefulWidget {
  final Map post;
  final ScrollController scrollController;

  /// Callback: (post, selectedUsers, message)
  final Future<void> Function(
    Map post,
    Set<String> users,
    String message,
  ) onSend;

  const ShareSheet({
    super.key,
    required this.post,
    required this.scrollController,
    required this.onSend,
  });

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  // ================= STATE =================
  final Set<String> selectedUsers = {};
  final TextEditingController messageController = TextEditingController();
  bool isSending = false;

  @override
  void dispose() {
    messageController.dispose(); // 🔥 مهم
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = UserManager.instance.getAllUsers();

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        color: Colors.black.withOpacity(0.85),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Column(
            children: [

              // ================= SCROLLABLE =================
              Expanded(
                child: ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [

                    // HANDLE
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // USERS
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: users.length,
                        itemBuilder: (_, i) {
                          final user = users[i];
                          final String userId = user['id'].toString();
                          final bool isSelected = selectedUsers.contains(userId);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedUsers.remove(userId);
                                } else {
                                  selectedUsers.add(userId);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                children: [

                                  // AVATAR
                                  Stack(
                                    children: [
                                      SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: UserAvatar(userId: userId),
                                      ),

                                      if (isSelected)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.blue,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    UserManager.instance.getUsername(userId),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // ================= BOTTOM =================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white12),
                  ),
                ),
                child: Column(
                  children: [

                    // MESSAGE
                    TextField(
                      controller: messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Write a message...",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // SEND BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (selectedUsers.isEmpty || isSending)
                            ? null
                            : () async {
                                setState(() => isSending = true);

                                await widget.onSend(
                                  widget.post,
                                  selectedUsers,
                                  messageController.text.trim(),
                                );

                                if (!mounted) return;

                                setState(() {
                                  isSending = false;
                                  selectedUsers.clear();
                                  messageController.clear();
                                });
                              },
                        child: isSending
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Send"),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}