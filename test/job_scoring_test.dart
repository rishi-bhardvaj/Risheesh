import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/features/career/services/job_scoring_service.dart';

void main() {
  test('JobScoringService scores jobs in isolate and updates database', () async {
    final db = AppDatabase(NativeDatabase.memory());

    // Insert user profile
    await db.registerNewProfile(
      id: 'profile-1',
      name: 'Rishi',
      currentRole: 'Senior Flutter Engineer',
    );

    // Insert a Flutter job
    final job = Job(
      id: 'job-flutter-1',
      title: 'Senior Flutter Engineer',
      company: 'TechCorp',
      location: 'Remote',
      url: 'https://example.com/job1',
      source: 'RemoteOK',
      description: 'We are looking for a Senior Flutter Developer with Dart and REST API experience.',
      skills: 'Flutter, Dart, Mobile, REST',
      discoveredAt: DateTime.now(),
      isSaved: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await db.into(db.jobs).insert(job);

    final profile = await db.getProfile();
    await JobScoringService.reScoreAllJobs(db, profile: profile);

    final updated = await (db.select(db.jobs)..where((j) => j.id.equals(job.id))).getSingle();

    expect(updated.matchScore, isNotNull);
    expect(updated.matchScore!, greaterThanOrEqualTo(75));
    expect(updated.matchTier, isIn(['STRONG_MATCH', 'RELEVANT']));
    expect(updated.isRemote, isTrue);

    await db.close();
  });
}
