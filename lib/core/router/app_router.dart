import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/career/presentation/application_details_screen.dart';
import '../../features/career/presentation/career_profile_view.dart';
import '../../features/career/presentation/career_screen.dart';
import '../../features/career/presentation/job_details_screen.dart';
import '../../features/freelance/presentation/client_details_screen.dart';
import '../../features/freelance/presentation/freelance_screen.dart';
import '../../features/freelance/presentation/lead_details_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/track/presentation/track_screen.dart';
import '../../features/work/presentation/eod_history_screen.dart';
import '../../features/work/presentation/project_details_screen.dart';
import '../../features/work/presentation/work_note_details_screen.dart';
import '../../features/work/presentation/work_screen.dart';
import '../../shared/widgets/app_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _careerNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'career');
final _workNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'work');
final _freelanceNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'freelance');
final _trackNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'track');

final routerProvider = Provider<GoRouter>((ref) {
  final isOnboardingCompleted = ref.watch(onboardingCompletedProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: isOnboardingCompleted ? '/home' : '/onboarding',
    redirect: (context, state) {
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';

      if (!isOnboardingCompleted && !isGoingToOnboarding) {
        return '/onboarding';
      }
      if (isOnboardingCompleted && isGoingToOnboarding) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Home
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 2: Career
          StatefulShellBranch(
            navigatorKey: _careerNavigatorKey,
            routes: [
              GoRoute(
                path: '/career',
                builder: (context, state) => const CareerScreen(),
              ),
            ],
          ),
          // Branch 3: Work
          StatefulShellBranch(
            navigatorKey: _workNavigatorKey,
            routes: [
              GoRoute(
                path: '/work',
                builder: (context, state) => const WorkScreen(),
              ),
            ],
          ),
          // Branch 4: Freelance
          StatefulShellBranch(
            navigatorKey: _freelanceNavigatorKey,
            routes: [
              GoRoute(
                path: '/freelance',
                builder: (context, state) => const FreelanceScreen(),
              ),
            ],
          ),
          // Branch 5: Track
          StatefulShellBranch(
            navigatorKey: _trackNavigatorKey,
            routes: [
              GoRoute(
                path: '/track',
                builder: (context, state) => const TrackScreen(),
              ),
            ],
          ),
        ],
      ),
      // Career Deep Routes
      GoRoute(
        path: '/career/job/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => JobDetailsScreen(jobId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/career/application/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ApplicationDetailsScreen(applicationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/career/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CareerProfileView(),
      ),
      // Work Deep Routes
      GoRoute(
        path: '/work/project/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ProjectDetailsScreen(projectId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/work/note/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => WorkNoteDetailsScreen(noteId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/work/eod-history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EODHistoryScreen(),
      ),
      // Freelance Deep Routes
      GoRoute(
        path: '/freelance/lead/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LeadDetailsScreen(leadId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/freelance/client/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ClientDetailsScreen(clientId: state.pathParameters['id']!),
      ),
      // Settings Route
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
