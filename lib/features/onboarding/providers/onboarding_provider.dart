import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/theme_provider.dart';

final onboardingCompletedProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(AppConstants.keyOnboardingCompleted) ?? false;
});

final userProfileStreamProvider = StreamProvider<UserProfile?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchProfile();
});

class OnboardingService {
  final AppDatabase db;
  final Ref ref;
  static const _uuid = Uuid();

  OnboardingService(this.db, this.ref);

  Future<void> completeOnboarding({
    required String name,
    String? currentRole,
    double experienceYears = 0.0,
    String? skills,
    String? preferredRoles,
    String? preferredLocations,
    String remotePreference = 'any',
    String? expectedSalary,
    String? resumeFilePath,
    String? resumeFileName,
  }) async {
    // If a resume was uploaded during onboarding, insert it into the resumes table
    String? resumeId;
    if (resumeFilePath != null) {
      final now = DateTime.now();
      final companion = ResumesCompanion(
        id: Value(_uuid.v4()),
        name: Value(resumeFileName ?? 'Resume'),
        version: const Value('1.0'),
        targetRole: Value(currentRole),
        filePath: Value(resumeFilePath),
        fileName: Value(resumeFileName ?? 'Resume'),
        notes: const Value('Uploaded during first-run onboarding'),
        isPrimary: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      );
      await db.insertResume(companion);
      resumeId = companion.id.value;
    }

    final existing = await db.getProfile();
    final profileId = existing?.id ?? resumeId ?? const Uuid().v4();
    final now = DateTime.now();

    final companion = UserProfilesCompanion(
      id: Value(profileId),
      name: Value(name.trim().isEmpty ? AppConstants.defaultUserName : name.trim()),
      currentRole: Value(currentRole?.trim().isEmpty == true ? null : currentRole?.trim()),
      experienceYears: Value(experienceYears),
      skills: Value(skills?.trim().isEmpty == true ? null : skills?.trim()),
      preferredRoles: Value(preferredRoles?.trim().isEmpty == true ? null : preferredRoles?.trim()),
      preferredLocations: Value(preferredLocations?.trim().isEmpty == true ? null : preferredLocations?.trim()),
      remotePreference: Value(remotePreference),
      expectedSalary: Value(expectedSalary?.trim().isEmpty == true ? null : expectedSalary?.trim()),
      createdAt: Value(existing?.createdAt ?? now),
      updatedAt: Value(now),
    );

    await db.upsertProfile(companion);

    // If a resume was uploaded, set it as primary
    if (resumeId != null) {
      await db.setPrimaryResume(resumeId);
    }

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(AppConstants.keyOnboardingCompleted, true);
    ref.read(onboardingCompletedProvider.notifier).state = true;
  }
}

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final db = ref.watch(databaseProvider);
  return OnboardingService(db, ref);
});