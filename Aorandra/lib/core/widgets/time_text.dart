import 'package:flutter/material.dart';

/// =============================================
/// TimeText Widget
/// Instagram-style:
/// Updates ONLY when widget rebuilds (refresh)
/// =============================================
class TimeText extends StatelessWidget {
  final String? date;
  final TextStyle? style;

  const TimeText({
    super.key,
    required this.date,
    this.style,
  });

  /// =============================================
  /// Calculate safe difference
  /// =============================================
  Duration _getDifference() {
    if (date == null) return Duration.zero;

    final parsedDate = DateTime.parse(date!).toLocal();
    final diff = DateTime.now().difference(parsedDate);

    // Prevent future-time bug
    if (diff.isNegative) return Duration.zero;

    return diff;
  }

  /// =============================================
  /// Format time
  /// =============================================
  String _formatTime() {
    final diff = _getDifference();

    if (diff.inSeconds < 5) return 'now';

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s';
    }

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    }

    if (diff.inHours < 24) {
      return '${diff.inHours}h';
    }

    if (diff.inDays < 7) {
      return '${diff.inDays}d';
    }

    final parsedDate = DateTime.parse(date!).toLocal();
    return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatTime(),
      style: style ??
          const TextStyle(
            fontSize: 12,
            color: Colors.white54,
          ),
    );
  }
}