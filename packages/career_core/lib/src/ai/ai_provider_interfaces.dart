import 'dart:typed_data';

abstract class EmbeddingProvider {
  String get modelId;
  int get dimensions;
  Future<List<Float32List>> embed(List<String> texts, {String taskType = 'SEMANTIC_SIMILARITY'});
}

abstract class ExtractionProvider {
  Future<Map<String, dynamic>> extractResume(String text);
  Future<Map<String, dynamic>> extractJob(String text);
}

class LlmMatchSkill {
  final String skill;
  final String jobEvidence;

  const LlmMatchSkill({required this.skill, required this.jobEvidence});

  Map<String, dynamic> toJson() => {'skill': skill, 'jobEvidence': jobEvidence};

  factory LlmMatchSkill.fromJson(Map<String, dynamic> json) => LlmMatchSkill(
        skill: json['skill']?.toString() ?? '',
        jobEvidence: json['jobEvidence']?.toString() ?? '',
      );
}

class LlmMissingSkill {
  final String skill;
  final String jobEvidence;
  final bool mandatory;

  const LlmMissingSkill({required this.skill, required this.jobEvidence, this.mandatory = true});

  Map<String, dynamic> toJson() => {'skill': skill, 'jobEvidence': jobEvidence, 'mandatory': mandatory};

  factory LlmMissingSkill.fromJson(Map<String, dynamic> json) => LlmMissingSkill(
        skill: json['skill']?.toString() ?? '',
        jobEvidence: json['jobEvidence']?.toString() ?? '',
        mandatory: json['mandatory'] as bool? ?? true,
      );
}

class LlmMatchResult {
  final bool isRelevant;
  final double confidence; // 0.0 to 1.0
  final String roleFamily;
  final int relevanceScore; // 0 - 100
  final int roleMatch;
  final int skillMatch;
  final int experienceMatch;
  final int educationMatch;
  final int domainMatch;
  final int locationMatch;
  final String reason;
  final List<LlmMatchSkill> matchedSkills;
  final List<LlmMissingSkill> missingImportantSkills;
  final List<String> redFlags;

  const LlmMatchResult({
    required this.isRelevant,
    required this.confidence,
    required this.roleFamily,
    required this.relevanceScore,
    this.roleMatch = 0,
    this.skillMatch = 0,
    this.experienceMatch = 0,
    this.educationMatch = 0,
    this.domainMatch = 0,
    this.locationMatch = 0,
    required this.reason,
    this.matchedSkills = const [],
    this.missingImportantSkills = const [],
    this.redFlags = const [],
  });

  Map<String, dynamic> toJson() => {
        'isRelevant': isRelevant,
        'confidence': confidence,
        'roleFamily': roleFamily,
        'relevanceScore': relevanceScore,
        'roleMatch': roleMatch,
        'skillMatch': skillMatch,
        'experienceMatch': experienceMatch,
        'educationMatch': educationMatch,
        'domainMatch': domainMatch,
        'locationMatch': locationMatch,
        'reason': reason,
        'matchedSkills': matchedSkills.map((s) => s.toJson()).toList(),
        'missingImportantSkills': missingImportantSkills.map((s) => s.toJson()).toList(),
        'redFlags': redFlags,
      };

  factory LlmMatchResult.fromJson(Map<String, dynamic> json) => LlmMatchResult(
        isRelevant: json['isRelevant'] as bool? ?? false,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
        roleFamily: json['roleFamily']?.toString() ?? 'UNKNOWN',
        relevanceScore: (json['relevanceScore'] as num?)?.toInt() ?? 0,
        roleMatch: (json['roleMatch'] as num?)?.toInt() ?? 0,
        skillMatch: (json['skillMatch'] as num?)?.toInt() ?? 0,
        experienceMatch: (json['experienceMatch'] as num?)?.toInt() ?? 0,
        educationMatch: (json['educationMatch'] as num?)?.toInt() ?? 0,
        domainMatch: (json['domainMatch'] as num?)?.toInt() ?? 0,
        locationMatch: (json['locationMatch'] as num?)?.toInt() ?? 0,
        reason: json['reason']?.toString() ?? '',
        matchedSkills: (json['matchedSkills'] as List?)?.map((e) => LlmMatchSkill.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
        missingImportantSkills: (json['missingImportantSkills'] as List?)?.map((e) => LlmMissingSkill.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
        redFlags: (json['redFlags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

abstract class MatchingProvider {
  Future<LlmMatchResult> classify({
    required Map<String, dynamic> profileJson,
    required Map<String, dynamic> jobJson,
    required Map<String, dynamic> deterministicFindings,
  });
}
