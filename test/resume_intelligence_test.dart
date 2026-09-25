import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/features/career/domain/resume_profile_models.dart';
import 'package:career_os/features/career/domain/job_search_criteria_builder.dart';
import 'package:career_os/features/career/domain/job_match_service.dart';
import 'package:career_os/features/career/services/resume_parser_service.dart';
import 'package:career_os/features/career/services/career_profile_sync_service.dart';
import 'package:career_os/features/career/services/live_job_discovery_service.dart';
import 'package:career_os/features/career/data/job_providers/public_api_job_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ResumeParserService Tests', () {
    const sampleResumeText = '''
John Doe
Senior Full-Stack & Mobile Engineer
Email: john.doe@example.com | Phone: +1 555-0199 | Location: San Francisco, CA
GitHub: https://github.com/johndoe | LinkedIn: https://linkedin.com/in/johndoe

SUMMARY
Experienced Software Engineer with 6+ years of experience designing scalable microservices,
cross-platform mobile apps with Flutter, and reactive web applications in React.

EXPERIENCE
Lead Mobile Engineer | TechCorp (2021 - Present)
- Architected production Flutter and Dart applications with Bloc and Riverpod state management.
- Integrated GraphQL and RESTful APIs, optimized SQLite caching, reduced cold-boot latency by 35%.
- Implemented CI/CD pipelines with GitHub Actions and Docker.

Senior Backend Engineer | CloudScale Inc. (2018 - 2021)
- Built distributed backend systems using Java, Spring Boot, Node.js, and Python.
- Managed PostgreSQL and MongoDB databases, handled Redis pub/sub messaging and Kafka streams.
- Deployed microservices to AWS (ECS, S3, Lambda) and Kubernetes.

EDUCATION
Bachelor of Technology in Computer Science
Stanford University (2014 - 2018) | GPA: 3.8

SKILLS
Languages: Dart, TypeScript, JavaScript, Java, Python, SQL, Go
Frameworks: Flutter, React, Node.js, Spring Boot, FastAPI
Cloud & Tools: Docker, Kubernetes, AWS, Git, CI/CD, Redis, PostgreSQL
''';

    test('Parses contact information, education, and target roles accurately', () {
      final parser = ResumeParserService();
      final profile = parser.parseResumeText(
        resumeText: sampleResumeText,
        resumeId: 'res-1',
        resumeName: 'John_Doe_FullStack_2026.pdf',
      );

      expect(profile.resumeId, 'res-1');
      expect(profile.email?.value, 'john.doe@example.com');
      expect(profile.email?.confidence, ExtractionConfidence.high);
      expect(profile.phone?.value, '+1 555-0199');
      expect(profile.linkedin?.value, 'https://linkedin.com/in/johndoe');
      expect(profile.github?.value, 'https://github.com/johndoe');
      expect(profile.targetRole?.value, isNotNull);
      expect(profile.targetRole!.value.toLowerCase(), contains('engineer'));
      expect(profile.experienceYears?.value, 6.0);
      expect(profile.education?.value, contains('Bachelor'));
    });

    test('Extracts and categorizes technical skills correctly', () {
      final parser = ResumeParserService();
      final profile = parser.parseResumeText(
        resumeText: sampleResumeText,
        resumeId: 'res-1',
        resumeName: 'John_Doe_Resume.pdf',
      );

      final languages = profile.programmingLanguages.map((e) => e.value).toList();
      expect(languages, contains('Dart'));
      expect(languages, contains('TypeScript'));
      expect(languages, contains('Java'));
      expect(languages, contains('Python'));

      final frameworks = profile.frameworks.map((e) => e.value).toList();
      expect(frameworks, contains('Flutter'));
      expect(frameworks, contains('React'));
      expect(frameworks, contains('Node.js'));
      expect(frameworks, contains('Spring Boot'));

      final tools = profile.toolsAndCloud.map((e) => e.value).toList();
      expect(tools, contains('Docker'));
      expect(tools, contains('Kubernetes'));
      expect(tools, contains('AWS'));
      expect(tools, contains('PostgreSQL'));
      expect(tools, contains('Redis'));
    });

    test('Calculates deterministic quality audit score and suggestions', () {
      final parser = ResumeParserService();
      final profile = parser.parseResumeText(
        resumeText: sampleResumeText,
        resumeId: 'res-1',
        resumeName: 'John_Doe_Resume.pdf',
      );

      final audit = profile.qualityAudit;
      expect(audit.score, greaterThanOrEqualTo(80));
      expect(audit.hasContactInfo, true);
      expect(audit.hasLinkedInOrGitHub, true);
      expect(audit.hasEducation, true);
      expect(audit.hasTargetRole, true);
      expect(audit.hasSufficientSkills, true);
      expect(audit.passedChecks.length, greaterThanOrEqualTo(5));
    });
  });

  group('CareerProfileSyncService Tests', () {
    test('Detects field differences without destructive overwrite', () {
      final syncService = CareerProfileSyncService();

      final existingProfile = UserProfile(
        id: 'user-1',
        name: 'John Doe',
        currentRole: 'Junior Developer',
        experienceYears: 2.0,
        skills: 'JavaScript, HTML',
        programmingLanguages: 'JavaScript',
        frameworks: 'React',
        remotePreference: 'remote',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final parser = ResumeParserService();
      final parsedResume = parser.parseResumeText(
        resumeText: '''
John Doe
Senior Flutter Engineer
Email: john@test.com
Skills: Dart, Python, Flutter, Docker, AWS
Experience: 5 years
Education: B.S. in Computer Science
''',
        resumeId: 'res-1',
        resumeName: 'Resume.pdf',
      );

      final diffs = syncService.computeDifferences(
        existingProfile: existingProfile,
        extractedProfile: parsedResume,
      );

      expect(diffs.isNotEmpty, true);
      final roleDiff = diffs.firstWhere((d) => d.fieldName == 'currentRole');
      expect(roleDiff.currentValue, 'Junior Developer');
      expect(roleDiff.extractedValue, 'Senior Flutter Engineer');

      final expDiff = diffs.firstWhere((d) => d.fieldName == 'experienceYears');
      expect(expDiff.currentValue, '2.0');
      expect(expDiff.extractedValue, '5.0');
    });

    test('Applies selected diffs and persists updated profile companion', () async {
      final syncService = CareerProfileSyncService();

      final existingProfile = UserProfile(
        id: 'user-1',
        name: 'John Doe',
        currentRole: 'Junior Developer',
        experienceYears: 2.0,
        skills: 'JavaScript',
        programmingLanguages: 'JavaScript',
        frameworks: 'React',
        remotePreference: 'remote',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final diffToApply = [
        const ProfileDiffItem(
          fieldName: 'currentRole',
          label: 'Current Role',
          currentValue: 'Junior Developer',
          extractedValue: 'Senior Flutter Engineer',
          confidence: ExtractionConfidence.high,
          selectedByDefault: true,
        ),
        const ProfileDiffItem(
          fieldName: 'programmingLanguages',
          label: 'Languages',
          currentValue: 'JavaScript',
          extractedValue: 'JavaScript, Dart, Python',
          confidence: ExtractionConfidence.high,
          selectedByDefault: true,
        ),
      ];

      final updatedCompanion = syncService.buildUpdatedCompanion(
        existingProfile: existingProfile,
        approvedDiffs: diffToApply,
      );

      await db.upsertProfile(updatedCompanion);
      final loaded = await db.getProfile();

      expect(loaded, isNotNull);
      expect(loaded!.currentRole, 'Senior Flutter Engineer');
      expect(loaded.programmingLanguages, 'JavaScript, Dart, Python');
      expect(loaded.experienceYears, 2.0); // Preserved unchanged
    });
  });

  group('JobSearchCriteriaBuilder Tests', () {
    test('Builds search criteria from active parsed resumes and profile', () {
      final parser = ResumeParserService();
      final parsedResume = parser.parseResumeText(
        resumeText: '''
Alice Smith
Senior Backend Architect
Email: alice@cloud.io
Skills: Go, Java, Docker, Kubernetes, AWS, PostgreSQL, Redis, Microservices
Experience: 7 years
''',
        resumeId: 'res-backend',
        resumeName: 'Alice_Backend.pdf',
      );

      final criteria = JobSearchCriteriaBuilder.buildCriteria(
        activeResumes: [
          Resume(
            id: 'res-backend',
            name: 'Alice Backend',
            version: '1.0',
            filePath: '/resumes/alice.pdf',
            fileName: 'alice.pdf',
            isPrimary: true,
            extractionStatus: 'COMPLETED',
            targetRole: 'Senior Backend Architect',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
          ),
        ],
        parsedProfiles: {'res-backend': parsedResume},
        profile: UserProfile(
          id: 'user-1',
          name: 'Alice',
          experienceYears: 7.0,
          preferredLocations: 'Remote, London',
          remotePreference: 'remote',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      expect(criteria.roleQueries, contains('Senior Backend Architect'));
      expect(criteria.topSkills, contains('Go'));
      expect(criteria.topSkills, contains('Docker'));
      expect(criteria.topSkills, contains('Kubernetes'));
      expect(criteria.preferredLocation, 'Remote');
      expect(criteria.remoteOnly, true);
    });
  });

  group('JobDeduplicator Tests', () {
    final now = DateTime.now();
    final existingJobs = [
      Job(
        id: 'job-1',
        title: 'Senior Flutter Developer',
        company: 'Acme Corp',
        url: 'https://acme.com/jobs/flutter-1',
        discoveredAt: now,
        createdAt: now,
        updatedAt: now,
        isSaved: false,
      ),
      Job(
        id: 'job-2',
        title: 'Backend Engineer',
        company: 'DataFlow Systems',
        url: 'https://dataflow.io/careers/be-1',
        discoveredAt: now,
        createdAt: now,
        updatedAt: now,
        isSaved: false,
      ),
    ];

    test('Identifies duplicate by exact URL', () {
      const raw = RawJobItem(
        title: 'Different Title',
        company: 'Other Corp',
        url: 'https://acme.com/jobs/flutter-1',
        isRemote: true,
      );

      final res = JobDeduplicator.isDuplicate(raw, existingJobs);
      expect(res.isDuplicate, true);
      expect(res.existingJobId, 'job-1');
      expect(res.reason, contains('URL'));
    });

    test('Identifies duplicate by Title + Company match', () {
      const raw = RawJobItem(
        title: 'Senior Flutter Developer',
        company: 'acme corp',
        url: 'https://remoteok.com/l/9999',
        isRemote: true,
      );

      final res = JobDeduplicator.isDuplicate(raw, existingJobs);
      expect(res.isDuplicate, true);
      expect(res.existingJobId, 'job-1');
      expect(res.reason, contains('Title and company'));
    });

    test('Allows unique new job', () {
      const raw = RawJobItem(
        title: 'Lead DevOps Engineer',
        company: 'CloudNine Inc',
        url: 'https://cloudnine.io/jobs/1',
        isRemote: true,
      );

      final res = JobDeduplicator.isDuplicate(raw, existingJobs);
      expect(res.isDuplicate, false);
      expect(res.existingJobId, isNull);
    });
  });

  group('JobMatchService & Explainability Engine Tests', () {
    final now = DateTime.now();
    final testJob = Job(
      id: 'job-flutter',
      title: 'Senior Mobile Engineer (Flutter & Dart)',
      company: 'AppVenture Global',
      location: 'Remote',
      employmentType: 'Full-time',
      skills: 'Flutter, Dart, Riverpod, REST API, SQLite, Git, Docker, CI/CD',
      description: 'Looking for a Senior Mobile Engineer with 4+ years experience in Flutter, Dart, Riverpod, Docker and SQLite.',
      discoveredAt: now,
      createdAt: now,
      updatedAt: now,
      isSaved: false,
    );

    final testProfile = UserProfile(
      id: 'user-1',
      name: 'Rishi',
      currentRole: 'Senior Flutter Developer',
      experienceYears: 4.5,
      skills: 'Flutter, Dart, State Management, REST APIs, SQLite, Git, Clean Architecture',
      programmingLanguages: 'Dart, TypeScript',
      frameworks: 'Flutter, Riverpod, Docker',
      preferredRoles: 'Senior Mobile Engineer, Flutter Lead',
      preferredLocations: 'Remote',
      remotePreference: 'remote',
      createdAt: now,
      updatedAt: now,
    );

    test('Calculates multi-factor explainable match breakdown (0-100%)', () {
      final match = JobMatchService.calculateMatch(
        job: testJob,
        profile: testProfile,
      );

      expect(match.matchPercentage, greaterThanOrEqualTo(70));
      expect(match.matchingFactors.isNotEmpty, true);
      expect(match.matchingFactors.any((f) => f.contains('Skills matched') || f.contains('matched')), true);
      expect(match.hasSufficientData, true);
      expect(match.label, isNotEmpty);
    });
  });

  group('Drift Schema v9 Database Persistence Tests', () {
    test('Persists parsed JSON, extraction status, and active flag in Resumes table', () async {
      final now = DateTime.now();
      const resumeId = 'res-schema-v9';

      final companion = ResumesCompanion(
        id: const Value(resumeId),
        name: const Value('Senior_Engineer_2026.pdf'),
        filePath: const Value('/storage/resumes/Senior_Engineer_2026.pdf'),
        fileName: const Value('Senior_Engineer_2026.pdf'),
        targetRole: const Value('Staff Mobile Architect'),
        version: const Value('2.1'),
        parsedDataJson: const Value('{"skills":["Flutter","Dart","Go"],"experienceYears":6.0}'),
        extractionStatus: const Value('COMPLETED'),
        isActive: const Value(true),
        isPrimary: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

      await db.insertResume(companion);
      final fetched = await db.getResumeById(resumeId);

      expect(fetched, isNotNull);
      expect(fetched!.name, 'Senior_Engineer_2026.pdf');
      expect(fetched.parsedDataJson, contains('"Flutter"'));
      expect(fetched.extractionStatus, 'COMPLETED');
      expect(fetched.isActive, true);
    });

    test('Persists live job with atsProvider, rawJson, and externalId in Jobs table', () async {
      final now = DateTime.now();
      const jobId = 'job-live-99';

      final companion = JobsCompanion(
        id: const Value(jobId),
        title: const Value('Founding Flutter Engineer'),
        company: const Value('Y-Combinator Startup'),
        location: const Value('Remote'),
        source: const Value('RemoteOK API'),
        atsProvider: const Value('REMOTEOK'),
        externalId: const Value('rok-102938'),
        rawJson: const Value('{"tags":["flutter","dart","remote"]}'),
        isSaved: const Value(true),
        discoveredAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

      await db.insertJob(companion);
      final fetched = await db.getJobById(jobId);

      expect(fetched, isNotNull);
      expect(fetched!.title, 'Founding Flutter Engineer');
      expect(fetched.atsProvider, 'REMOTEOK');
      expect(fetched.externalId, 'rok-102938');
      expect(fetched.rawJson, contains('"tags"'));
      expect(fetched.isSaved, true);
    });
  });
}
