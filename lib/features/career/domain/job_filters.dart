import 'package:career_core/career_core.dart';
import '../../../core/database/app_database.dart';

enum JobSegment {
  forYou('For you'),
  needsReview('Needs review'),
  saved('Saved'),
  applied('Applied'),
  filteredOut('Filtered out');

  final String label;
  const JobSegment(this.label);
}

enum QuickPill {
  remote('Remote'),
  newToday('New today'),
  best('Best (≥80)');

  final String label;
  const QuickPill(this.label);
}

class JobFilterCriteria {
  final String? roleFamily;
  final String? source;
  final String? location;
  final String? company;
  final int? maxDaysOld; // 1, 3, 7, 30
  final double? minScore;
  final Set<String> requiredSkills;

  const JobFilterCriteria({
    this.roleFamily,
    this.source,
    this.location,
    this.company,
    this.maxDaysOld,
    this.minScore,
    this.requiredSkills = const {},
  });

  bool get isActive =>
      roleFamily != null ||
      source != null ||
      location != null ||
      company != null ||
      maxDaysOld != null ||
      minScore != null ||
      requiredSkills.isNotEmpty;

  JobFilterCriteria copyWith({
    String? roleFamily,
    String? source,
    String? location,
    String? company,
    int? maxDaysOld,
    double? minScore,
    Set<String>? requiredSkills,
    bool clearRoleFamily = false,
    bool clearSource = false,
    bool clearLocation = false,
    bool clearCompany = false,
    bool clearMaxDaysOld = false,
    bool clearMinScore = false,
  }) {
    return JobFilterCriteria(
      roleFamily: clearRoleFamily ? null : (roleFamily ?? this.roleFamily),
      source: clearSource ? null : (source ?? this.source),
      location: clearLocation ? null : (location ?? this.location),
      company: clearCompany ? null : (company ?? this.company),
      maxDaysOld: clearMaxDaysOld ? null : (maxDaysOld ?? this.maxDaysOld),
      minScore: clearMinScore ? null : (minScore ?? this.minScore),
      requiredSkills: requiredSkills ?? this.requiredSkills,
    );
  }
}

/// Helper model wrapping a Job with its match explanation and tier for display.
class ScoredJobDisplay {
  final Job job;
  final String tier;
  final double score;
  final String explanation;
  final List<String> matchedSkills;
  final List<String> missingSkills;

  const ScoredJobDisplay({
    required this.job,
    required this.tier,
    required this.score,
    required this.explanation,
    required this.matchedSkills,
    required this.missingSkills,
  });

  bool get isHighlyRelevant => tier == 'HIGHLY_RELEVANT';
  bool get isRelevant => tier == 'RELEVANT';
  bool get isPossibleMatch => tier == 'POSSIBLE_MATCH';
  bool get isNotRelevant => tier == 'NOT_RELEVANT';
}

/// Pure filtering function that strictly rejects non-relevant jobs from main feeds
/// and categorizes into the requested JobSegment with quick pills and advanced criteria.
List<ScoredJobDisplay> filterJobsList({
  required List<Job> jobs,
  required JobSegment segment,
  Set<QuickPill> quickPills = const {},
  JobFilterCriteria criteria = const JobFilterCriteria(),
  String query = '',
  Set<String> appliedJobIds = const {},
  DateTime? now,
}) {
  final q = query.trim().toLowerCase();
  final current = now ?? DateTime.now();
  final oneDayAgo = current.subtract(const Duration(hours: 24));
  final out = <ScoredJobDisplay>[];

  for (final j in jobs) {
    // 1. Text Query Filter
    if (q.isNotEmpty) {
      final text = '${j.title} ${j.company} ${j.skills ?? ''} ${j.location ?? ''}'.toLowerCase();
      if (!text.contains(q)) continue;
    }

    // Determine tier and score
    var tier = 'UNSCORED';
    var score = 0.0;
    var explanation = '';
    try {
      final dynamic d = j;
      tier = d.relevanceTier as String? ?? 'UNSCORED';
      score = (d.relevanceScore as num?)?.toDouble() ?? 0.0;
      explanation = d.explanation as String? ?? '';
    } catch (_) {}

    // If unscored in database, classify role using RoleClassifier as defensive gate
    if (tier == 'UNSCORED') {
      final rf = RoleClassifier.classify(title: j.title, description: j.description);
      if (!RoleClassifier.isEngineeringRole(rf)) {
        tier = 'NOT_RELEVANT';
        score = 0.0;
        explanation = 'Non-engineering role ($rf)';
      }
    }

    // Parse matched and missing skills from skills column
    final jobSkills = (j.skills ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final matchedSkills = jobSkills.take(4).toList();
    final missingSkills = jobSkills.length > 4 ? [jobSkills[4]] : <String>[];

    // 2. Segment Filter
    final isApplied = appliedJobIds.contains(j.id);
    final inSegment = switch (segment) {
      JobSegment.forYou => (tier == 'HIGHLY_RELEVANT' || tier == 'RELEVANT') && !isApplied,
      JobSegment.needsReview => tier == 'POSSIBLE_MATCH' && !isApplied,
      JobSegment.saved => j.isSaved,
      JobSegment.applied => isApplied,
      JobSegment.filteredOut => tier == 'NOT_RELEVANT',
    };

    if (!inSegment) continue;

    // 3. Quick Pills
    if (quickPills.contains(QuickPill.remote)) {
      final loc = '${j.location ?? ''} ${j.employmentType ?? ''}'.toLowerCase();
      if (!loc.contains('remote')) continue;
    }
    if (quickPills.contains(QuickPill.newToday)) {
      final date = j.postedDate ?? j.discoveredAt;
      if (date.isBefore(oneDayAgo)) continue;
    }
    if (quickPills.contains(QuickPill.best)) {
      if (score < 80.0) continue;
    }

    // 4. Advanced Filter Criteria
    try {
      final dynamic d = j;
      final jRoleFamily = d.roleFamily as String?;
      if (criteria.roleFamily != null && jRoleFamily != null && jRoleFamily != criteria.roleFamily) {
        continue;
      }
    } catch (_) {}

    if (criteria.source != null && j.source != null && j.source != criteria.source) {
      continue;
    }
    if (criteria.location != null && j.location != null) {
      if (!j.location!.toLowerCase().contains(criteria.location!.toLowerCase())) continue;
    }
    if (criteria.company != null) {
      if (!j.company.toLowerCase().contains(criteria.company!.toLowerCase())) continue;
    }
    if (criteria.maxDaysOld != null) {
      final cutoff = current.subtract(Duration(days: criteria.maxDaysOld!));
      final date = j.postedDate ?? j.discoveredAt;
      if (date.isBefore(cutoff)) continue;
    }
    if (criteria.minScore != null && score < criteria.minScore!) {
      continue;
    }
    if (criteria.requiredSkills.isNotEmpty) {
      final lowerSkills = (j.skills ?? '').toLowerCase();
      final hasAll = criteria.requiredSkills.every((s) => lowerSkills.contains(s.toLowerCase()));
      if (!hasAll) continue;
    }

    out.add(ScoredJobDisplay(
      job: j,
      tier: tier,
      score: score,
      explanation: explanation,
      matchedSkills: matchedSkills,
      missingSkills: missingSkills,
    ));
  }

  // Sort by score descending, then date descending
  out.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final dateA = a.job.postedDate ?? a.job.discoveredAt;
    final dateB = b.job.postedDate ?? b.job.discoveredAt;
    return dateB.compareTo(dateA);
  });

  return out;
}
