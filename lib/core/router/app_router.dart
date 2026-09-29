import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/career/presentation/application_details_screen.dart';
import '../../features/career/presentation/career_profile_view.dart';
import '../../features/career/presentation/career_screen.dart';
import '../../features/career/presentation/job_details_screen.dart';
import '../../features/freelance/presentation/business_lead_screen.dart';
import '../../features/freelance/presentation/client_details_screen.dart';
import '../../features/freelance/presentation/freelance_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/settings/presentation/ai_keys_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/track/presentation/dsa_problem_details_screen.dart';
import '../../features/track/presentation/track_screen.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../ai/ai_keys.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Re-runs redirects when onboarding or AI-key state changes, without
/// rebuilding the router (which would reset navigation).
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(onboardingCompletedProvider, (_, __) => refresh.ping());
  ref.listen(aiKeysProvider, (_, __) => refresh.ping());
  ref.listen(aiSetupSkippedThisSessionProvider, (_, __) => refresh.ping());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final onboarded = ref.read(onboardingCompletedProvider);
      final loc = state.matchedLocation;
      if (!onboarded) return loc == '/onboarding' ? null : '/onboarding';
      if (loc == '/onboarding') return '/home';

      // Ask for the AI keys on every launch until the required ones are set
      // (the user can skip for the current session).
      final needsKeys = !ref.read(aiKeysProvider).hasRequired && !ref.read(aiSetupSkippedThisSessionProvider);
      if (needsKeys && loc != '/ai-setup') return '/ai-setup';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/ai-setup', builder: (_, __) => const AiKeysScreen(firstRun: true)),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppScaffold(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/career', builder: (_, __) => const CareerScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/freelance', builder: (_, __) => const FreelanceScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/track', builder: (_, __) => const TrackScreen())]),
        ],
      ),
      GoRoute(
        path: '/career/job/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => JobDetailsScreen(jobId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/career/application/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => ApplicationDetailsScreen(applicationId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/career/profile', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const CareerProfileView()),
      GoRoute(
        path: '/freelance/business/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => BusinessLeadScreen(leadId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/freelance/client/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => ClientDetailsScreen(clientId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/track/dsa/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => DSAProblemDetailsScreen(problemId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/settings', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/settings/ai', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const AiKeysScreen()),
    ],
  );
});
