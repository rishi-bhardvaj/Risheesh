import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../ai/ai_provider_interfaces.dart';
import '../taxonomy/skill_matcher.dart';
import '../taxonomy/skills.dart';
import '../util/text_normalize.dart';
import 'candidate_profile.dart';
import 'entity_extractors.dart';
import 'experience_calculator.dart';
import 'section_detector.dart';
import 'skill_tiering.dart';

class ResumePipelineResult {
  final CandidateProfile profile;
  final String rawText;
  final List<String> warnings;
  final int droppedUngroundedCount;

  const ResumePipelineResult({
    required this.profile,
    required this.rawText,
    this.warnings = const [],
    this.droppedUngroundedCount = 0,
  });
}

class ResumePipeline {
  final ExtractionProvider? extractionProvider;
  final EmbeddingProvider? embeddingProvider;

  const ResumePipeline({
    this.extractionProvider,
    this.embeddingProvider,
  });

  Future<ResumePipelineResult> process({
    required String rawText,
    Map<String, dynamic>? existingOverrides,
  }) async {
    final warnings = <String>[];
    var droppedUngrounded = 0;

    // 1. Text sanity
    final normalizedResumeText = TextNormalize.collapseWhitespace(rawText).toLowerCase();
    if (rawText.trim().length < 200) {
      warnings.add('Text layer is unusually short (<200 characters). Document may be scanned or image-only.');
    }

    final sha256Hash = sha256.convert(utf8.encode(rawText)).toString();

    // 2. Detect sections
    final sections = SectionDetector.detectSections(rawText);
    String sectionText(String canonical) =>
        sections.where((s) => s.canonicalSection == canonical).map((s) => s.content).join('\n\n');

    final summaryContent = sectionText('summary');
    final experienceContent = sectionText('experience');
    final projectsContent = sectionText('projects');
    final skillsContent = sectionText('skills');
    final educationContent = sectionText('education');

    // 3. Deterministic extraction
    final email = EntityExtractors.extractEmail(rawText);
    final phone = EntityExtractors.extractPhone(rawText);
    final location = EntityExtractors.extractLocation(rawText) ?? '';
    final detectedSkills = SkillMatcher.extractCanonicalSkills(rawText);

    // Deterministic experience dates
    final intervals = <DateInterval>[];
    final expLines = experienceContent.split('\n');
    for (final line in expLines) {
      final (start, end) = ExperienceCalculator.parseRange(line);
      if (start != null && end != null) {
        intervals.add(DateInterval(
          start: start,
          end: end,
          isInternship: line.toLowerCase().contains('intern'),
        ));
      }
    }
    final expMonths = ExperienceCalculator.calculateTotalMonths(intervals);

    // 4. LLM structured extraction (if provider present)
    Map<String, dynamic>? llmData;
    if (extractionProvider != null) {
      try {
        llmData = await extractionProvider!.extractResume(rawText);
      } catch (e) {
        warnings.add('AI extraction failed, fell back to deterministic parser: $e');
      }
    } else {
      warnings.add('AI extraction unavailable; profile is keyword-derived');
    }

    // Grounding verification helper
    bool isGrounded(String? snippet) {
      if (snippet == null || snippet.trim().isEmpty) return false;
      final norm = TextNormalize.collapseWhitespace(snippet).toLowerCase();
      if (norm.length < 5) return true;
      final found = normalizedResumeText.contains(norm);
      if (!found) {
        droppedUngrounded++;
      }
      return found;
    }

    // 5. Merge results
    String name = '';
    String currentRole = '';
    final experiences = <CandidateExperience>[];
    final projects = <CandidateProject>[];
    final educations = <CandidateEducation>[];

    if (llmData != null) {
      final cand = llmData['candidate'] as Map<String, dynamic>? ?? llmData;
      name = cand['name']?.toString() ?? '';
      currentRole = cand['currentRole']?.toString() ?? '';

      // Experiences with grounding check
      final rawExps = cand['experience'] as List? ?? const [];
      for (final e in rawExps) {
        if (e is Map<String, dynamic>) {
          final evidence = e['evidence']?.toString() ?? '';
          if (evidence.isNotEmpty && !isGrounded(evidence)) {
            continue; // drop ungrounded
          }
          experiences.add(CandidateExperience.fromJson(e));
        }
      }

      // Projects with grounding check
      final rawProjs = cand['projects'] as List? ?? const [];
      for (final p in rawProjs) {
        if (p is Map<String, dynamic>) {
          final evidence = p['evidence']?.toString() ?? '';
          if (evidence.isNotEmpty && !isGrounded(evidence)) {
            continue; // drop ungrounded
          }
          projects.add(CandidateProject.fromJson(p));
        }
      }

      // Education
      final rawEdus = cand['education'] as List? ?? const [];
      for (final ed in rawEdus) {
        if (ed is Map<String, dynamic>) {
          educations.add(CandidateEducation.fromJson(ed));
        }
      }
    }

    // Deterministic fallbacks if LLM omitted them
    if (name.isEmpty) {
      final firstLine = rawText.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => 'Candidate').trim();
      name = firstLine.length <= 40 ? firstLine : 'Candidate';
    }

    if (educations.isEmpty && educationContent.isNotEmpty) {
      educations.add(CandidateEducation(
        degree: 'Degree',
        level: EntityExtractors.detectDegreeLevel(educationContent),
        specialization: '',
        institution: educationContent.split('\n').first.trim(),
      ));
    }

    // 6. Tiering
    final tiers = SkillTiering.assignTiers(
      experiences: experiences,
      projects: projects,
      summaryText: summaryContent,
      allExtractedSkills: detectedSkills,
    );

    // Determine primary role family from title/roles
    final primaryFamily = _derivePrimaryRoleFamily(currentRole, detectedSkills);

    // 7. Assemble CandidateProfile
    var profile = CandidateProfile(
      name: name,
      currentRole: currentRole.isNotEmpty ? currentRole : 'Software Professional',
      roles: currentRole.isNotEmpty ? [currentRole] : const ['Software Engineer'],
      primaryRoleFamily: primaryFamily,
      adjacentRoleFamilies: primaryFamily == 'MOBILE' ? const ['FULLSTACK', 'FRONTEND'] : const ['FULLSTACK'],
      experienceMonths: expMonths,
      experienceLevel: expMonths < 24
          ? ExperienceLevel.junior
          : (expMonths < 60 ? ExperienceLevel.mid : ExperienceLevel.senior),
      education: educations,
      primarySkills: tiers.primary,
      secondarySkills: tiers.secondary,
      familiarSkills: tiers.familiar,
      experience: experiences,
      projects: projects,
      currentLocation: location,
      sourceResumeSha256: sha256Hash,
      warnings: warnings,
    );

    // Apply overrides if any
    if (existingOverrides != null && existingOverrides.isNotEmpty) {
      profile = profile.applyOverrides(existingOverrides);
    }

    return ResumePipelineResult(
      profile: profile,
      rawText: rawText,
      warnings: warnings,
      droppedUngroundedCount: droppedUngrounded,
    );
  }

  static String _derivePrimaryRoleFamily(String role, Set<String> skills) {
    final lower = role.toLowerCase();
    if (lower.contains('flutter') || lower.contains('android') || lower.contains('ios') || lower.contains('mobile')) {
      return 'MOBILE';
    }
    if (lower.contains('frontend') || lower.contains('front-end') || lower.contains('react') || lower.contains('vue')) {
      return 'FRONTEND';
    }
    if (lower.contains('backend') || lower.contains('back-end') || lower.contains('java') || lower.contains('golang') || lower.contains('node')) {
      return 'BACKEND';
    }
    if (skills.contains('Flutter') || skills.contains('React Native')) return 'MOBILE';
    if (skills.contains('React') || skills.contains('Angular') || skills.contains('Vue.js')) return 'FRONTEND';
    return 'BACKEND';
  }
}
