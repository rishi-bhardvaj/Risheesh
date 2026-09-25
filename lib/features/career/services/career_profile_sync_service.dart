import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../domain/resume_profile_models.dart';

class CareerProfileSyncService {
  List<ProfileDiffItem> computeDifferences({
    required UserProfile existingProfile,
    required ResumeProfile extractedProfile,
  }) {
    final diffs = <ProfileDiffItem>[];

    // Current / Target Role
    if (extractedProfile.targetRole != null &&
        extractedProfile.targetRole!.value.isNotEmpty &&
        extractedProfile.targetRole!.value.toLowerCase() !=
            (existingProfile.currentRole ?? '').toLowerCase()) {
      diffs.add(
        ProfileDiffItem(
          fieldName: 'currentRole',
          label: 'Primary Role / Title',
          currentValue: existingProfile.currentRole,
          extractedValue: extractedProfile.targetRole!.value,
          confidence: extractedProfile.targetRole!.confidence,
          selectedByDefault: true,
        ),
      );
    }

    // Experience Years
    if (extractedProfile.experienceYears != null &&
        extractedProfile.experienceYears!.value > 0 &&
        extractedProfile.experienceYears!.value !=
            existingProfile.experienceYears) {
      diffs.add(
        ProfileDiffItem(
          fieldName: 'experienceYears',
          label: 'Years of Experience',
          currentValue: '${existingProfile.experienceYears}',
          extractedValue: '${extractedProfile.experienceYears!.value}',
          confidence: extractedProfile.experienceYears!.confidence,
          selectedByDefault: existingProfile.experienceYears == 0,
        ),
      );
    }

    // Programming Languages
    if (extractedProfile.programmingLanguages.isNotEmpty) {
      final extractedStr = extractedProfile.programmingLanguages
          .map((e) => e.value)
          .join(', ');
      if (extractedStr.toLowerCase() !=
          (existingProfile.programmingLanguages ?? '').toLowerCase()) {
        diffs.add(
          ProfileDiffItem(
            fieldName: 'programmingLanguages',
            label: 'Programming Languages',
            currentValue: existingProfile.programmingLanguages,
            extractedValue: extractedStr,
            confidence: ExtractionConfidence.high,
            selectedByDefault: true,
          ),
        );
      }
    }

    // Frameworks & Libraries
    if (extractedProfile.frameworks.isNotEmpty) {
      final extractedStr =
          extractedProfile.frameworks.map((e) => e.value).join(', ');
      if (extractedStr.toLowerCase() !=
          (existingProfile.frameworks ?? '').toLowerCase()) {
        diffs.add(
          ProfileDiffItem(
            fieldName: 'frameworks',
            label: 'Frameworks & Libraries',
            currentValue: existingProfile.frameworks,
            extractedValue: extractedStr,
            confidence: ExtractionConfidence.high,
            selectedByDefault: true,
          ),
        );
      }
    }

    // Tools, Cloud & Tech Stack
    if (extractedProfile.toolsAndCloud.isNotEmpty) {
      final extractedStr =
          extractedProfile.toolsAndCloud.map((e) => e.value).join(', ');
      final currentSkills = existingProfile.skills ?? '';
      if (!extractedProfile.toolsAndCloud.every(
          (t) => currentSkills.toLowerCase().contains(t.value.toLowerCase()))) {
        diffs.add(
          ProfileDiffItem(
            fieldName: 'skills',
            label: 'Tools, Cloud & General Skills',
            currentValue: existingProfile.skills,
            extractedValue: extractedStr,
            confidence: ExtractionConfidence.high,
            selectedByDefault: true,
          ),
        );
      }
    }

    // Education
    if (extractedProfile.education != null &&
        extractedProfile.education!.value.isNotEmpty &&
        extractedProfile.education!.value.toLowerCase() !=
            (existingProfile.education ?? '').toLowerCase()) {
      diffs.add(
        ProfileDiffItem(
          fieldName: 'education',
          label: 'Academic Background',
          currentValue: existingProfile.education,
          extractedValue: extractedProfile.education!.value,
          confidence: extractedProfile.education!.confidence,
          selectedByDefault: true,
        ),
      );
    }

    return diffs;
  }

  UserProfilesCompanion buildUpdatedCompanion({
    required UserProfile existingProfile,
    required List<ProfileDiffItem> approvedDiffs,
  }) {
    String? currentRole = existingProfile.currentRole;
    double experienceYears = existingProfile.experienceYears;
    String? languages = existingProfile.programmingLanguages;
    String? frameworks = existingProfile.frameworks;
    String? skills = existingProfile.skills;
    String? education = existingProfile.education;

    for (final diff in approvedDiffs) {
      switch (diff.fieldName) {
        case 'currentRole':
          currentRole = diff.extractedValue;
          break;
        case 'experienceYears':
          experienceYears =
              double.tryParse(diff.extractedValue) ?? experienceYears;
          break;
        case 'programmingLanguages':
          languages = _mergeCommaSeparated(languages, diff.extractedValue);
          break;
        case 'frameworks':
          frameworks = _mergeCommaSeparated(frameworks, diff.extractedValue);
          break;
        case 'skills':
          skills = _mergeCommaSeparated(skills, diff.extractedValue);
          break;
        case 'education':
          education = diff.extractedValue;
          break;
      }
    }

    return UserProfilesCompanion(
      id: Value(existingProfile.id),
      name: Value(existingProfile.name),
      currentRole: Value(currentRole),
      experienceYears: Value(experienceYears),
      skills: Value(skills),
      programmingLanguages: Value(languages),
      frameworks: Value(frameworks),
      preferredRoles: Value(existingProfile.preferredRoles),
      preferredLocations: Value(existingProfile.preferredLocations),
      remotePreference: Value(existingProfile.remotePreference),
      expectedSalary: Value(existingProfile.expectedSalary),
      preferredEmploymentType: Value(existingProfile.preferredEmploymentType),
      noticePeriod: Value(existingProfile.noticePeriod),
      education: Value(education),
      resumePreferences: Value(existingProfile.resumePreferences),
      createdAt: Value(existingProfile.createdAt),
      updatedAt: Value(DateTime.now()),
    );
  }

  String _mergeCommaSeparated(String? existing, String incoming) {
    final set = <String>{};
    if (existing != null && existing.isNotEmpty) {
      set.addAll(existing.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    }
    set.addAll(incoming.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    return set.join(', ');
  }
}
