import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/notification_service.dart';
import '../services/automation_engine.dart';
import '../services/automation_scheduler.dart';

final notificationServiceProvider = Provider<AppNotificationService>((ref) {
  return AppNotificationService();
});

final automationEngineProvider = Provider<AutomationEngine>((ref) {
  final db = ref.watch(databaseProvider);
  final notifService = ref.watch(notificationServiceProvider);
  final engine = AutomationEngine(db: db, notificationService: notifService);
  return engine;
});

final automationSchedulerProvider = Provider<AutomationScheduler>((ref) {
  final engine = ref.watch(automationEngineProvider);
  return AutomationScheduler(engine: engine);
});

final automationRulesStreamProvider = StreamProvider<List<AutomationRule>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllAutomationRules();
});

final recentRunsStreamProvider = StreamProvider<List<AutomationRun>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchRecentRuns();
});

final pendingActionsStreamProvider = StreamProvider<List<AutomationAction>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllPendingActions();
});

final notificationSettingsStreamProvider = StreamProvider<NotificationSetting?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchNotificationSettings();
});

final jobSourceConfigsStreamProvider = StreamProvider<List<JobSourceConfig>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllJobSources();
});

class AutomationActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase db;

  AutomationActionsNotifier(this.db) : super(const AsyncValue.data(null));

  Future<void> dismissAction(String actionId) async {
    state = const AsyncValue.loading();
    try {
      await db.updateAutomationActionStatus(actionId, 'DISMISSED');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resolveAction(String actionId) async {
    state = const AsyncValue.loading();
    try {
      await db.updateAutomationActionStatus(actionId, 'COMPLETED');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final automationActionsNotifierProvider =
    StateNotifierProvider<AutomationActionsNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseProvider);
  return AutomationActionsNotifier(db);
});
