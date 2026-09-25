import '../domain/resume_profile_models.dart';

class ResumeParserService {
  // Common programming languages dictionary for normalized extraction
  static const List<String> _knownLanguages = [
    'Dart', 'TypeScript', 'JavaScript', 'Python', 'Java', 'Kotlin', 'Swift',
    'Go', 'Golang', 'Rust', 'C++', 'C#', 'PHP', 'Ruby', 'Scala', 'SQL',
    'HTML', 'CSS', 'Bash', 'Shell', 'R', 'MATLAB'
  ];

  // Common frameworks & libraries dictionary
  static const List<String> _knownFrameworks = [
    'Flutter', 'React', 'React Native', 'Node.js', 'Express', 'Next.js',
    'Vue.js', 'Angular', 'Spring Boot', 'Django', 'FastAPI', 'Flask',
    'NestJS', 'ASP.NET', 'Laravel', 'Rails', 'Bloc', 'Riverpod', 'Provider',
    'Tailwind CSS', 'Redux', 'GraphQL', 'gRPC'
  ];

  // Tools, Cloud, Databases, and DevOps dictionary
  static const List<String> _knownTools = [
    'Docker', 'Kubernetes', 'AWS', 'GCP', 'Azure', 'Git', 'GitHub', 'GitLab',
    'PostgreSQL', 'MySQL', 'MongoDB', 'Redis', 'SQLite', 'Firebase', 'Supabase',
    'Kafka', 'RabbitMQ', 'Elasticsearch', 'Terraform', 'CI/CD', 'Linux',
    'Nginx', 'Datadog', 'Prometheus', 'Grafana'
  ];

  // Target roles pattern matchers
  static final List<String> _roleKeywords = [
    'Software Engineer', 'Full-Stack Engineer', 'Frontend Engineer',
    'Backend Engineer', 'Mobile Engineer', 'Flutter Developer', 'Flutter Engineer',
    'Android Developer', 'Android Engineer', 'iOS Developer', 'iOS Engineer',
    'DevOps Engineer', 'Cloud Architect', 'Data Engineer', 'Software Developer',
    'Full-Stack Developer', 'Frontend Developer', 'Backend Developer', 'Mobile Developer',
    'Machine Learning Engineer', 'Engineering Manager', 'Tech Lead', 'Staff Engineer',
    'Systems Architect', 'Solutions Architect'
  ];

  ResumeProfile parseResumeText({
    required String resumeText,
    required String resumeId,
    required String resumeName,
  }) {
    final lines = resumeText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // 1. Extract Contact Info
    final email = _extractEmail(resumeText);
    final phone = _extractPhone(resumeText);
    final linkedin = _extractLinkedIn(resumeText);
    final github = _extractGitHub(resumeText);

    // 2. Extract Candidate Target Role & Experience
    final targetRole = _extractTargetRole(lines, resumeText);
    final experienceYears = _extractExperienceYears(resumeText);
    final education = _extractEducation(lines, resumeText);

    // 3. Extract & Categorize Technical Skills
    final languages = _extractFromDictionary(resumeText, _knownLanguages);
    final frameworks = _extractFromDictionary(resumeText, _knownFrameworks);
    final tools = _extractFromDictionary(resumeText, _knownTools);

    // 4. Quality Audit Checks
    final audit = _performQualityAudit(
      hasContactInfo: email != null || phone != null,
      hasLinkedInOrGitHub: linkedin != null || github != null,
      hasEducation: education != null,
      hasTargetRole: targetRole != null,
      totalSkillsCount: languages.length + frameworks.length + tools.length,
      experienceYears: experienceYears?.value,
    );

    return ResumeProfile(
      resumeId: resumeId,
      resumeName: resumeName,
      email: email,
      phone: phone,
      linkedin: linkedin,
      github: github,
      targetRole: targetRole,
      experienceYears: experienceYears,
      education: education,
      programmingLanguages: languages,
      frameworks: frameworks,
      toolsAndCloud: tools,
      rawLines: lines,
      qualityAudit: audit,
    );
  }

  ExtractedField<String>? _extractEmail(String text) {
    final match = RegExp(
      r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    ).firstMatch(text);
    if (match != null) {
      return ExtractedField(
        value: match.group(0)!,
        confidence: ExtractionConfidence.high,
        sourceSnippet: match.group(0),
      );
    }
    return null;
  }

  ExtractedField<String>? _extractPhone(String text) {
    final match = RegExp(
      r'(?:\+?\d{1,3}[-.\s]?)?(?:\(?\d{2,4}\)?[-.\s]?)?\d{3}[-.\s]?\d{4}',
    ).firstMatch(text);
    if (match != null) {
      return ExtractedField(
        value: match.group(0)!.trim(),
        confidence: ExtractionConfidence.medium,
        sourceSnippet: match.group(0),
      );
    }
    return null;
  }

  ExtractedField<String>? _extractLinkedIn(String text) {
    final match = RegExp(
      r'(https?:\/\/)?(www\.)?linkedin\.com\/in\/[a-zA-Z0-9_-]+',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      String url = match.group(0)!;
      if (!url.startsWith('http')) url = 'https://$url';
      return ExtractedField(
        value: url,
        confidence: ExtractionConfidence.high,
      );
    }
    return null;
  }

  ExtractedField<String>? _extractGitHub(String text) {
    final match = RegExp(
      r'(https?:\/\/)?(www\.)?github\.com\/[a-zA-Z0-9_-]+',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      String url = match.group(0)!;
      if (!url.startsWith('http')) url = 'https://$url';
      return ExtractedField(
        value: url,
        confidence: ExtractionConfidence.high,
      );
    }
    return null;
  }

  ExtractedField<String>? _extractTargetRole(List<String> lines, String fullText) {
    // Check top 5 lines first (standard resume header)
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      if (line.contains('@') || line.contains('http') || line.length > 60) continue;
      for (final role in _roleKeywords) {
        if (line.toLowerCase().contains(role.toLowerCase())) {
          return ExtractedField(
            value: line.trim(),
            confidence: ExtractionConfidence.high,
            sourceSnippet: line,
          );
        }
      }
    }
    // Fallback: search anywhere
    for (final role in _roleKeywords) {
      if (fullText.toLowerCase().contains(role.toLowerCase())) {
        return ExtractedField(
          value: role,
          confidence: ExtractionConfidence.medium,
        );
      }
    }
    return null;
  }

  ExtractedField<double>? _extractExperienceYears(String text) {
    final regexes = [
      RegExp(r'(?:experience|exp):\s*(\d+(?:\.\d+)?)\s*(?:\+)?\s*(?:years?|yrs?)?', caseSensitive: false),
      RegExp(r'(\d+(?:\.\d+)?)\s*\+?\s*(?:years?|yrs?)(?:\s+of)?\s+experience', caseSensitive: false),
    ];
    for (final regex in regexes) {
      final match = regex.firstMatch(text);
      if (match != null) {
        final val = double.tryParse(match.group(1) ?? '');
        if (val != null) {
          return ExtractedField(
            value: val,
            confidence: ExtractionConfidence.high,
            sourceSnippet: match.group(0),
          );
        }
      }
    }
    return null;
  }

  ExtractedField<String>? _extractEducation(List<String> lines, String fullText) {
    final eduKeywords = [
      'Bachelor', 'Master', 'Ph.D.', 'B.Tech', 'M.Tech', 'B.S.', 'M.S.',
      'B.E.', 'Computer Science', 'Information Technology'
    ];
    for (final line in lines) {
      for (final kw in eduKeywords) {
        if (line.contains(kw)) {
          return ExtractedField(
            value: line,
            confidence: ExtractionConfidence.medium,
            sourceSnippet: line,
          );
        }
      }
    }
    return null;
  }

  List<ExtractedField<String>> _extractFromDictionary(
    String text,
    List<String> dictionary,
  ) {
    final lowerText = ' ${text.toLowerCase()} ';
    final results = <ExtractedField<String>>[];

    for (final item in dictionary) {
      final escaped = RegExp.escape(item.toLowerCase());
      // Boundary check to prevent false substring positives (e.g. 'R' in 'React')
      final pattern = RegExp('(?<=[^a-zA-Z0-9_#+.]|^)$escaped(?=[^a-zA-Z0-9_#+.]|\$)', caseSensitive: false);
      if (pattern.hasMatch(lowerText)) {
        results.add(
          ExtractedField(
            value: item,
            confidence: ExtractionConfidence.high,
          ),
        );
      }
    }
    return results;
  }

  ResumeQualityAudit _performQualityAudit({
    required bool hasContactInfo,
    required bool hasLinkedInOrGitHub,
    required bool hasEducation,
    required bool hasTargetRole,
    required int totalSkillsCount,
    required double? experienceYears,
  }) {
    int score = 0;
    final passedChecks = <String>[];
    final improvementSuggestions = <String>[];

    if (hasContactInfo) {
      score += 20;
      passedChecks.add('Verified Contact Details (Email & Phone)');
    } else {
      improvementSuggestions.add('Add an email address and direct phone number at the top.');
    }

    if (hasLinkedInOrGitHub) {
      score += 20;
      passedChecks.add('Online Portfolio / Profile Links (GitHub / LinkedIn)');
    } else {
      improvementSuggestions.add('Include your GitHub profile or LinkedIn URL.');
    }

    if (hasTargetRole) {
      score += 20;
      passedChecks.add('Clear Headline / Target Engineering Role');
    } else {
      improvementSuggestions.add('Specify a clear target title (e.g., Senior Full-Stack Engineer).');
    }

    if (hasEducation) {
      score += 20;
      passedChecks.add('Education & Academic Background');
    } else {
      improvementSuggestions.add('Include your degree or university qualifications.');
    }

    if (totalSkillsCount >= 8) {
      score += 20;
      passedChecks.add('Well-structured Technical Skills Portfolio ($totalSkillsCount recognized tech skills)');
    } else if (totalSkillsCount >= 4) {
      score += 10;
      passedChecks.add('Recognized Technical Skills ($totalSkillsCount tech skills)');
      improvementSuggestions.add('Expand your technical stack with specific tools, databases, and libraries.');
    } else {
      improvementSuggestions.add('Add a dedicated SKILLS section with languages, frameworks, and cloud tools.');
    }

    return ResumeQualityAudit(
      score: score.clamp(0, 100),
      hasContactInfo: hasContactInfo,
      hasLinkedInOrGitHub: hasLinkedInOrGitHub,
      hasEducation: hasEducation,
      hasTargetRole: hasTargetRole,
      hasSufficientSkills: totalSkillsCount >= 8,
      passedChecks: passedChecks,
      improvementSuggestions: improvementSuggestions,
    );
  }
}
