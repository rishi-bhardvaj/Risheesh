import '../../../core/database/app_database.dart';
import 'resume_profile_models.dart';

class JobSearchCriteria {
  final List<String> roleQueries;
  final List<String> topSkills;
  final String? preferredLocation;
  final bool remoteOnly;
  final double minExperience;

  const JobSearchCriteria({
    required this.roleQueries,
    required this.topSkills,
    this.preferredLocation,
    this.remoteOnly = false,
    this.minExperience = 0,
  });

  bool get isEmpty => roleQueries.isEmpty && topSkills.isEmpty;
}

class JobSearchCriteriaBuilder {
  static JobSearchCriteria buildCriteria({
    required List<Resume> activeResumes,
    required Map<String, ResumeProfile> parsedProfiles,
    required UserProfile? profile,
  }) {
    final roleSet = <String>{};
    final skillSet = <String>{};
    double experience = profile?.experienceYears ?? 0;
    bool isRemote = (profile?.remotePreference ?? '').toLowerCase() == 'remote';
    String? location = profile?.preferredLocations?.split(',').firstOrNull?.trim();

    // 1. Collect from active resumes
    for (final resume in activeResumes) {
      if (resume.targetRole != null && resume.targetRole!.trim().isNotEmpty) {
        roleSet.add(resume.targetRole!.trim());
      }
      final parsed = parsedProfiles[resume.id];
      if (parsed != null) {
        if (parsed.targetRole != null) {
          roleSet.add(parsed.targetRole!.value);
        }
        for (final lang in parsed.programmingLanguages) {
          skillSet.add(lang.value);
        }
        for (final fw in parsed.frameworks) {
          skillSet.add(fw.value);
        }
        for (final tool in parsed.toolsAndCloud) {
          skillSet.add(tool.value);
        }
        if (parsed.experienceYears != null && parsed.experienceYears!.value > experience) {
          experience = parsed.experienceYears!.value;
        }
      }
    }

    // 2. Supplement from user career profile
    if (profile != null) {
      if (profile.currentRole != null && profile.currentRole!.trim().isNotEmpty) {
        roleSet.add(profile.currentRole!.trim());
      }
      if (profile.preferredRoles != null) {
        for (final r in profile.preferredRoles!.split(',')) {
          if (r.trim().isNotEmpty) roleSet.add(r.trim());
        }
      }
      if (profile.skills != null) {
        for (final s in profile.skills!.split(',')) {
          if (s.trim().isNotEmpty) skillSet.add(s.trim());
        }
      }
    }

    // Fallback if empty
    if (roleSet.isEmpty) {
      roleSet.add('Software Engineer');
    }

    return JobSearchCriteria(
      roleQueries: roleSet.take(3).toList(),
      topSkills: skillSet.take(8).toList(),
      preferredLocation: location,
      remoteOnly: isRemote,
      minExperience: experience,
    );
  }
}
