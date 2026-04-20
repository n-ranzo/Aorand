import 'package:flutter/material.dart';
import 'package:aorandra/core/utils/glass_container.dart';

class StoryPanel extends StatelessWidget {
  final double progress;
  final Function(double) onDrag;
  final VoidCallback onDragEnd;

  const StoryPanel({
    super.key,
    required this.progress,
    required this.onDrag,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    const hiddenX = -120;
    const shownX = 10;

    final x = hiddenX + (shownX - hiddenX) * progress;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      left: x,
      top: 100,
      bottom: 100,
      child: Stack(
        children: [

          GlassContainer(
            height: double.infinity,
            radius: 30,
            child: SizedBox(
              width: 100,
              child: Column(
                children: const [
                  SizedBox(height: 20),
                  Text("Stories", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),

          // CLOSE DRAG
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 40,
            child: GestureDetector(
              onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
              onHorizontalDragEnd: (_) => onDragEnd(),
            ),
          ),
        ],
      ),
    );
  }
}