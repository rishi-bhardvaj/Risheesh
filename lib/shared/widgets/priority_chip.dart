import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class PriorityChip extends StatelessWidget {
  final TaskPriority priority;

  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (priority) {
      case TaskPriority.high:
        bg = const Color(0xFFEF4444).withOpacity(0.15);
        fg = const Color(0xFFEF4444);
        break;
      case TaskPriority.medium:
        bg = const Color(0xFFF59E0B).withOpacity(0.15);
        fg = const Color(0xFFF59E0B);
        break;
      case TaskPriority.low:
        bg = const Color(0xFF10B981).withOpacity(0.15);
        fg = const Color(0xFF10B981);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

