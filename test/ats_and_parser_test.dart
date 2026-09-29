import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/features/career/services/ats_scoring_service.dart';
import 'package:career_os/features/career/services/resume_ingest_service.dart';
import 'package:career_os/features/career/services/resume_parser_service.dart';
import 'package:career_os/features/career/services/resume_text_extractor.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResumeParserService on real extracted text', () {
    late String chromeText;
    setUpAll(() async {
      chromeText = await ResumeTextExtractor.extractFromFile('test/fixtures/sample_resume_chrome.pdf');
    });

    test('name, contact, sections and computed years', () {
      final p = ResumeParserService().parseResumeText(resumeText: chromeText, resumeId: 'r', resumeName: 'r.pdf');
      expect(p.fullName?.value, 'Priya Raman');
      expect(p.email?.value, 'priya.raman@example.com');
      expect(p.phone?.value, '+91 98765 43210');
      expect(p.linkedin?.value, 'https://linkedin.com/in/priya-raman-dev');
      expect(p.github?.value, 'https://github.com/priyaraman');
      expect(p.targetRole?.value, 'Senior Flutter Developer');
      expect(p.experienceYears?.value, 5.0); // stated "5+ years"
      expect(p.sections, containsAll(['summary', 'experience', 'projects', 'skills', 'education']));
      expect(p.educationEntries.first, contains('B.Tech in Computer Science'));
    });

    test('experience entries with role, company, location, dates and bullets', () {
      final p = ResumeParserService().parseResumeText(resumeText: chromeText, resumeId: 'r', resumeName: 'r.pdf');
      expect(p.experience, hasLength(2));
      final first = p.experience.first;
      expect(first.role, 'Senior Flutter Developer');
      expect(first.company, 'Swiggy');
      expect(first.location, 'Bengaluru');
      expect(first.isCurrent, isTrue);
      expect(first.start, DateTime(2022, 1));
      expect(first.bullets, hasLength(3));
      expect(first.bullets.first, startsWith('Led migration'));
      final second = p.experience[1];
      expect(second.role, 'Android Developer');
      expect(second.company, 'Zoho Corporation');
      expect(second.end, DateTime(2021, 12));
      expect(second.bullets, hasLength(2));
    });

    test('years are derived from history when not stated', () {
      const text = '''
Alex Kim
alex@example.com | +1 415 555 0100
EXPERIENCE
Backend Engineer | Acme (Jan 2020 - Dec 2022)
- Built billing APIs in Go serving 3M requests/day.
Software Engineer | Beta Labs (Jan 2023 - Dec 2023)
- Shipped Kotlin features.
EDUCATION
B.S. Computer Science, UCLA, 2019
''';
      final p = ResumeParserService().parseResumeText(resumeText: text, resumeId: 'r', resumeName: 'r');
      expect(p.experienceYears?.value, 4.0);
      expect(p.experience.map((e) => e.company), ['Acme', 'Beta Labs']);
    });

    test('ambiguous short skills need canonical casing', () {
      const text = 'Alex Kim\nI like to go hiking and did R&D on swift delivery.\nSKILLS\nPython, Go, Swift';
      final p = ResumeParserService().parseResumeText(resumeText: text, resumeId: 'r', resumeName: 'r');
      final langs = p.programmingLanguages.map((e) => e.value).toList();
      expect(langs, containsAll(['Python', 'Go', 'Swift']));
      expect(langs, isNot(contains('R')));

      const prose = 'Alex Kim\nI like to go hiking and did R&D on swift delivery.';
      final q = ResumeParserService().parseResumeText(resumeText: prose, resumeId: 'r', resumeName: 'r');
      expect(q.programmingLanguages, isEmpty);
    });
  });

  group('AtsScoringService', () {
    late ResumeIngestResult priya;
    setUpAll(() async {
      final text = await ResumeTextExtractor.extractFromFile('test/fixtures/sample_resume_chrome.pdf');
      priya = ResumeIngestService.fromText(text, resumeId: 'r', resumeName: 'r.pdf');
    });

    test('general score rewards complete, quantified resumes', () {
      final report = AtsScoringService().evaluate(priya.profile);
      expect(report.scoredAgainstJob, isFalse);
      expect(report.sections.score, report.sections.maxScore);
      expect(report.impact.score, greaterThanOrEqualTo(15));
      expect(report.total, greaterThanOrEqualTo(70));
    });

    test('job keyword match lists missing technologies', () {
      const jd = '''
Senior Mobile Engineer. You will build our Flutter app with Riverpod and Dart,
integrate GraphQL APIs, and deploy backend services on Kubernetes and Docker.
Experience with Kubernetes, Terraform and Kafka is a plus. 7+ years of experience required.
''';
      final report = AtsScoringService().evaluate(priya.profile, jobDescription: jd, jobTitle: 'Senior Mobile Engineer');
      expect(report.scoredAgainstJob, isTrue);
      expect(report.matchedKeywords, containsAll(['Flutter', 'Riverpod', 'Dart', 'GraphQL', 'Docker']));
      expect(report.missingKeywords, containsAll(['Kubernetes', 'Terraform', 'Kafka']));
      expect(report.suggestions.any((s) => s.startsWith('Missing keywords: Kubernetes')), isTrue);
      expect(report.suggestions.any((s) => s.contains('7+ years')), isTrue);
    });

    test('weak, unquantified resume gets actionable suggestions', () {
      const weak = '''
Jamie Doe
Developer
EXPERIENCE
Developer, Some Company
2021 - Present
Responsible for the website.
Worked on various features.
Helped the team with tasks.
''';
      final r = ResumeIngestService.fromText(weak, resumeId: 'w', resumeName: 'w');
      final report = AtsScoringService().evaluate(r.profile);
      expect(report.total, lessThan(45));
      expect(report.suggestions.any((s) => s.startsWith('Add quantified metrics')), isTrue);
      expect(report.suggestions.any((s) => s.contains('Responsible for')), isTrue);
      expect(report.suggestions.any((s) => s.contains('Skills')), isTrue);
    });
  });

  group('ResumeIngestService.applyToProfile', () {
    test('fills empty profile fields, merges skills and seeds skills tracker', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final text = await ResumeTextExtractor.extractFromFile('test/fixtures/sample_resume_chrome.pdf');
      final ingest = ResumeIngestService.fromText(text, resumeId: 'r', resumeName: 'r.pdf');

      final result = await ResumeIngestService(db).applyToProfile(ingest.profile);
      final profile = (await db.getProfile())!;
      expect(profile.name, 'Priya Raman');
      expect(profile.email, 'priya.raman@example.com');
      expect(profile.currentRole, 'Senior Flutter Developer');
      expect(profile.experienceYears, 5.0);
      expect(profile.programmingLanguages, contains('Dart'));
      expect(profile.frameworks, contains('Flutter'));
      expect(result.skillsAdded, greaterThan(10));

      // Second run keeps user edits and doesn't duplicate tracker skills.
      await (db.update(db.userProfiles)).write(const UserProfilesCompanion(currentRole: Value('Staff Engineer')));
      final again = await ResumeIngestService(db).applyToProfile(ingest.profile);
      expect((await db.getProfile())!.currentRole, 'Staff Engineer');
      expect(again.skillsAdded, 0);
    });
  });
}
