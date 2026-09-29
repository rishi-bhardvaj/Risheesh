import 'package:flutter/material.dart';

import '../../core/network/feed_utils.dart';
import '../../core/theme/app_theme.dart';

/// Pulsing placeholder card shown while a live feed loads for the first time.
class SkeletonCard extends StatefulWidget {
  final int lines;

  const SkeletonCard({super.key, this.lines = 3});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
          widthFactor: widthFactor,
          alignment: Alignment.centerLeft,
          child: Container(
            height: height,
            decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6)),
          ),
        );

    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_controller),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(0.7, 16),
              const SizedBox(height: 10),
              bar(0.45, 12),
              for (var i = 0; i < widget.lines; i++) ...[
                const SizedBox(height: 10),
                bar(i.isEven ? 0.9 : 0.6, 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum BannerTone { error, warning, info }

/// Inline banner with an optional Retry action, used for feed failures.
class StatusBanner extends StatelessWidget {
  final BannerTone tone;
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onDetails;
  final String detailsLabel;

  const StatusBanner({
    super.key,
    required this.tone,
    required this.title,
    this.message,
    this.onRetry,
    this.onDetails,
    this.detailsLabel = 'Details',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (tone) {
      BannerTone.error => AppTheme.error,
      BannerTone.warning => AppTheme.warning,
      BannerTone.info => theme.colorScheme.primary,
    };
    final icon = switch (tone) {
      BannerTone.error => Icons.cloud_off_rounded,
      BannerTone.warning => Icons.warning_amber_rounded,
      BannerTone.info => Icons.info_outline_rounded,
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                if (message != null) ...[
                  const SizedBox(height: 2),
                  Text(message!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
                if (onRetry != null || onDetails != null)
                  Wrap(
                    spacing: 4,
                    children: [
                      if (onRetry != null)
                        TextButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry'),
                        ),
                      if (onDetails != null) TextButton(onPressed: onDetails, child: Text(detailsLabel)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet listing every upstream source and whether it succeeded.
Future<void> showSourceStatusSheet(BuildContext context, List<SourceStatus> sources) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      final sorted = [...sources]..sort((a, b) => (a.ok ? 1 : 0).compareTo(b.ok ? 1 : 0));
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text('Source status', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final s in sorted)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  s.ok ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: s.ok ? AppTheme.success : AppTheme.error,
                ),
                title: Text(s.label),
                subtitle: Text(s.ok ? '${s.itemCount} items · ${s.elapsed.inMilliseconds} ms' : s.error!),
              ),
          ],
        ),
      );
    },
  );
}

/// Small rounded label used for sources, tags and metadata on cards.
class MetaChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const MetaChip({super.key, required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = color ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (color ?? theme.colorScheme.onSurface).withValues(alpha: color == null ? 0.06 : 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
