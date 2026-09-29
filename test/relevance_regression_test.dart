import 'package:flutter_test/flutter_test.dart';
import 'package:career_core/career_core.dart';
import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/features/career/domain/job_filters.dart';

void main() {
  group('M1 Relevance Regression Tests (Clean-room Verified in M7/M13)', () {
    late RelevanceEngine engine;

    setUp(() {
      engine = RelevanceEngine(
        matchingProvider: const FakeMatchingProvider(),
        embeddingProvider: FakeEmbeddingProvider(),
      );
    });

    test(
      '1. Sales Manager posting is rejected as non-engineering and excluded from main feeds',
      () async {
        final job = Job(
          id: 'sales-1',
          title: 'Enterprise Software Sales Manager',
          company: 'SaaS Corp',
          location: 'Remote',
          url: 'https://example.com/job/1',
          source: 'RemoteOK',
          description: 'Sell enterprise software. Knowledge of Python scripts is a plus.',
          skills: 'Sales, Software, Python',
          discoveredAt: DateTime.now(),
          isSaved: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Verify role classification strictly identifies non-engineering sales role
        final family = RoleClassifier.classify(title: job.title, description: job.description);
        expect(family, equals(RoleFamily.sales));
        expect(RoleClassifier.isEngineeringRole(family), isFalse);

        // Verify it is excluded from For you feed
        final forYouFeed = filterJobsList(
          jobs: [job],
          segment: JobSegment.forYou,
        );
        expect(forYouFeed, isEmpty, reason: 'Non-engineering sales manager must never appear in For you feed');

        // Verify it is excluded from Needs review feed
        final reviewFeed = filterJobsList(
          jobs: [job],
          segment: JobSegment.needsReview,
        );
        expect(reviewFeed, isEmpty, reason: 'Non-engineering sales manager must never appear in Needs review feed');
      },
    );

    test(
      '2. Keyword-bait "AI Trainer (Python)" job is rejected as data entry annotation with score < 40',
      () async {
        final job = NormalizedJob.fromRaw(
          id: 'trainer-1',
          rawTitle: 'AI Trainer (Python)',
          rawCompany: 'DataAnnotation Co',
          rawLocation: 'Remote',
          source: 'RemoteOK',
          rawDescription: 'Review code snippets and rate model outputs. Must know basic Python.',
          rawSkills: 'Python',
        );

        const profile = CandidateProfile(
          name: 'Python Candidate',
          currentRole: 'Python Developer',
          roles: ['Python Developer', 'Backend Engineer'],
          primaryRoleFamily: RoleFamily.backend,
          experienceMonths: 24,
          primarySkills: ['Python', 'Django', 'FastAPI'],
        );

        // Check classifier rejects title into dataEntryAnnotation
        expect(job.roleFamily, equals(RoleFamily.dataEntryAnnotation));

        // Evaluate against engine
        final result = await engine.evaluate(job: job, candidate: profile);
        expect(result.isPassed, isFalse);
        expect(result.tier, equals(RelevanceTier.notRelevant));
        expect(result.score, lessThan(40.0));
      },
    );

    test(
      '3. Senior Java Developer job strictly fails for a candidate who only knows JavaScript (Stack mismatch)',
      () async {
        final javaJob = NormalizedJob.fromRaw(
          id: 'java-1',
          rawTitle: 'Senior Java Developer',
          rawCompany: 'Enterprise Systems',
          rawLocation: 'Bengaluru',
          rawSkills: 'Java, Spring Boot',
          rawDescription: 'Senior Java Backend role. Experience with Spring Boot and PostgreSQL required.',
        );

        const jsCandidate = CandidateProfile(
          name: 'Frontend Candidate',
          currentRole: 'Frontend Developer',
          roles: ['Frontend Developer', 'React Developer'],
          primaryRoleFamily: RoleFamily.frontend,
          experienceMonths: 36,
          primarySkills: ['JavaScript', 'TypeScript', 'React', 'CSS'],
          secondarySkills: ['HTML', 'Redux', 'Webpack'],
        );

        final result = await engine.evaluate(job: javaJob, candidate: jsCandidate);
        expect(result.isPassed, isFalse);
        expect(result.tier, equals(RelevanceTier.notRelevant));
        expect(result.matchedSkills, isNot(contains('Java')));
      },
    );

    test(
      '4. Unified Ingestion Relevance Pipeline produces concrete tier and score for every job',
      () async {
        final flutterJob = NormalizedJob.fromRaw(
          id: 'flutter-1',
          rawTitle: 'Flutter Developer',
          rawCompany: 'App Studios',
          rawLocation: 'Bengaluru',
          rawSkills: 'Flutter, Dart, Riverpod',
          rawDescription: 'Build modern mobile apps using Flutter, Dart, Riverpod and SQLite.',
        );

        const flutterCandidate = CandidateProfile(
          name: 'Flutter Dev',
          currentRole: 'Flutter Developer',
          roles: ['Flutter Developer', 'Mobile Engineer'],
          primaryRoleFamily: RoleFamily.mobile,
          experienceMonths: 24,
          primarySkills: ['Flutter', 'Dart', 'Riverpod', 'SQLite'],
        );

        final result = await engine.evaluate(job: flutterJob, candidate: flutterCandidate);
        expect(result.isPassed, isTrue);
        expect(result.tier, isIn([RelevanceTier.highlyRelevant, RelevanceTier.relevant]));
        expect(result.score, greaterThanOrEqualTo(70.0));
        expect(result.explainability.summaryReason, isNotEmpty);
      },
    );
  });
}
