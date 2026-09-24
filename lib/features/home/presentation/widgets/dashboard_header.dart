import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../onboarding/providers/onboarding_provider.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    final theme = Theme.of(context);
    final greeting = _getGreeting();
    final todayFormatted = DateFormatter.formatHeaderDate(DateTime.now());

    final userName = profileAsync.value?.name ?? 'Engineer';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          todayFormatted.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$greeting, $userName',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }
}

