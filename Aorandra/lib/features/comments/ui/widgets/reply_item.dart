import 'package:flutter/material.dart';

class ReplyItem extends StatelessWidget {
  final Map reply;

  const ReplyItem({super.key, required this.reply});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(radius: 12),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reply["username"] ?? "user"),
            Text(reply["content"] ?? ""),
          ],
        )
      ],
    );
  }
}