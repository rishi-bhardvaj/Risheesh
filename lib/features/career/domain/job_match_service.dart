import 'dart:math' as math;

import '../../../core/database/app_database.dart';
import '../services/resume_parser_service.dart';

class JobMatchResult {
  final int matchPercentage;
  final List<String> matchingFactors;
  final List<String> gapFactors;
  final bool hasSufficientData;
  final String label;

  static const String disclaimer = 'Profile-to-job match based on your saved preferences and job data.';

  const JobMatchResult({
    required this.matchPercentage,
    required this.matchingFactors,
    required this.gapFactors,
    required this.hasSufficientData,
    required this.label,
  });

  factory JobMatchResult.insufficient() => const JobMatchResult(
        matchPercentage: 0,
        matchingFactors: [],
        gapFactors: [],
        hasSufficientData: false,
        label: 'Add skills to your profile',
      );

  factory JobMatchResult.fromStoredScore(int score, {String? reason}) => JobMatchResult(
        matchPercentage: score,
        matchingFactors: reason != null && reason.isNotEmpty ? [reason] : const ['Matched profile skills & experience'],
        gapFactors: const [],
        hasSufficientData: true,
        label: score >= 75 ? 'Strong match' : (score >= 50 ? 'Good match' : 'Possible match'),
      );
}

/// Profile-to-job match (0-100):
///  * Skills 45: overlap of known tech terms in the job vs. the profile.
///  * Role 30: specialization words ("backend", "flutter", "data") in the title.
///  * Location 15: remote preference / preferred cities.
///  * Experience 10: required years and seniority words.
class JobMatchService {
  static final List<String> _dictionary = [
    ...ResumeParserService.knownLanguages,
    ...ResumeParserService.knownFrameworks,
    ...ResumeParserService.knownTools,
    ...ResumeParserService.knownDomainSkills,
  ].where((t) => t.length > 1).map((t) => t.toLowerCase()).toSet().toList();

  static const _genericRoleWords = {
    'engineer', 'engineering', 'developer', 'development', 'senior', 'junior', 'software', 'lead', 'staff',
    'principal', 'sr', 'jr', 'ii', 'iii', 'iv', 'manager', 'intern', 'associate', 'head', 'the', 'and', 'for',
  };

  static final Map<String, RegExp> _termPatterns = {
    for (final t in _dictionary) t: RegExp('(?<![a-z0-9_#+.])${RegExp.escape(t)}(?![a-z0-9_#+]|\\.[a-z])'),
  };

  static Set<String> _termsIn(String text) {
    final lower = text.toLowerCase();
    return {for (final e in _termPatterns.entries) if (e.value.hasMatch(lower)) e.key};
  }

  static Set<String> _list(Iterable<String?> inputs) => {
        for (final input in inputs)
          if (input != null)
            for (final part in input.split(RegExp(r'[,/|\n;]')))
              if (part.trim().isNotEmpty && part.trim().length <= 30) part.trim().toLowerCase(),
      };

  static Set<String> _tokens(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9+#]'), ' ').split(RegExp(r'\s+')).where((s) => s.length > 1).toSet();

  static JobMatchResult calculateMatch({required Job job, required UserProfile? profile}) {
    if (profile == null) return JobMatchResult.insufficient();

    final userSkillText = [profile.skills, profile.programmingLanguages, profile.frameworks].whereType<String>().join(', ');
    final userTerms = {..._list([userSkillText]), ..._termsIn(userSkillText)};
    final roleText = [profile.preferredRoles, profile.currentRole].whereType<String>().join(', ');
    if (userTerms.isEmpty && roleText.trim().isEmpty) return JobMatchResult.insufficient();

    final matching = <String>[];
    final gaps = <String>[];
    var total = 0.0;

    // 1. Skills (45)
    final jobText = '${job.title}\n${job.skills ?? ''}\n${job.description ?? ''}';
    final jobTerms = {..._termsIn(jobText), ..._list([job.skills]).where(_dictionary.contains)};
    if (jobTerms.isNotEmpty && userTerms.isNotEmpty) {
      final matched = jobTerms.where(userTerms.contains).toList();
      final missing = jobTerms.where((t) => !userTerms.contains(t)).toList();
      total += math.min(1.0, matched.length / math.min(jobTerms.length, 6)) * 45;
      if (matched.isNotEmpty) matching.add('Skills matched: ${matched.take(5).join(', ')}');
      if (missing.isNotEmpty) gaps.add('Missing skills: ${missing.take(4).join(', ')}');
    } else if (userTerms.isNotEmpty) {
      final found = userTerms.where((s) => jobText.toLowerCase().contains(s)).take(3).toList();
      total += found.isEmpty ? 8 : 22;
      if (found.isNotEmpty) matching.add('Mentions ${found.join(', ')}');
    }

    // 2. Role (30)
    final titleTokens = _tokens(job.title);
    final specialization = _tokens(roleText).difference(_genericRoleWords);
    final specHit = specialization.intersection(titleTokens);
    if (specHit.isNotEmpty) {
      total += 30;
      matching.add('Role match: ${job.title}');
    } else if (roleText.isNotEmpty && RegExp(r'engineer|developer|programmer|architect', caseSensitive: false).hasMatch(job.title)) {
      total += 12;
      gaps.add('Different specialization than ${roleText.split(',').first.trim()}');
    } else if (roleText.isNotEmpty) {
      gaps.add('Role differs from your target');
    }

    // 3. Location (15)
    final jobLoc = '${job.location ?? ''} ${job.employmentType ?? ''}'.toLowerCase();
    final isRemote = jobLoc.contains('remote') || jobLoc.contains('anywhere');
    final pref = profile.remotePreference.toLowerCase();
    final cities = _list([profile.preferredLocations]).where((c) => c != 'remote');
    if (isRemote && pref != 'onsite') {
      total += 15;
      matching.add('Remote');
    } else if (cities.any(jobLoc.contains)) {
      total += 15;
      matching.add('Location match: ${job.location}');
    } else if (pref == 'any' || (cities.isEmpty && pref != 'remote')) {
      total += 10;
    } else {
      gaps.add(pref == 'remote' ? 'Not remote' : 'Outside your preferred locations');
    }

    // 4. Experience (10)
    final reqMatch = RegExp(r'(\d{1,2})\s*\+?\s*(?:-\s*\d{1,2}\s*)?(?:years?|yrs?)', caseSensitive: false)
        .firstMatch('${job.experienceRequirement ?? ''} ${job.description ?? ''}');
    final required = int.tryParse(reqMatch?.group(1) ?? '');
    final years = profile.experienceYears;
    if (required == null || required > 20) {
      total += 8;
    } else if (years >= required) {
      total += 10;
      matching.add('Meets $required+ yrs');
    } else if (years >= required - 1) {
      total += 5;
      gaps.add('Asks $required+ yrs (you: ${years.toStringAsFixed(1)})');
    } else {
      gaps.add('Asks $required+ yrs (you: ${years.toStringAsFixed(1)})');
    }
    final title = job.title.toLowerCase();
    if (RegExp(r'\b(senior|sr\.?|staff|principal|lead)\b').hasMatch(title) && years < 3) total -= 10;
    if (RegExp(r'\b(intern|junior|jr\.?|graduate|entry)\b').hasMatch(title) && years >= 5) total -= 10;

    final pct = total.clamp(0, 100).round();
    return JobMatchResult(
      matchPercentage: pct,
      matchingFactors: matching,
      gapFactors: gaps,
      hasSufficientData: true,
      label: pct >= 75
          ? 'Strong match'
          : pct >= 50
              ? 'Good match'
              : 'Low match',
    );
  }
}
