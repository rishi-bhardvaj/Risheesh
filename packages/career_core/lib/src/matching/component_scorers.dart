import '../jobs/location_parser.dart';
import '../jobs/normalized_job.dart';
import '../profile/candidate_profile.dart';
import 'matching_config.dart';

class MatchComponents {
  final double role;
  final double skill;
  final double semantic;
  final double experience;
  final double project;
  final double domain;
  final double education;
  final double location;

  const MatchComponents({
    required this.role,
    required this.skill,
    required this.semantic,
    required this.experience,
    required this.project,
    required this.domain,
    required this.education,
    required this.location,
  });

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

  double computeDeterministicScore(MatchingWeights weights) {
    return (role * weights.role) +
        (skill * weights.skill) +
        (semantic * weights.semantic) +
        (experience * weights.experience) +
        (project * weights.project) +
        (domain * weights.domain) +
        (education * weights.education) +
        (location * weights.location);
  }
}

class ComponentScorers {
  ComponentScorers._();

  static double scoreRole({
    required NormalizedJob job,
    required CandidateProfile candidate,
    required MatchingConfig config,
  }) {
    if (job.roleFamily == candidate.primaryRoleFamily) {
      return 100.0;
    }
    if (candidate.adjacentRoleFamilies.contains(job.roleFamily)) {
      return 75.0;
    }
    final adjList = config.familyAdjacency[candidate.primaryRoleFamily] ?? const [];
    if (adjList.contains(job.roleFamily)) {
      return 70.0;
    }
    return 30.0;
  }

  static double scoreExperience({
    required NormalizedJob job,
    required CandidateProfile candidate,
    required MatchingConfig config,
  }) {
    final candMonths = candidate.experienceMonths;
    final reqMonths = job.expMinMonths;

    if (reqMonths <= 0) return 90.0;
    if (candMonths >= reqMonths && candMonths <= reqMonths + 36) {
      return 100.0;
    }
    if (candMonths < reqMonths) {
      // Within tolerance
      final ratio = candMonths / reqMonths;
      return (ratio * 100.0).clamp(40.0, 95.0);
    }
    // Overqualified: soft penalty
    return (100.0 - config.overqualifiedPenalty).clamp(50.0, 100.0);
  }

  static double scoreLocation({
    required NormalizedJob job,
    required CandidateProfile candidate,
  }) {
    if (job.workMode == WorkMode.remote) return 100.0;
    if (job.city.isNotEmpty) {
      if (candidate.currentLocation.toLowerCase() == job.city.toLowerCase()) return 100.0;
      if (candidate.preferredLocations.any((loc) => loc.toLowerCase() == job.city.toLowerCase())) return 95.0;
    }
    return candidate.willRelocate ? 70.0 : 40.0;
  }

  static double scoreEducation({
    required NormalizedJob job,
    required CandidateProfile candidate,
  }) {
    return 90.0; // Default solid score for standard tech degrees
  }

  static double scoreDomain({
    required NormalizedJob job,
    required CandidateProfile candidate,
  }) {
    var hits = 0;
    final text = job.descriptionText.toLowerCase();
    for (final d in candidate.domains) {
      if (text.contains(d.toLowerCase())) hits++;
    }
    return hits > 0 ? 100.0 : 70.0;
  }
}
