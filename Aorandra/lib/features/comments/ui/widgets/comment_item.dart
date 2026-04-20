import 'package:flutter/material.dart';
import 'reply_item.dart';
import '../../data/comment_service.dart';

class CommentItem extends StatefulWidget {
  final Map comment;
  final List allComments;
  final Function(String, String) onReply;
  final VoidCallback onRefresh;

  const CommentItem({
    super.key,
    required this.comment,
    required this.allComments,
    required this.onReply,
    required this.onRefresh,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  final service = CommentService();
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;

    final replies = widget.allComments
        .where((r) => r["parent_comment_id"] == c["id"])
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 COMMENT UI
        Row(
          children: [
            const CircleAvatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c["username"] ?? "user"),
                  Text(c["content"] ?? ""),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Row(
          children: [
            GestureDetector(
              onTap: () async {
                await service.likeComment(
                  comment: c,
                  userId: service.supabase.auth.currentUser!.id,
                );
                widget.onRefresh();
              },
              child: const Text("Like"),
            ),

            const SizedBox(width: 12),

            GestureDetector(
              onTap: () {
                widget.onReply(
                  c["id"],
                  c["username"] ?? "user",
                );
              },
              child: const Text("Reply"),
            ),
          ],
        ),

        // 🔥 REPLIES
        if (replies.isNotEmpty)
          GestureDetector(
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            child: Text(
              expanded
                  ? "Hide replies"
                  : "View ${replies.length} replies",
            ),
          ),

        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: replies.map((r) {
                return ReplyItem(reply: r);
              }).toList(),
            ),
          ),
      ],
    );
  }
}