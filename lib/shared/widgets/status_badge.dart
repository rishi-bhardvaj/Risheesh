import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final dynamic status; // ApplicationStatus or String

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final ApplicationStatus appStatus = status is ApplicationStatus
        ? status as ApplicationStatus
        : ApplicationStatus.fromString(status?.toString());

    Color bg;
    Color fg;

    switch (appStatus) {
      case ApplicationStatus.saved:
        bg = const Color(0xFF64748B).withOpacity(0.15);
        fg = const Color(0xFF94A3B8);
        break;
      case ApplicationStatus.applying:
        bg = const Color(0xFF0EA5E9).withOpacity(0.15);
        fg = const Color(0xFF0EA5E9);
        break;
      case ApplicationStatus.applied:
        bg = const Color(0xFF3B82F6).withOpacity(0.15);
        fg = const Color(0xFF3B82F6);
        break;
      case ApplicationStatus.screening:
        bg = const Color(0xFF8B5CF6).withOpacity(0.15);
        fg = const Color(0xFF8B5CF6);
        break;
      case ApplicationStatus.interview:
        bg = const Color(0xFFF59E0B).withOpacity(0.15);
        fg = const Color(0xFFF59E0B);
        break;
      case ApplicationStatus.technical:
        bg = const Color(0xFF6366F1).withOpacity(0.15);
        fg = const Color(0xFF6366F1);
        break;
      case ApplicationStatus.hr:
        bg = const Color(0xFF14B8A6).withOpacity(0.15);
        fg = const Color(0xFF14B8A6);
        break;
      case ApplicationStatus.offer:
        bg = const Color(0xFF10B981).withOpacity(0.15);
        fg = const Color(0xFF10B981);
        break;
      case ApplicationStatus.rejected:
        bg = const Color(0xFFEF4444).withOpacity(0.15);
        fg = const Color(0xFFEF4444);
        break;
      case ApplicationStatus.withdrawn:
        bg = const Color(0xFF64748B).withOpacity(0.15);
        fg = const Color(0xFF64748B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        appStatus.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ApplicationStatusBadge extends StatelessWidget {
  final dynamic status;

  const ApplicationStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StatusBadge(status: status);
  }
}

class ProjectStatusBadge extends StatelessWidget {
  final dynamic status; // ProjectStatus or String

  const ProjectStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final ProjectStatus projStatus = status is ProjectStatus
        ? status as ProjectStatus
        : ProjectStatus.fromString(status?.toString());

    Color bg;
    Color fg;

    switch (projStatus) {
      case ProjectStatus.idea:
        bg = const Color(0xFF8B5CF6).withOpacity(0.15);
        fg = const Color(0xFF8B5CF6);
        break;
      case ProjectStatus.planned:
        bg = const Color(0xFF3B82F6).withOpacity(0.15);
        fg = const Color(0xFF3B82F6);
        break;
      case ProjectStatus.inProgress:
        bg = const Color(0xFFF59E0B).withOpacity(0.15);
        fg = const Color(0xFFF59E0B);
        break;
      case ProjectStatus.paused:
        bg = const Color(0xFF64748B).withOpacity(0.15);
        fg = const Color(0xFF94A3B8);
        break;
      case ProjectStatus.completed:
        bg = const Color(0xFF10B981).withOpacity(0.15);
        fg = const Color(0xFF10B981);
        break;
      case ProjectStatus.archived:
        bg = const Color(0xFF64748B).withOpacity(0.15);
        fg = const Color(0xFF64748B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        projStatus.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
