import '../jobs/normalized_job.dart';
import '../jobs/section_splitter.dart';
import '../profile/candidate_profile.dart';
import '../taxonomy/skill_matcher.dart';

class SkillScoringResult {
  final double? score; // 0 to 100, or null if no required/preferred skills
  final List<String> exactMatches;
  final List<String> equivalentMatches;
  final List<String> transferableMatches;
  final List<String> missingRequired;
  final List<String> missingPreferred;

  const SkillScoringResult({
    required this.score,
    required this.exactMatches,
    required this.equivalentMatches,
    required this.transferableMatches,
    required this.missingRequired,
    required this.missingPreferred,
  });
}

class SkillScorer {
  SkillScorer._();

  static SkillScoringResult score({
    required NormalizedJob job,
    required CandidateProfile candidate,
  }) {
    final exact = <String>[];
    final equivalent = <String>[];
    final transferable = <String>[];
    final missingReq = <String>[];
    final missingPref = <String>[];

    final requiredSkills = job.skills.where((s) => s.requirement == SkillRequirementType.required).toList();
    final preferredSkills = job.skills.where((s) => s.requirement == SkillRequirementType.preferred).toList();

    if (requiredSkills.isEmpty && preferredSkills.isEmpty) {
      return const SkillScoringResult(
        score: null,
        exactMatches: [],
        equivalentMatches: [],
        transferableMatches: [],
        missingRequired: [],
        missingPreferred: [],
      );
    }

    double candidateTierWeight(String canonical) {
      if (candidate.primarySkills.contains(canonical)) return 1.0;
      if (candidate.secondarySkills.contains(canonical)) return 0.85;
      if (candidate.familiarSkills.contains(canonical)) return 0.6;
      return 0.85;
    }

    var totalWeightedScore = 0.0;
    var totalDenominator = 0.0;

    for (final req in requiredSkills) {
      totalDenominator += 1.0;
      final finding = SkillMatcher.matchSkill(
        jobSkill: req.canonical,
        candidateCanonicalSkills: candidate.allCanonicalSkills,
      );

      switch (finding.quality) {
        case SkillMatchQuality.exact:
          exact.add(req.canonical);
          totalWeightedScore += 1.0 * candidateTierWeight(req.canonical);
        case SkillMatchQuality.equivalent:
          equivalent.add(req.canonical);
          totalWeightedScore += 0.9 * candidateTierWeight(finding.canonical);
        case SkillMatchQuality.transferable:
          transferable.add('${req.canonical} (~${finding.rawMatch})');
          totalWeightedScore += finding.weight * candidateTierWeight(finding.canonical);
        case SkillMatchQuality.none:
          missingReq.add(req.canonical);
      }
    }

    for (final pref in preferredSkills) {
      totalDenominator += 0.5;
      final finding = SkillMatcher.matchSkill(
        jobSkill: pref.canonical,
        candidateCanonicalSkills: candidate.allCanonicalSkills,
      );

      switch (finding.quality) {
        case SkillMatchQuality.exact:
          exact.add(pref.canonical);
          totalWeightedScore += 0.5 * 1.0 * candidateTierWeight(pref.canonical);
        case SkillMatchQuality.equivalent:
          equivalent.add(pref.canonical);
          totalWeightedScore += 0.5 * 0.9 * candidateTierWeight(finding.canonical);
        case SkillMatchQuality.transferable:
          transferable.add(pref.canonical);
          totalWeightedScore += 0.5 * finding.weight * candidateTierWeight(finding.canonical);
        case SkillMatchQuality.none:
          missingPref.add(pref.canonical);
      }
    }

    final calculatedScore = totalDenominator > 0 ? (totalWeightedScore / totalDenominator) * 100.0 : 0.0;

    return SkillScoringResult(
      score: calculatedScore.clamp(0.0, 100.0),
      exactMatches: exact,
      equivalentMatches: equivalent,
      transferableMatches: transferable,
      missingRequired: missingReq,
      missingPreferred: missingPref,
    );
  }
}
