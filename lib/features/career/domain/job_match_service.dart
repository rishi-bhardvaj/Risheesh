import '../../../core/database/app_database.dart';

class JobMatchResult {
  final int matchPercentage;
  final List<String> matchingFactors;
  final List<String> gapFactors;
  final bool hasSufficientData;
  final String label;

  static const String disclaimer =
      'Profile-to-job match based on your saved preferences and job data.';

  const JobMatchResult({
    required this.matchPercentage,
    required this.matchingFactors,
    required this.gapFactors,
    required this.hasSufficientData,
    required this.label,
  });

  factory JobMatchResult.insufficient() {
    return const JobMatchResult(
      matchPercentage: 0,
      matchingFactors: [],
      gapFactors: [],
      hasSufficientData: false,
      label: 'Insufficient Profile Data',
    );
  }
}

class JobMatchService {
  static JobMatchResult calculateMatch({
    required Job job,
    required UserProfile? profile,
  }) {
    if (profile == null) {
      return JobMatchResult.insufficient();
    }

    final userSkills = _extractKeywords([
      profile.skills,
      profile.programmingLanguages,
      profile.frameworks,
    ]);

    final userRoles = _extractKeywords([
      profile.preferredRoles,
      profile.currentRole,
    ]);

    final userLocations = _extractKeywords([
      profile.preferredLocations,
    ]);

    final userRemote = profile.remotePreference.toLowerCase();

    // If profile has no skills and no preferred roles, insufficient data
    if (userSkills.isEmpty && userRoles.isEmpty) {
      return JobMatchResult.insufficient();
    }

    final matchingFactors = <String>[];
    final gapFactors = <String>[];
    double totalPoints = 0;
    double maxPoints = 0;

    // 1. Role / Title Match (Weight: 30)
    maxPoints += 30;
    final jobTitleTokens = _tokenize(job.title);
    bool roleMatched = false;
    for (final role in userRoles) {
      final roleTokens = _tokenize(role);
      if (roleTokens.any((t) => jobTitleTokens.contains(t))) {
        roleMatched = true;
        matchingFactors.add('Role match: ${job.title}');
        totalPoints += 30;
        break;
      }
    }
    if (!roleMatched && userRoles.isNotEmpty) {
      gapFactors.add('Role title differs from preferred: ${userRoles.take(2).join(', ')}');
    }

    // 2. Skills Match (Weight: 40)
    final jobSkills = _extractKeywords([job.skills, job.description]);
    if (jobSkills.isNotEmpty) {
      maxPoints += 40;
      final matchedSkills = <String>[];
      final missingSkills = <String>[];

      for (final skill in jobSkills) {
        if (userSkills.contains(skill.toLowerCase())) {
          matchedSkills.add(skill);
        } else {
          missingSkills.add(skill);
        }
      }

      if (matchedSkills.isNotEmpty) {
        final skillScore = (matchedSkills.length / jobSkills.length) * 40;
        totalPoints += skillScore;
        matchingFactors.add('Skills: ${matchedSkills.take(4).join(', ')}');
      }

      if (missingSkills.isNotEmpty) {
        gapFactors.add('Missing skills: ${missingSkills.take(3).join(', ')}');
      }
    } else if (userSkills.isNotEmpty) {
      // If job has no explicit skills, check user skills against job description / title
      maxPoints += 20;
      final textToScan = '${job.title} ${job.description ?? ''}'.toLowerCase();
      final matchedFromText = userSkills.where((s) => textToScan.contains(s)).toList();
      if (matchedFromText.isNotEmpty) {
        totalPoints += (matchedFromText.length / userSkills.length.clamp(1, 5)) * 20;
        matchingFactors.add('Keywords found: ${matchedFromText.take(3).join(', ')}');
      }
    }

    // 3. Location & Remote Compatibility (Weight: 20)
    maxPoints += 20;
    final jobLoc = (job.location ?? '').toLowerCase();
    final jobEmpType = (job.employmentType ?? '').toLowerCase();
    final isJobRemote = jobLoc.contains('remote') || jobEmpType.contains('remote');

    if (userRemote == 'remote' && isJobRemote) {
      totalPoints += 20;
      matchingFactors.add('Remote preference matched');
    } else if (userRemote == 'any' || userLocations.isEmpty) {
      totalPoints += 15;
      matchingFactors.add('Location flexible');
    } else {
      bool locMatched = false;
      for (final loc in userLocations) {
        if (jobLoc.contains(loc.toLowerCase())) {
          locMatched = true;
          totalPoints += 20;
          matchingFactors.add('Location match: ${job.location}');
          break;
        }
      }
      if (!locMatched && !isJobRemote) {
        gapFactors.add('Location differs from preferred locations');
      }
    }

    // 4. Experience Compatibility (Weight: 10)
    maxPoints += 10;
    final expReq = job.experienceRequirement;
    if (expReq != null && expReq.isNotEmpty) {
      final expYearsReq = _parseExperienceYears(expReq);
      if (expYearsReq != null) {
        if (profile.experienceYears >= expYearsReq) {
          totalPoints += 10;
          matchingFactors.add('Experience requirement met ($expReq)');
        } else {
          gapFactors.add('Requires $expReq (Profile: ${profile.experienceYears} yrs)');
        }
      } else {
        totalPoints += 8;
      }
    } else {
      totalPoints += 10;
    }

    final percentage = maxPoints > 0 ? ((totalPoints / maxPoints) * 100).clamp(0, 100).round() : 0;

    String label;
    if (percentage >= 80) {
      label = 'Strong Match';
    } else if (percentage >= 50) {
      label = 'Moderate Match';
    } else {
      label = 'Low Match';
    }

    return JobMatchResult(
      matchPercentage: percentage,
      matchingFactors: matchingFactors,
      gapFactors: gapFactors,
      hasSufficientData: true,
      label: label,
    );
  }

  static Set<String> _extractKeywords(List<String?> inputs) {
    final result = <String>{};
    for (final input in inputs) {
      if (input == null || input.trim().isEmpty) continue;
      final parts = input.split(RegExp(r'[,/|\n]'));
      for (final part in parts) {
        final clean = part.trim().toLowerCase();
        if (clean.isNotEmpty) {
          result.add(clean);
        }
      }
    }
    return result;
  }

  static Set<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((s) => s.length > 2)
        .toSet();
  }

  static double? _parseExperienceYears(String expText) {
    final match = RegExp(r'(\d+)(\+)?').firstMatch(expText);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '');
    }
    return null;
  }
}

