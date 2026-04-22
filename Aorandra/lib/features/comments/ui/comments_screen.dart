import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../shared/services/interactions/comment_service.dart';
import 'package:aorandra/features/profile/ui/profile_screen.dart'; // Profile navigation
import 'package:share_plus/share_plus.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final ScrollController scrollController;

  // Pass the post/video owner id here
  // Owner replies will always stay visible under the main comment
  final String? postOwnerId;

  const CommentsScreen({
    super.key,
    required this.postId,
    required this.scrollController,
    this.postOwnerId,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController controller = TextEditingController();
  final CommentService service = CommentService();

  List comments = [];
  bool isSending = false;
  String myAvatar = "";

  String? replyingToCommentId;
  String? replyingToUsername;

  // Controls open / close state for normal replies
  final Map<String, bool> expandedReplies = {};

  // ======================
  // INIT STATE
  // ======================
  @override
  void initState() {
    super.initState();
    loadComments();
    loadMyAvatar();

    controller.addListener(() {
      setState(() {});
    });
  }

  // ======================
  // DISPOSE
  // ======================
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ======================
  // FORMAT TIME
  // ======================
  String formatTime(String? date) {
    if (date == null) return "";

    final diff = DateTime.now().difference(DateTime.parse(date));

    if (diff.inSeconds < 60) return "now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}s";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return "${diff.inDays}d";
    return "${(diff.inDays / 7).floor()}w";
  }

  // ======================
  // LOAD COMMENTS
  // ======================
  Future<void> loadComments() async {
    final data = await service.getComments(widget.postId);

    if (mounted) {
      setState(() {
        comments = data;
      });
    }
  }

  // ======================
  // LOAD MY AVATAR
  // ======================
  Future<void> loadMyAvatar() async {
    final user = service.supabase.auth.currentUser;
    if (user == null) return;

    final data = await service.supabase
        .from("profiles")
        .select("avatar_url")
        .eq("id", user.id)
        .single();

    if (mounted) {
      setState(() {
        myAvatar = data["avatar_url"] ?? "";
      });
    }
  }

  // ======================
  // MEDIA OPTIONS
  // ======================
  void openMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.image_outlined, color: Colors.white),
                title: Text(
                  "Send Image",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ListTile(
                leading: Icon(Icons.gif_box_outlined, color: Colors.white),
                title: Text(
                  "Send GIF",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ListTile(
                leading: Icon(Icons.emoji_emotions_outlined, color: Colors.white),
                title: Text(
                  "Sticker",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ======================
  // OPEN PROFILE
  // ======================
  void openProfile(String? userId, String username) {
    if (userId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          userId: userId,
          username: username,
        ),
      ),
    );
  }

  // ======================
  // SEND COMMENT / REPLY
  // ======================
  Future<void> sendComment() async {
    if (isSending) return;

    String text = controller.text.trim();
    if (text.isEmpty) return;

    // Auto prepend @username when replying
    if (replyingToUsername != null) {
      text = "@$replyingToUsername $text";
    }

    setState(() => isSending = true);

    await service.addComment(
      postId: widget.postId,
      content: text,
      parentId: replyingToCommentId,
    );

    controller.clear();

    setState(() {
      replyingToCommentId = null;
      replyingToUsername = null;
    });

    await service.updateCommentsCount(widget.postId);
    await loadComments();

    setState(() => isSending = false);
  }

  // ======================
  // DELETE COMMENT
  // ======================
  Future<void> deleteComment(String id) async {
    await service.deleteComment(id);
    await service.updateCommentsCount(widget.postId);
    await loadComments();
  }

  // ======================
  // LIKE
  // ======================
  Future<void> like(Map comment) async {
    final userId = service.supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      List likedBy = List.from(comment["liked_by"] ?? []);
      List dislikedBy = List.from(comment["disliked_by"] ?? []);

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
        dislikedBy.remove(userId);
      }

      comment["liked_by"] = likedBy;
      comment["disliked_by"] = dislikedBy;
      comment["likes_count"] = likedBy.length;
      comment["dislikes_count"] = dislikedBy.length;
    });

    await service.likeComment(comment: comment, userId: userId);
  }

  // ======================
  // DISLIKE
  // ======================
  Future<void> dislike(Map comment) async {
    final userId = service.supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      List likedBy = List.from(comment["liked_by"] ?? []);
      List dislikedBy = List.from(comment["disliked_by"] ?? []);

      if (dislikedBy.contains(userId)) {
        dislikedBy.remove(userId);
      } else {
        dislikedBy.add(userId);
        likedBy.remove(userId);
      }

      comment["liked_by"] = likedBy;
      comment["disliked_by"] = dislikedBy;
      comment["likes_count"] = likedBy.length;
      comment["dislikes_count"] = dislikedBy.length;
    });

    await service.dislikeComment(comment: comment, userId: userId);
  }

  // ======================
  // BUILD SINGLE REPLY ITEM
  // ======================
Widget buildReplyItem(Map r) {
  final rUser = r["profiles"];
  final String rUsername = rUser?["username"] ?? "user";
  final String rAvatar = rUser?["avatar_url"] ?? "";
  final String? rUserId = rUser?["id"];

  final currentUserId = service.supabase.auth.currentUser?.id;

  final List likedBy =
      r["liked_by"] is List ? List.from(r["liked_by"]) : [];
  final List dislikedBy =
      r["disliked_by"] is List ? List.from(r["disliked_by"]) : [];

  final bool isLiked =
      currentUserId != null && likedBy.contains(currentUserId);
  final bool isDisliked =
      currentUserId != null && dislikedBy.contains(currentUserId);

  final int likesCount = r["likes_count"] ?? 0;
  final int dislikesCount = r["dislikes_count"] ?? 0;

  // ======================
  // HANDLE MENTION
  // ======================
  String content = r["content"] ?? "";
  String? mention;
  String? mentionedUsername;
  String message = content;

  if (content.startsWith("@")) {
    final parts = content.split(" ");
    mention = parts.first; // @username
    mentionedUsername = mention.replaceFirst("@", "");
    message = parts.sublist(1).join(" ");
  }

  return GestureDetector(
    onLongPress: () => _openCommentMenu(r),
    child: Padding(
      padding: const EdgeInsets.only(left: 40, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================
          // AVATAR
          // ======================
          GestureDetector(
            onTap: () => openProfile(rUserId, rUsername),
            child: CircleAvatar(
              radius: 12,
              backgroundImage:
                  rAvatar.isNotEmpty ? NetworkImage(rAvatar) : null,
              backgroundColor: Colors.white24,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ======================
                // USERNAME
                // ======================
                GestureDetector(
                  onTap: () => openProfile(rUserId, rUsername),
                  child: Text(
                    rUsername,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                // ======================
                // MESSAGE + MENTION
                // ======================
                RichText(
                  text: TextSpan(
                    children: [
                      if (mention != null)
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () async {
                              if (mentionedUsername == null) return;

                              final user = await service.supabase
                                  .from("profiles")
                                  .select("id, username")
                                  .eq("username", mentionedUsername)
                                  .maybeSingle();

                              if (user != null) {
                                openProfile(
                                  user["id"],
                                  user["username"],
                                );
                              }
                            },
                            child: Text(
                              "$mention ",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                      TextSpan(
                        text: message,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // ======================
                // ACTIONS
                // ======================
                Row(
                  children: [
                    // ❤️ LIKE
                    GestureDetector(
                      onTap: () => like(r),
                      child: Icon(
                        isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 14,
                        color:
                            isLiked ? Colors.red : Colors.white54,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$likesCount",
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // 👎 DISLIKE
                    GestureDetector(
                      onTap: () => dislike(r),
                      child: Icon(
                        isDisliked
                            ? Icons.thumb_down
                            : Icons.thumb_down_outlined,
                        size: 14,
                        color: isDisliked
                            ? Colors.blue
                            : Colors.white54,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$dislikesCount",
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 🔁 REPLY (nested replies fix)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          replyingToCommentId =
                              r["parent_comment_id"] == null
                                  ? r["id"]
                                  : r["parent_comment_id"];

                          replyingToUsername = rUsername;
                        });
                      },
                      child: const Text(
                        "Reply",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  

 void _openCommentMenu(Map comment) {
  final currentUserId = service.supabase.auth.currentUser?.id;
  final bool isMe = comment['profile_id'] == currentUserId;

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) {
      return GestureDetector(
        onTap: () => Navigator.pop(context), // 🔥 اضغط برا = سكّر
        child: Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {}, // 🔥 يمنع الإغلاق عند الضغط على المينيو نفسه
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: 280,
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),

                        // ======================
                        // SHARE
                        // ======================
                        _menuItem(Icons.send_outlined, "Share", () async {
                          Navigator.pop(context);
                          final text = comment['content'] ?? '';
                          await Share.share(text);
                        }),

                        // ======================
                        // OWNER OPTIONS
                        // ======================
                        if (isMe) ...[
                          _menuItem(Icons.edit_outlined, "Edit", () {
                            Navigator.pop(context);
                            openEditCommentDialog(comment);
                          }),

                          _menuItem(
                            Icons.delete_outline,
                            "Delete",
                            () async {
                              Navigator.pop(context);
                              if (comment['id'] != null) {
                                await deleteComment(comment['id']);
                                await loadComments();
                              }
                            },
                            color: Colors.redAccent,
                          ),
                        ],

                        // ======================
                        // OTHER USER OPTIONS
                        // ======================
                        if (!isMe) ...[
                          _menuItem(Icons.block_outlined, "Block", () async {
                            Navigator.pop(context);
                            final userId = comment['profile_id'];
                            if (userId != null) {
                              await service.blockUser(userId);
                            }
                          }),

                          _menuItem(
                            Icons.flag_outlined,
                            "Report",
                            () async {
                              Navigator.pop(context);
                              if (comment['id'] != null) {
                                await service.reportComment(comment['id']);
                              }
                            },
                            color: Colors.redAccent,
                          ),
                        ],

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

void openEditCommentDialog(Map comment) {
  // ======================
  // ORIGINAL CONTENT
  // ======================
  String content = comment['content'] ?? "";

  String? mention;
  String message = content;

  // ======================
  // SPLIT @MENTION FROM TEXT
  // ======================
  if (content.startsWith("@")) {
    final parts = content.split(" ");
    mention = parts.first; // @username
    message = parts.sublist(1).join(" "); // rest
  }

  // ======================
  // CONTROLLER (ONLY MESSAGE)
  // ======================
  final TextEditingController controller =
      TextEditingController(text: message);

  // ======================
  // SHOW GLASS DIALOG
  // ======================
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),

        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),

            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),

              child: Container(
                width: 260, // 🔥 أصغر من AlertDialog
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ======================
                    // TITLE
                    // ======================
                    const Text(
                      "Edit Comment",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ======================
                    // INPUT FIELD
                    // ======================
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: controller,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,

                        decoration: const InputDecoration(
                          hintText: "Edit your comment...",
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ======================
                    // ACTION BUTTONS
                    // ======================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [

                        // CANCEL
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(width: 18),

                        // SAVE
                        GestureDetector(
                          onTap: () async {
                            final String newText =
                                controller.text.trim();

                            if (newText.isEmpty) return;

                            // ======================
                            // FINAL CONTENT (KEEP MENTION)
                            // ======================
                            final String finalContent =
                                mention != null
                                    ? "$mention $newText"
                                    : newText;

                            // ======================
                            // UPDATE DATABASE
                            // ======================
                            await service.updateComment(
                              commentId: comment['id'],
                              content: finalContent,
                            );

                            if (!mounted) return;

                            Navigator.pop(context);

                            await loadComments();
                          },
                          child: const Text(
                            "Save",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _menuItem(
  IconData icon,
  String text,
  VoidCallback onTap, {
  Color color = Colors.white,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 14),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
  );
}

  // ======================
  // UI
  // ======================
  @override
  Widget build(BuildContext context) {
    final isTyping = controller.text.trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 8),

          // Title
          const Text(
            "Comments",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),

          // ======================
          // COMMENTS LIST
          // ======================
          Expanded(
            child: comments.isEmpty
                ? const Center(
                    child: Text(
                      "No comments yet",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      final user = c["profiles"];

                      final avatar = user?["avatar_url"] ?? "";
                      final username = user?["username"] ?? "user";
                      final userId = user?["id"];

                      final likesCount = c["likes_count"] ?? 0;
                      final dislikesCount = c["dislikes_count"] ?? 0;

                      final currentUserId =
                          service.supabase.auth.currentUser?.id;

                      final likedBy = c["liked_by"] is List
                          ? List.from(c["liked_by"])
                          : [];
                      final dislikedBy = c["disliked_by"] is List
                          ? List.from(c["disliked_by"])
                          : [];

                      final isLiked = currentUserId != null &&
                          likedBy.contains(currentUserId);
                      final isDisliked = currentUserId != null &&
                          dislikedBy.contains(currentUserId);

                      final replies = comments
                          .where((r) => r["parent_comment_id"] == c["id"])
                          .toList();

                      // Skip replies in main list
                      if (c["parent_comment_id"] != null) {
                        return const SizedBox();
                      }

                      // Owner replies always visible
                      final ownerReplies = widget.postOwnerId == null
                          ? <dynamic>[]
                          : replies
                              .where((r) => r["profile_id"] == widget.postOwnerId)
                              .toList();

                      // Normal replies go inside collapse / expand
                      final normalReplies = widget.postOwnerId == null
                          ? replies
                          : replies
                              .where((r) => r["profile_id"] != widget.postOwnerId)
                              .toList();

                      final isExpanded = expandedReplies[c["id"]] ?? false;

                      return GestureDetector(
                        onLongPress: () => _openCommentMenu(c), 
                        child: Padding(
                         padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                             vertical: 8,
                         ),
                         child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main comment avatar
                            GestureDetector(
                              onTap: () => openProfile(userId, username),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundImage: avatar.isNotEmpty
                                    ? NetworkImage(avatar)
                                    : null,
                                backgroundColor: Colors.white24,
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Main comment content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Username + time
                                  GestureDetector(
                                    onTap: () => openProfile(userId, username),
                                    child: Row(
                                      children: [
                                        Text(
                                          username,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          formatTime(c["created_at"]),
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  // Comment text
                                  Text(
                                    c["content"] ?? "",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // Like / dislike row
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => like(c),
                                        child: Icon(
                                          isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 16,
                                          color: isLiked
                                              ? Colors.red
                                              : Colors.white54,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$likesCount",
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () => dislike(c),
                                        child: Icon(
                                          isDisliked
                                              ? Icons.thumb_down
                                              : Icons.thumb_down_outlined,
                                          size: 16,
                                          color: isDisliked
                                              ? Colors.blue
                                              : Colors.white54,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$dislikesCount",
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 4),

                                  // Reply action
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        replyingToCommentId = c["id"];
                                        replyingToUsername = username;
                                      });
                                    },
                                    child: const Text(
                                      "Reply",
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                  // Owner replies always visible
                                  if (ownerReplies.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: ownerReplies
                                          .map<Widget>((r) => buildReplyItem(r))
                                          .toList(),
                                    ),
                                  ],

                                  // Normal replies hidden / shown like Instagram
                                  if (normalReplies.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          expandedReplies[c["id"]] = !isExpanded;
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 1,
                                            color: Colors.white24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isExpanded
                                                ? "Hide replies"
                                                : "View ${normalReplies.length} more repl${normalReplies.length == 1 ? "y" : "ies"}",
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  if (normalReplies.isNotEmpty && isExpanded) ...[
                                    const SizedBox(height: 6),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: normalReplies
                                          .map<Widget>((r) => buildReplyItem(r))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),

          // ======================
          // INPUT + REPLY PREVIEW
          // ======================
          SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(
                left: 10,
                right: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                top: 6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reply preview
                  if (replyingToUsername != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(
                            "Replying to @$replyingToUsername",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                replyingToCommentId = null;
                                replyingToUsername = null;
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Input row
                  Row(
                    children: [
                      // Open media sheet from avatar
                      GestureDetector(
                        onTap: openMediaOptions,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white24,
                          backgroundImage:
                              myAvatar.isNotEmpty ? NetworkImage(myAvatar) : null,
                        ),
                      ),
                      const SizedBox(width: 10),

                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Add a comment...",
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.08),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      if (isTyping)
                        GestureDetector(
                          onTap: isSending ? null : sendComment,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: isSending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send,
                                    color: Colors.black,
                                    size: 18,
                                  ),
                          ),
                        ),
                    ],
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