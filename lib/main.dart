import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/ai/ai_keys.dart';
import 'core/background/background_tasks.dart';
import 'core/constants/app_constants.dart';
import 'core/diagnostics/crash_reporter.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CrashReporter.instance.initialize();
  await NotificationService.initialize();
  await BackgroundTasksManager.initialize();

  // Initialize SharedPreferences for local configuration
  final sharedPreferences = await SharedPreferences.getInstance();
  // Keys come from the Android keystore; loaded up front so the router can
  // decide synchronously whether to show the AI key setup screen.
  final aiKeys = await SecureAiKeyStore().load();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        initialAiKeysProvider.overrideWithValue(aiKeys),
      ],
      child: const RisheeshApp(),
    ),
  );
}

class RisheeshApp extends ConsumerWidget {
  const RisheeshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
