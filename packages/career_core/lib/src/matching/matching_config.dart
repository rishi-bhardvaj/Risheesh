class MatchingWeights {
  final double role;
  final double skill;
  final double semantic;
  final double experience;
  final double project;
  final double domain;
  final double education;
  final double location;

  const MatchingWeights({
    this.role = 0.22,
    this.skill = 0.30,
    this.semantic = 0.18,
    this.experience = 0.12,
    this.project = 0.06,
    this.domain = 0.04,
    this.education = 0.03,
    this.location = 0.05,
  });

  double get sum => role + skill + semantic + experience + project + domain + education + location;

  Map<String, dynamic> toJson() => {
        'role': role,
        'skill': skill,
        'semantic': semantic,
        'experience': experience,
        'project': project,
        'domain': domain,
        'education': education,
        'location': location,
      };

  factory MatchingWeights.fromJson(Map<String, dynamic> json) => MatchingWeights(
        role: (json['role'] as num?)?.toDouble() ?? 0.22,
        skill: (json['skill'] as num?)?.toDouble() ?? 0.30,
        semantic: (json['semantic'] as num?)?.toDouble() ?? 0.18,
        experience: (json['experience'] as num?)?.toDouble() ?? 0.12,
        project: (json['project'] as num?)?.toDouble() ?? 0.06,
        domain: (json['domain'] as num?)?.toDouble() ?? 0.04,
        education: (json['education'] as num?)?.toDouble() ?? 0.03,
        location: (json['location'] as num?)?.toDouble() ?? 0.05,
      );
}

class MatchingThresholds {
  final int high;
  final int relevant;
  final int possible;
  final int llmGateMin;
  final double semanticFloor;
  final double llmMinConfidenceHigh;

  const MatchingThresholds({
    this.high = 80,
    this.relevant = 65,
    this.possible = 50,
    this.llmGateMin = 45,
    this.semanticFloor = 0.55,
    this.llmMinConfidenceHigh = 0.7,
  });

  Map<String, dynamic> toJson() => {
        'high': high,
        'relevant': relevant,
        'possible': possible,
        'llmGateMin': llmGateMin,
        'semanticFloor': semanticFloor,
        'llmMinConfidenceHigh': llmMinConfidenceHigh,
      };

  factory MatchingThresholds.fromJson(Map<String, dynamic> json) => MatchingThresholds(
        high: (json['high'] as num?)?.toInt() ?? 80,
        relevant: (json['relevant'] as num?)?.toInt() ?? 65,
        possible: (json['possible'] as num?)?.toInt() ?? 50,
        llmGateMin: (json['llmGateMin'] as num?)?.toInt() ?? 45,
        semanticFloor: (json['semanticFloor'] as num?)?.toDouble() ?? 0.55,
        llmMinConfidenceHigh: (json['llmMinConfidenceHigh'] as num?)?.toDouble() ?? 0.7,
      );
}

class MatchingConfig {
  final int version;
  final MatchingWeights weights;
  final double alpha;
  final MatchingThresholds thresholds;
  final int experienceToleranceMonths;
  final double internshipWeight;
  final int seniorityMaxGap;
  final int overqualifiedPenalty;
  final int feedbackAdjMin;
  final int feedbackAdjMax;
  final List<String> alwaysAllowedFamilies;
  final Map<String, List<String>> familyAdjacency;
  final List<String> blockingRedFlags;

  const MatchingConfig({
    this.version = 1,
    this.weights = const MatchingWeights(),
    this.alpha = 0.55,
    this.thresholds = const MatchingThresholds(),
    this.experienceToleranceMonths = 18,
    this.internshipWeight = 0.5,
    this.seniorityMaxGap = 1,
    this.overqualifiedPenalty = 8,
    this.feedbackAdjMin = -15,
    this.feedbackAdjMax = 5,
    this.alwaysAllowedFamilies = const [],
    this.familyAdjacency = const {
      'MOBILE': ['FULLSTACK', 'FRONTEND'],
      'BACKEND': ['FULLSTACK', 'DEVOPS_SRE_PLATFORM'],
      'FRONTEND': ['FULLSTACK', 'MOBILE'],
      'FULLSTACK': ['BACKEND', 'FRONTEND', 'MOBILE'],
    },
    this.blockingRedFlags = const [
      'unpaid', 'commission only', 'bond', 'security deposit', 'pay to apply',
    ],
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'weights': weights.toJson(),
        'alpha': alpha,
        'thresholds': thresholds.toJson(),
        'experienceToleranceMonths': experienceToleranceMonths,
        'internshipWeight': internshipWeight,
        'seniorityMaxGap': seniorityMaxGap,
        'overqualifiedPenalty': overqualifiedPenalty,
        'feedbackAdjMin': feedbackAdjMin,
        'feedbackAdjMax': feedbackAdjMax,
        'alwaysAllowedFamilies': alwaysAllowedFamilies,
        'familyAdjacency': familyAdjacency,
        'blockingRedFlags': blockingRedFlags,
      };

  factory MatchingConfig.fromJson(Map<String, dynamic> json) {
    final weights = MatchingWeights.fromJson(json['weights'] as Map<String, dynamic>? ?? const {});
    if ((weights.sum - 1.0).abs() > 0.01) {
      throw ArgumentError('MatchingConfig weights must sum to 1.0, got ${weights.sum}');
    }
    return MatchingConfig(
      version: (json['version'] as num?)?.toInt() ?? 1,
      weights: weights,
      alpha: (json['alpha'] as num?)?.toDouble() ?? 0.55,
      thresholds: MatchingThresholds.fromJson(json['thresholds'] as Map<String, dynamic>? ?? const {}),
      experienceToleranceMonths: (json['experienceToleranceMonths'] as num?)?.toInt() ?? 18,
      internshipWeight: (json['internshipWeight'] as num?)?.toDouble() ?? 0.5,
      seniorityMaxGap: (json['seniorityMaxGap'] as num?)?.toInt() ?? 1,
      overqualifiedPenalty: (json['overqualifiedPenalty'] as num?)?.toInt() ?? 8,
      feedbackAdjMin: (json['feedbackAdjMin'] as num?)?.toInt() ?? -15,
      feedbackAdjMax: (json['feedbackAdjMax'] as num?)?.toInt() ?? 5,
      alwaysAllowedFamilies: (json['alwaysAllowedFamilies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      familyAdjacency: (json['familyAdjacency'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as List).map((e) => e.toString()).toList())) ?? const {},
      blockingRedFlags: (json['blockingRedFlags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
