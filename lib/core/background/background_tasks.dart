import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../database/app_database.dart';
import '../notifications/notification_service.dart';
import '../../features/career/domain/job_search_criteria_builder.dart';
import '../../features/career/services/job_scoring_service.dart';
import '../../features/career/services/live_job_discovery_service.dart';

const String kPeriodicJobSyncTask = 'com.risheesh.sync_jobs';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == kPeriodicJobSyncTask) {
        final db = AppDatabase();
        final notifService = NotificationService(db);

        final profile = await db.getProfile();
        final resume = await db.getPrimaryResume();
        final candidate = JobScoringService.buildCandidateProfile(
          profile: profile,
          primaryResume: resume,
        );

        final discovery = LiveJobDiscoveryService(db: db);
        final criteria = JobSearchCriteria(
          roleQueries: candidate.primarySkills.isNotEmpty
              ? [candidate.currentRole, ...candidate.primarySkills.take(2)]
              : ['Flutter', 'Software Engineer'],
          topSkills: candidate.primarySkills,
          remoteOnly: profile?.remotePreference == 'remote',
        );

        final result = await discovery.discoverAndSyncJobs(criteria: criteria);

        if (result.newJobsSaved > 0) {
          // Score newly inserted jobs
          await JobScoringService.reScoreAllJobs(db, profile: profile, primaryResume: resume);

          // Check if any scored job is a strong match
          final topJobs = await (db.select(db.jobs)
                ..where((j) => j.matchScore.isBiggerOrEqualValue(75))
                ..orderBy([(j) => OrderingTerm.desc(j.matchScore)])
                ..limit(1))
              .get();

          if (topJobs.isNotEmpty) {
            final top = topJobs.first;
            await notifService.notifyMatchingJobs(
              count: result.newJobsSaved,
              topTitle: top.title,
              company: top.company,
              topScore: top.matchScore ?? 80,
            );
          }
        }

        // Check habit completion if after 6 PM
        final now = DateTime.now();
        if (now.hour >= 18) {
          await notifService.checkAndNotifyHabits();
        }

        await db.close();
      }
      return true;
    } catch (e) {
      debugPrint('[BackgroundTasks] Error executing background task: $e');
      return true;
    }
  });
}

class BackgroundTasksManager {
  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: kDebugMode,
        );

        await Workmanager().registerPeriodicTask(
          kPeriodicJobSyncTask,
          kPeriodicJobSyncTask,
          frequency: const Duration(hours: 3),
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: true,
          ),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        );
      } catch (e) {
        debugPrint('[BackgroundTasksManager] Failed to schedule worker: $e');
      }
    }
  }
}
