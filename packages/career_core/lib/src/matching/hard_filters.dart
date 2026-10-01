import '../jobs/location_parser.dart';
import '../jobs/normalized_job.dart';
import '../jobs/section_splitter.dart';
import '../jobs/seniority.dart';
import '../profile/candidate_profile.dart';
import '../taxonomy/skill_matcher.dart';
import '../taxonomy/skills.dart';
import 'matching_config.dart';

class HardFilterResult {
  final bool passed;
  final String? rejectionReason; // e.g. EXPERIENCE_GAP, MANDATORY_STACK, etc.

  const HardFilterResult.pass() : passed = true, rejectionReason = null;
  const HardFilterResult.reject(this.rejectionReason) : passed = false;
}

class HardFilters {
  HardFilters._();

  static HardFilterResult evaluate({
    required NormalizedJob job,
    required CandidateProfile candidate,
    required MatchingConfig config,
    Set<String> hiddenCompanies = const {},
    Set<String> hiddenRoles = const {},
  }) {
    // 1. Hidden entities
    if (hiddenCompanies.contains(job.companyNorm) || hiddenCompanies.contains(job.company.toLowerCase())) {
      return const HardFilterResult.reject('HIDDEN_COMPANY');
    }
    if (hiddenRoles.contains(job.roleFamily) || hiddenRoles.contains(job.titleNorm)) {
      return const HardFilterResult.reject('HIDDEN_ROLE');
    }

    // 2. Experience Gap
    final allowedMaxMonths = candidate.experienceMonths + config.experienceToleranceMonths;
    if (job.expMinMonths > allowedMaxMonths && job.expMinMonths > 0) {
      return HardFilterResult.reject('EXPERIENCE_GAP:${job.expMinMonths}m > ${allowedMaxMonths}m');
    }

    // 3. Seniority Mismatch
    final candidateRank = candidate.experienceLevel == ExperienceLevel.junior
        ? 1
        : (candidate.experienceLevel == ExperienceLevel.mid
            ? 2
            : (candidate.experienceLevel == ExperienceLevel.senior ? 3 : 4));

    if (job.seniority == SeniorityLevel.management && candidateRank < 3) {
      return const HardFilterResult.reject('SENIORITY_MISMATCH:Management track requires senior experience');
    }
    if (job.seniority.rank - candidateRank >= config.seniorityMaxGap + 1) {
      return HardFilterResult.reject('SENIORITY_MISMATCH:${job.seniority.name} vs ${candidate.experienceLevel.name}');
    }

    // 4. Internship Only
    if (job.seniority == SeniorityLevel.intern && !candidate.employmentTypes.contains('INTERNSHIP') && candidate.experienceMonths >= 24) {
      return const HardFilterResult.reject('INTERNSHIP_ONLY');
    }

    // 5. Location & Remote Region
    if (job.workMode == WorkMode.onsite || job.workMode == WorkMode.hybrid) {
      if (candidate.remotePreference == RemotePreferenceMode.remoteOnly && !candidate.willRelocate) {
        return const HardFilterResult.reject('LOCATION:Candidate is remote only and job is onsite/hybrid');
      }
      if (!candidate.willRelocate && candidate.preferredLocations.isNotEmpty && job.city.isNotEmpty) {
        final matchesPreferred = candidate.preferredLocations.any((loc) => loc.toLowerCase() == job.city.toLowerCase());
        final isCurrentCity = candidate.currentLocation.toLowerCase() == job.city.toLowerCase();
        if (!matchesPreferred && !isCurrentCity) {
          return HardFilterResult.reject('LOCATION:Job in ${job.city} does not match candidate locations');
        }
      }
    }

    if (job.workMode == WorkMode.remote) {
      if (job.country == 'United States' && !candidate.countries.contains('US')) {
        final descLower = job.descriptionText.toLowerCase();
        if (descLower.contains('us only') || descLower.contains('united states only') || descLower.contains('authorized to work in the united states')) {
          return const HardFilterResult.reject('REMOTE_REGION:US only remote restriction');
        }
      }
    }

    // 6. Mandatory Stack
    final requiredCoreSkills = job.skills
        .where((s) => s.requirement == SkillRequirementType.required)
        .map((s) => s.canonical)
        .where((s) {
          final def = SkillTaxonomy.lookup(s);
          return def == null || def.kind == SkillKind.core;
        })
        .toList();

    if (requiredCoreSkills.length >= 2) {
      var candidateHasAtLeastOne = false;
      for (final req in requiredCoreSkills) {
        final match = SkillMatcher.matchSkill(
          jobSkill: req,
          candidateCanonicalSkills: candidate.allCanonicalSkills,
        );
        if (match.quality == SkillMatchQuality.exact || match.quality == SkillMatchQuality.equivalent) {
          candidateHasAtLeastOne = true;
          break;
        }
      }
      if (!candidateHasAtLeastOne) {
        return HardFilterResult.reject('MANDATORY_STACK:Missing all required core skills: ${requiredCoreSkills.take(3).join(', ')}');
      }
    }

    // 7. Title Stack
    final titleSkills = job.skills.where((s) => s.fromTitle).map((s) => s.canonical).toList();
    for (final ts in titleSkills) {
      final match = SkillMatcher.matchSkill(
        jobSkill: ts,
        candidateCanonicalSkills: candidate.allCanonicalSkills,
      );
      if (match.quality == SkillMatchQuality.none && match.weight < 0.5) {
        return HardFilterResult.reject('TITLE_STACK:Lacks core technology from title: $ts');
      }
    }

    return const HardFilterResult.pass();
  }
}
