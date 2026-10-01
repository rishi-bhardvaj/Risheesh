import 'matching_config.dart';

enum RelevanceTier {
  highlyRelevant,
  relevant,
  possibleMatch,
  notRelevant,
  unscored,
}

class FusionResult {
  final RelevanceTier tier;
  final int finalScore; // 0 to 100
  final double deterministicScore;
  final int? llmScore;
  final int feedbackAdjustment;
  final List<String> appliedCaps;

  const FusionResult({
    required this.tier,
    required this.finalScore,
    required this.deterministicScore,
    this.llmScore,
    this.feedbackAdjustment = 0,
    this.appliedCaps = const [],
  });
}

class FusionEngine {
  FusionEngine._();

  static FusionResult fuse({
    required double deterministicScore,
    int? llmScore,
    bool? llmIsRelevant,
    double? llmConfidence,
    int missingRequiredCoreSkillsCount = 0,
    List<String> redFlags = const [],
    int feedbackAdjustment = 0,
    bool isCappedAtPossible = false,
    List<String> caps = const [],
    required MatchingConfig config,
  }) {
    final adj = feedbackAdjustment.clamp(config.feedbackAdjMin, config.feedbackAdjMax);

    final double effectiveScore;
    if (llmScore != null) {
      effectiveScore = (config.alpha * deterministicScore) + ((1.0 - config.alpha) * llmScore);
    } else {
      effectiveScore = deterministicScore;
    }

    final finalScore = (effectiveScore.round() + adj).clamp(0, 100);

    // If capped (e.g. no LLM, no embeddings, null skills, or unknown role)
    if (isCappedAtPossible) {
      if (finalScore >= config.thresholds.possible && deterministicScore >= 55) {
        return FusionResult(
          tier: RelevanceTier.possibleMatch,
          finalScore: finalScore,
          deterministicScore: deterministicScore,
          llmScore: llmScore,
          feedbackAdjustment: adj,
          appliedCaps: caps,
        );
      } else {
        return FusionResult(
          tier: RelevanceTier.notRelevant,
          finalScore: finalScore,
          deterministicScore: deterministicScore,
          llmScore: llmScore,
          feedbackAdjustment: adj,
          appliedCaps: caps,
        );
      }
    }

    // Check blocking red flags
    final hasBlockingRedFlag = redFlags.any((flag) =>
        config.blockingRedFlags.any((b) => flag.toLowerCase().contains(b.toLowerCase())));

    // 1. HIGHLY_RELEVANT
    final satisfiesHigh = finalScore >= config.thresholds.high &&
        (llmIsRelevant ?? true) &&
        ((llmConfidence ?? 1.0) >= config.thresholds.llmMinConfidenceHigh) &&
        missingRequiredCoreSkillsCount == 0 &&
        !hasBlockingRedFlag;

    if (satisfiesHigh) {
      return FusionResult(
        tier: RelevanceTier.highlyRelevant,
        finalScore: finalScore,
        deterministicScore: deterministicScore,
        llmScore: llmScore,
        feedbackAdjustment: adj,
      );
    }

    // 2. RELEVANT
    final satisfiesRelevant = finalScore >= config.thresholds.relevant &&
        (llmIsRelevant ?? true) &&
        missingRequiredCoreSkillsCount <= 1 &&
        !hasBlockingRedFlag;

    if (satisfiesRelevant) {
      return FusionResult(
        tier: RelevanceTier.relevant,
        finalScore: finalScore,
        deterministicScore: deterministicScore,
        llmScore: llmScore,
        feedbackAdjustment: adj,
      );
    }

    // 3. POSSIBLE_MATCH
    if (finalScore >= config.thresholds.possible) {
      return FusionResult(
        tier: RelevanceTier.possibleMatch,
        finalScore: finalScore,
        deterministicScore: deterministicScore,
        llmScore: llmScore,
        feedbackAdjustment: adj,
      );
    }

    // 4. NOT_RELEVANT
    return FusionResult(
      tier: RelevanceTier.notRelevant,
      finalScore: finalScore,
      deterministicScore: deterministicScore,
      llmScore: llmScore,
      feedbackAdjustment: adj,
    );
  }
}
