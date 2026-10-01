import '../taxonomy/skill_matcher.dart';

enum SkillRequirementType {
  required,
  preferred,
  mentioned,
}

class JobSkillRequirement {
  final String canonical;
  final SkillRequirementType requirement;
  final bool fromTitle;

  const JobSkillRequirement({
    required this.canonical,
    required this.requirement,
    this.fromTitle = false,
  });
}

class SectionSplitter {
  SectionSplitter._();

  static const _reqHeadings = [
    'requirements', 'what you\'ll need', 'must have', 'qualifications',
    'what we\'re looking for', 'minimum qualifications', 'what you bring',
    'you should have', 'required skills', 'basic qualifications',
  ];

  static const _prefHeadings = [
    'nice to have', 'preferred', 'bonus', 'plus', 'preferred qualifications',
    'good to have', 'bonus points', 'it\'s a plus', 'would be nice',
  ];

  static List<JobSkillRequirement> extractJobSkills({
    required String title,
    required String description,
    String? explicitSkills,
  }) {
    final results = <String, JobSkillRequirement>{};

    // 1. Skills in title are REQUIRED with fromTitle=true
    final titleSkills = SkillMatcher.extractCanonicalSkills(title);
    for (final s in titleSkills) {
      results[s] = JobSkillRequirement(
        canonical: s,
        requirement: SkillRequirementType.required,
        fromTitle: true,
      );
    }

    // 2. Split description into requirements vs preferred vs other
    final lines = description.split('\n');
    var currentType = SkillRequirementType.mentioned;

    final reqText = StringBuffer();
    final prefText = StringBuffer();
    final otherText = StringBuffer();

    for (final line in lines) {
      final lower = line.toLowerCase().trim();
      if (_matchesHeading(lower, _prefHeadings)) {
        currentType = SkillRequirementType.preferred;
        continue;
      } else if (_matchesHeading(lower, _reqHeadings)) {
        currentType = SkillRequirementType.required;
        continue;
      }

      switch (currentType) {
        case SkillRequirementType.required:
          reqText.writeln(line);
        case SkillRequirementType.preferred:
          prefText.writeln(line);
        case SkillRequirementType.mentioned:
          otherText.writeln(line);
      }
    }

    // Extract from blocks
    final reqSkills = SkillMatcher.extractCanonicalSkills(reqText.toString());
    for (final s in reqSkills) {
      results.putIfAbsent(s, () => JobSkillRequirement(
        canonical: s,
        requirement: SkillRequirementType.required,
      ));
    }

    final prefSkills = SkillMatcher.extractCanonicalSkills(prefText.toString());
    for (final s in prefSkills) {
      results.putIfAbsent(s, () => JobSkillRequirement(
        canonical: s,
        requirement: SkillRequirementType.preferred,
      ));
    }

    final otherSkills = SkillMatcher.extractCanonicalSkills(otherText.toString());
    for (final s in otherSkills) {
      results.putIfAbsent(s, () => JobSkillRequirement(
        canonical: s,
        requirement: SkillRequirementType.mentioned,
      ));
    }

    // 3. Explicit skills if provided
    if (explicitSkills != null && explicitSkills.isNotEmpty) {
      final exp = SkillMatcher.extractCanonicalSkills(explicitSkills);
      for (final s in exp) {
        results.putIfAbsent(s, () => JobSkillRequirement(
          canonical: s,
          requirement: SkillRequirementType.required,
        ));
      }
    }

    return results.values.toList();
  }

  static bool _matchesHeading(String line, List<String> headings) {
    if (line.length > 50) return false;
    final clean = line.replaceAll(RegExp(r'[^a-z\s]'), '').trim();
    return headings.any((h) => clean == h || clean.startsWith('$h:'));
  }
}
