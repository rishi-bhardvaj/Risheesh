import 'package:test/test.dart';
import 'package:career_core/career_core.dart';

void main() {
  group('Relevance Corpus & Precision Verification (M7 & 12.2)', () {
    // Profile A: Mobile / Flutter Engineer in Bengaluru
    final candidateA = CandidateProfile(
      name: 'Mobile Candidate',
      currentRole: 'Flutter Developer',
      roles: const ['Flutter Developer', 'Mobile Engineer'],
      primaryRoleFamily: RoleFamily.mobile,
      adjacentRoleFamilies: const [RoleFamily.fullstack, RoleFamily.frontend],
      experienceMonths: 36,
      experienceLevel: ExperienceLevel.mid,
      currentLocation: 'Bengaluru',
      preferredLocations: const ['Bengaluru'],
      remotePreference: RemotePreferenceMode.any,
      primarySkills: const ['Flutter', 'Dart', 'Riverpod', 'SQLite', 'REST'],
      secondarySkills: const ['Firebase', 'Kotlin', 'Git'],
      familiarSkills: const ['Android', 'iOS', 'Clean Architecture'],
      countries: const ['IN'],
    );

    // Profile B: Java Backend Developer in Pune
    final candidateB = CandidateProfile(
      name: 'Backend Candidate',
      currentRole: 'Java Backend Engineer',
      roles: const ['Backend Engineer', 'Java Developer'],
      primaryRoleFamily: RoleFamily.backend,
      adjacentRoleFamilies: const [RoleFamily.fullstack, RoleFamily.devopsSrePlatform],
      experienceMonths: 48,
      experienceLevel: ExperienceLevel.mid,
      currentLocation: 'Pune',
      preferredLocations: const ['Pune', 'Bengaluru'],
      remotePreference: RemotePreferenceMode.any,
      primarySkills: const ['Java', 'Spring Boot', 'PostgreSQL', 'REST', 'Docker'],
      secondarySkills: const ['Angular', 'Kubernetes', 'Microservices'],
      familiarSkills: const ['SQL', 'Git', 'Linux'],
      countries: const ['IN'],
    );

    final engine = RelevanceEngine(
      matchingProvider: const FakeMatchingProvider(),
      embeddingProvider: FakeEmbeddingProvider(),
    );

    test('Corpus evaluation: 100% precision for Profile A (no unrelated jobs in HIGH or RELEVANT)', () async {
      final corpus = <(NormalizedJob, RelevanceTier, String)>[
        // 1. Strong Match
        (
          NormalizedJob.fromRaw(
            id: 'job-1',
            rawTitle: 'Senior Flutter Developer',
            rawCompany: 'Tech Corp',
            rawLocation: 'Bengaluru',
            rawSkills: 'Flutter, Dart, Riverpod, REST',
            rawDescription: 'Requirements:\n• 3+ years experience with Flutter and Dart\n• Riverpod and SQLite\nNice to have:\n• Kotlin',
          ),
          RelevanceTier.highlyRelevant,
          'Strong Flutter match',
        ),
        // 2. Unrelated Non-Engineering: Sales Manager
        (
          NormalizedJob.fromRaw(
            id: 'job-2',
            rawTitle: 'Software Sales Manager',
            rawCompany: 'SaaS Giant',
            rawLocation: 'Remote',
            rawSkills: 'Sales, Python, Cloud',
            rawDescription: 'Sell software to enterprise clients. Knowledge of Python scripts is good.',
          ),
          RelevanceTier.notRelevant,
          'Sales role',
        ),
        // 3. Unrelated Non-Engineering: AI Trainer
        (
          NormalizedJob.fromRaw(
            id: 'job-3',
            rawTitle: 'AI Trainer – Python',
            rawCompany: 'Annotation Inc',
            rawLocation: 'Remote',
            rawSkills: 'Python',
            rawDescription: 'Label and rate AI models on code accuracy.',
          ),
          RelevanceTier.notRelevant,
          'Data annotation role',
        ),
        // 4. Unrelated Engineering: Java Backend (Candidate A is Mobile)
        (
          NormalizedJob.fromRaw(
            id: 'job-4',
            rawTitle: 'Senior Java Backend Engineer',
            rawCompany: 'Bank Systems',
            rawLocation: 'Bengaluru',
            rawSkills: 'Java, Spring Boot',
            rawDescription: 'Requirements:\n• 4+ years of Core Java and Spring Boot\n• Microservices',
          ),
          RelevanceTier.notRelevant,
          'Java backend mismatch for Flutter candidate',
        ),
        // 5. Unrelated: Civil Engineer
        (
          NormalizedJob.fromRaw(
            id: 'job-5',
            rawTitle: 'Civil Engineer – AutoCAD',
            rawCompany: 'Infra Builders',
            rawLocation: 'Bengaluru',
            rawDescription: 'Designing civil structures and managing construction.',
          ),
          RelevanceTier.notRelevant,
          'Civil engineering role',
        ),
        // 6. Mandatory Missing Stack: iOS Only (SwiftUI mandatory)
        (
          NormalizedJob.fromRaw(
            id: 'job-6',
            rawTitle: 'iOS Engineer (Swift/SwiftUI required)',
            rawCompany: 'Apple Devs',
            rawLocation: 'Remote',
            rawSkills: 'Swift, SwiftUI',
            rawDescription: 'Requirements:\n• 3+ years pure native iOS\n• Swift and SwiftUI required',
          ),
          RelevanceTier.notRelevant,
          'Lacks mandatory Swift/SwiftUI from title & reqs',
        ),
        // 7. Remote Region Restriction: US Only
        (
          NormalizedJob.fromRaw(
            id: 'job-7',
            rawTitle: 'Flutter Engineer',
            rawCompany: 'US Startup',
            rawLocation: 'Remote',
            rawSkills: 'Flutter, Dart',
            rawDescription: 'Remote role. US ONLY. Must be authorized to work in the United States without sponsorship.',
          ),
          RelevanceTier.notRelevant,
          'US only remote restriction',
        ),
        // 8. Good match with missing PREFERRED skill (should still be RELEVANT)
        (
          NormalizedJob.fromRaw(
            id: 'job-8',
            rawTitle: 'Mobile Engineer (Flutter)',
            rawCompany: 'Fintech Hub',
            rawLocation: 'Bengaluru',
            rawSkills: 'Flutter, Dart, SQLite',
            rawDescription: 'Requirements:\n• Flutter and Dart\nNice to have:\n• GraphQL\n• AWS',
          ),
          RelevanceTier.relevant,
          'Missing preferred GraphQL is not a disqualifier',
        ),
      ];

      for (final (job, expectedTier, reason) in corpus) {
        final eval = await engine.evaluate(job: job, candidate: candidateA);

        if (expectedTier == RelevanceTier.notRelevant) {
          expect(
            eval.isPassed,
            isFalse,
            reason: 'Job "${job.title}" should be NOT_RELEVANT ($reason), but got ${eval.tier.name} with score ${eval.score}',
          );
        } else if (expectedTier == RelevanceTier.highlyRelevant) {
          expect(
            eval.tier == RelevanceTier.highlyRelevant || eval.tier == RelevanceTier.relevant,
            isTrue,
            reason: 'Job "${job.title}" should pass, got ${eval.tier.name}',
          );
          expect(eval.explainability.summaryReason, isNotEmpty);
        }
      }
    });

    test('Corpus evaluation: Profile B (Java backend) matches Java job and rejects Flutter', () async {
      final javaJob = NormalizedJob.fromRaw(
        id: 'job-java',
        rawTitle: 'Senior Java Backend Engineer',
        rawCompany: 'Enterprise Services',
        rawLocation: 'Pune',
        rawSkills: 'Java, Spring Boot, PostgreSQL, Docker',
        rawDescription: 'Requirements:\n• Java and Spring Boot\n• PostgreSQL and Docker required',
      );

      final flutterJob = NormalizedJob.fromRaw(
        id: 'job-flutter',
        rawTitle: 'Flutter Developer',
        rawCompany: 'App Studios',
        rawLocation: 'Pune',
        rawSkills: 'Flutter, Dart',
        rawDescription: 'Requirements:\n• Flutter and Dart mobile apps',
      );

      final evalJava = await engine.evaluate(job: javaJob, candidate: candidateB);
      expect(evalJava.isPassed, isTrue, reason: 'Java candidate should match Java job');
      expect(evalJava.explainability.header, contains('MATCH'));

      final evalFlutter = await engine.evaluate(job: flutterJob, candidate: candidateB);
      expect(evalFlutter.isPassed, isFalse, reason: 'Java candidate should reject Flutter job (Title/Stack mismatch)');
    });
  });
}
