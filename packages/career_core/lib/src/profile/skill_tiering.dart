import '../taxonomy/skill_matcher.dart';
import 'candidate_profile.dart';

class SkillTiersResult {
  final List<String> primary;
  final List<String> secondary;
  final List<String> familiar;

  const SkillTiersResult({
    required this.primary,
    required this.secondary,
    required this.familiar,
  });
}

class SkillTiering {
  SkillTiering._();

  /// Assigns skills to PRIMARY, SECONDARY, and FAMILIAR tiers based on deterministic criteria:
  /// - PRIMARY: appears in 2+ experiences, or in the most recent role plus summary or projects.
  /// - SECONDARY: appears once in experience or projects.
  /// - FAMILIAR: listed only in a skills section.
  static SkillTiersResult assignTiers({
    required List<CandidateExperience> experiences,
    required List<CandidateProject> projects,
    required String summaryText,
    required Set<String> allExtractedSkills,
  }) {
    final primary = <String>{};
    final secondary = <String>{};
    final familiar = <String>{};

    final summarySkills = SkillMatcher.extractCanonicalSkills(summaryText);
    final projectSkills = <String>{};
    for (final p in projects) {
      projectSkills.addAll(p.technologies.map((t) => SkillMatcher.extractCanonicalSkills(t)).expand((e) => e));
      projectSkills.addAll(SkillMatcher.extractCanonicalSkills('${p.name} ${p.description}'));
    }

    final expSkillOccurrences = <String, int>{};
    final mostRecentExpSkills = <String>{};

    for (var i = 0; i < experiences.length; i++) {
      final exp = experiences[i];
      final expSkills = <String>{};
      expSkills.addAll(exp.technologies.map((t) => SkillMatcher.extractCanonicalSkills(t)).expand((e) => e));
      expSkills.addAll(SkillMatcher.extractCanonicalSkills('${exp.role} ${exp.responsibilities.join(' ')} ${exp.achievements.join(' ')}'));

      for (final s in expSkills) {
        expSkillOccurrences[s] = (expSkillOccurrences[s] ?? 0) + 1;
      }
      if (i == 0) {
        mostRecentExpSkills.addAll(expSkills);
      }
    }

    for (final skill in allExtractedSkills) {
      final count = expSkillOccurrences[skill] ?? 0;
      final inMostRecent = mostRecentExpSkills.contains(skill);
      final inSummary = summarySkills.contains(skill);
      final inProjects = projectSkills.contains(skill);

      if (count >= 2 || (inMostRecent && (inSummary || inProjects))) {
        primary.add(skill);
      } else if (count == 1 || inProjects) {
        secondary.add(skill);
      } else {
        familiar.add(skill);
      }
    }

    return SkillTiersResult(
      primary: primary.toList()..sort(),
      secondary: secondary.toList()..sort(),
      familiar: familiar.toList()..sort(),
    );
  }
}
