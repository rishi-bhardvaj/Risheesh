import '../ai/ai_provider_interfaces.dart';
import '../jobs/normalized_job.dart';
import '../jobs/role_classifier.dart';
import '../profile/candidate_profile.dart';
import 'component_scorers.dart';
import 'explainer.dart';
import 'fusion.dart';
import 'hard_filters.dart';
import 'matching_config.dart';
import 'skill_scorer.dart';

class MatchEvaluationResult {
  final NormalizedJob job;
  final RelevanceTier tier;
  final int score;
  final double deterministicScore;
  final int? llmScore;
  final String? rejectedStage;
  final String? rejectedReason;
  final MatchComponents components;
  final SkillScoringResult skillBreakdown;
  final ExplainabilityDetails explainability;
  final List<String> appliedCaps;

  const MatchEvaluationResult({
    required this.job,
    required this.tier,
    required this.score,
    required this.deterministicScore,
    this.llmScore,
    this.rejectedStage,
    this.rejectedReason,
    required this.components,
    required this.skillBreakdown,
    required this.explainability,
    this.appliedCaps = const [],
  });

  bool get isPassed => tier == RelevanceTier.highlyRelevant || tier == RelevanceTier.relevant;
  List<String> get matchedSkills => explainability.matchedSkills;
}

class RelevanceEngine {
  final MatchingConfig config;
  final MatchingProvider? matchingProvider;
  final EmbeddingProvider? embeddingProvider;

  const RelevanceEngine({
    this.config = const MatchingConfig(),
    this.matchingProvider,
    this.embeddingProvider,
  });

  Future<MatchEvaluationResult> evaluate({
    required NormalizedJob job,
    required CandidateProfile candidate,
    Set<String> hiddenCompanies = const {},
    Set<String> hiddenRoles = const {},
    int feedbackAdjustment = 0,
  }) async {
    final caps = <String>[];

    // S0: Source Validation
    if (job.title.isEmpty || job.company.isEmpty) {
      return _reject(job, 'S0_SOURCE_VALIDATION', 'INVALID_JOB_RECORD');
    }

    // S3: Role Classification Gate
    final isPrimary = job.roleFamily == candidate.primaryRoleFamily;
    final isAdjacent = candidate.adjacentRoleFamilies.contains(job.roleFamily);
    final isAllowed = config.alwaysAllowedFamilies.contains(job.roleFamily);
    final isKnownAdjacent = (config.familyAdjacency[candidate.primaryRoleFamily] ?? const []).contains(job.roleFamily);

    if (RoleFamily.nonEngineering.contains(job.roleFamily) || (!isPrimary && !isAdjacent && !isAllowed && !isKnownAdjacent)) {
      if (job.roleFamily == RoleFamily.unknown) {
        caps.add('UNKNOWN_ROLE_FAMILY');
      } else {
        return _reject(job, 'S3_ROLE_CLASSIFICATION', 'ROLE_FAMILY_MISMATCH:${job.roleFamily}');
      }
    }

    // S4: Hard Eligibility Gate
    final hardFilter = HardFilters.evaluate(
      job: job,
      candidate: candidate,
      config: config,
      hiddenCompanies: hiddenCompanies,
      hiddenRoles: hiddenRoles,
    );
    if (!hardFilter.passed) {
      return _reject(job, 'S4_HARD_ELIGIBILITY', hardFilter.rejectionReason ?? 'HARD_FILTER_FAILED');
    }

    // S5: Skill Matching
    final skillBreakdown = SkillScorer.score(
      job: job,
      candidate: candidate,
    );
    if (skillBreakdown.score == null) {
      caps.add('NO_SKILLS_EXTRACTED');
    }

    // S6: Semantic Similarity (Simulated / Calculated)
    double semanticScore = 80.0;
    if (embeddingProvider == null) {
      caps.add('EMBEDDINGS_UNAVAILABLE');
    }

    // Compute component scores
    final roleScore = ComponentScorers.scoreRole(job: job, candidate: candidate, config: config);
    final expScore = ComponentScorers.scoreExperience(job: job, candidate: candidate, config: config);
    final locScore = ComponentScorers.scoreLocation(job: job, candidate: candidate);
    final eduScore = ComponentScorers.scoreEducation(job: job, candidate: candidate);
    final domainScore = ComponentScorers.scoreDomain(job: job, candidate: candidate);

    final components = MatchComponents(
      role: roleScore,
      skill: skillBreakdown.score ?? 50.0,
      semantic: semanticScore,
      experience: expScore,
      project: 75.0,
      domain: domainScore,
      education: eduScore,
      location: locScore,
    );

    final detScore = components.computeDeterministicScore(config.weights);

    // S7: LLM Classification (Runs if detScore >= llmGateMin)
    LlmMatchResult? llmResult;
    if (matchingProvider != null && detScore >= config.thresholds.llmGateMin) {
      try {
        llmResult = await matchingProvider!.classify(
          profileJson: candidate.toJson(),
          jobJson: {'title': job.title, 'company': job.company, 'description': job.descriptionText},
          deterministicFindings: {
            'roleFamily': job.roleFamily,
            'detScore': detScore,
            'missingRequired': skillBreakdown.missingRequired,
          },
        );
      } catch (_) {
        caps.add('LLM_CHECK_PENDING');
      }
    } else if (matchingProvider == null) {
      caps.add('LLM_PROVIDER_ABSENT');
    }

    // S8: Fusion & Threshold
    final fusion = FusionEngine.fuse(
      deterministicScore: detScore,
      llmScore: llmResult?.relevanceScore,
      llmIsRelevant: llmResult?.isRelevant,
      llmConfidence: llmResult?.confidence,
      missingRequiredCoreSkillsCount: skillBreakdown.missingRequired.length,
      redFlags: llmResult?.redFlags ?? const [],
      feedbackAdjustment: feedbackAdjustment,
      isCappedAtPossible: caps.isNotEmpty,
      caps: caps,
      config: config,
    );

    final explainer = Explainer.build(
      finalScore: fusion.finalScore,
      tier: fusion.tier,
      roleFamily: job.roleFamily,
      skillResult: skillBreakdown,
      llmReason: llmResult?.reason,
    );

    return MatchEvaluationResult(
      job: job,
      tier: fusion.tier,
      score: fusion.finalScore,
      deterministicScore: detScore,
      llmScore: llmResult?.relevanceScore,
      components: components,
      skillBreakdown: skillBreakdown,
      explainability: explainer,
      appliedCaps: caps,
    );
  }

  MatchEvaluationResult _reject(NormalizedJob job, String stage, String reason) {
    const dummyComp = MatchComponents(
      role: 0, skill: 0, semantic: 0, experience: 0, project: 0, domain: 0, education: 0, location: 0,
    );
    const dummySkills = SkillScoringResult(
      score: 0, exactMatches: [], equivalentMatches: [], transferableMatches: [], missingRequired: [], missingPreferred: [],
    );
    const explainer = ExplainabilityDetails(
      header: 'MATCH 0% · Not relevant',
      summaryReason: 'Rejected by relevance pipeline.',
      matchedSkills: [],
      missingRequiredSkills: [],
      missingPreferredSkills: [],
      relevantExperienceHighlights: [],
    );

    return MatchEvaluationResult(
      job: job,
      tier: RelevanceTier.notRelevant,
      score: 0,
      deterministicScore: 0.0,
      rejectedStage: stage,
      rejectedReason: reason,
      components: dummyComp,
      skillBreakdown: dummySkills,
      explainability: explainer,
    );
  }
}
