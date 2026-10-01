import 'fusion.dart';
import 'skill_scorer.dart';

class ExplainabilityDetails {
  final String header;
  final String summaryReason;
  final List<String> matchedSkills;
  final List<String> missingRequiredSkills;
  final List<String> missingPreferredSkills;
  final List<String> relevantExperienceHighlights;

  const ExplainabilityDetails({
    required this.header,
    required this.summaryReason,
    required this.matchedSkills,
    required this.missingRequiredSkills,
    required this.missingPreferredSkills,
    required this.relevantExperienceHighlights,
  });

  Map<String, dynamic> toJson() => {
        'header': header,
        'summaryReason': summaryReason,
        'matchedSkills': matchedSkills,
        'missingRequiredSkills': missingRequiredSkills,
        'missingPreferredSkills': missingPreferredSkills,
        'relevantExperienceHighlights': relevantExperienceHighlights,
      };
}

class Explainer {
  Explainer._();

  static ExplainabilityDetails build({
    required int finalScore,
    required RelevanceTier tier,
    required String roleFamily,
    required SkillScoringResult skillResult,
    String? llmReason,
  }) {
    final tierLabel = switch (tier) {
      RelevanceTier.highlyRelevant => 'Highly relevant',
      RelevanceTier.relevant => 'Relevant',
      RelevanceTier.possibleMatch => 'Possible match',
      RelevanceTier.notRelevant => 'Not relevant',
      RelevanceTier.unscored => 'Unscored',
    };

    final header = 'MATCH $finalScore% · $tierLabel';

    final matched = [
      ...skillResult.exactMatches,
      ...skillResult.equivalentMatches,
    ];

    final summary = (llmReason != null && llmReason.trim().isNotEmpty && llmReason.length <= 400)
        ? llmReason
        : 'Strong $roleFamily alignment; ${matched.length} matched skills; '
            '${skillResult.missingRequired.isEmpty ? "All mandatory requirements met." : "Missing: ${skillResult.missingRequired.take(2).join(', ')}"}';

    return ExplainabilityDetails(
      header: header,
      summaryReason: summary,
      matchedSkills: matched,
      missingRequiredSkills: skillResult.missingRequired,
      missingPreferredSkills: skillResult.missingPreferred,
      relevantExperienceHighlights: [
        if (matched.isNotEmpty) 'Matched tech stack: ${matched.take(4).join(', ')}',
      ],
    );
  }
}
