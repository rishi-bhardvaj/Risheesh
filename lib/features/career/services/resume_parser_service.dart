import '../domain/resume_profile_models.dart';

/// Heuristic resume parser: contact details, name, sections, work history,
/// education and a categorized skills inventory from plain resume text
/// (as produced by `ResumeTextExtractor`).
class ResumeParserService {
  static const List<String> knownLanguages = [
    'Dart', 'TypeScript', 'JavaScript', 'Python', 'Java', 'Kotlin', 'Swift',
    'Go', 'Golang', 'Rust', 'C++', 'C#', 'C', 'PHP', 'Ruby', 'Scala', 'SQL',
    'HTML', 'CSS', 'Bash', 'Shell', 'R', 'MATLAB', 'Objective-C', 'Elixir', 'Haskell', 'Solidity',
  ];

  static const List<String> knownFrameworks = [
    'Flutter', 'React', 'React Native', 'Node.js', 'Express', 'Next.js', 'Nuxt',
    'Vue.js', 'Angular', 'Svelte', 'Spring Boot', 'Spring', 'Django', 'FastAPI', 'Flask',
    'NestJS', 'ASP.NET', '.NET', 'Laravel', 'Rails', 'Bloc', 'Riverpod', 'Provider',
    'Jetpack Compose', 'SwiftUI', 'Tailwind CSS', 'Redux', 'GraphQL', 'gRPC',
    'TensorFlow', 'PyTorch', 'Pandas', 'NumPy', 'LangChain', 'Spark', 'Hadoop',
  ];

  static const List<String> knownTools = [
    'Docker', 'Kubernetes', 'AWS', 'GCP', 'Google Cloud', 'Azure', 'Git', 'GitHub', 'GitLab',
    'GitHub Actions', 'Jenkins', 'CircleCI', 'PostgreSQL', 'MySQL', 'MongoDB', 'Redis', 'SQLite',
    'Drift', 'Firebase', 'Supabase', 'DynamoDB', 'Cassandra', 'Kafka', 'RabbitMQ', 'Elasticsearch',
    'Terraform', 'Ansible', 'CI/CD', 'Linux', 'Nginx', 'Datadog', 'Prometheus', 'Grafana',
    'Jira', 'Figma', 'Postman', 'Vercel', 'Heroku', 'Snowflake', 'BigQuery', 'Airflow',
  ];

  static const List<String> knownDomainSkills = [
    'Microservices', 'REST', 'REST APIs', 'System Design', 'Distributed Systems', 'Machine Learning',
    'Deep Learning', 'NLP', 'LLM', 'Data Structures', 'Algorithms', 'Agile', 'Scrum', 'TDD',
    'Unit Testing', 'Offline-first', 'Performance Optimization', 'Security', 'OAuth', 'WebSockets',
    'Clean Architecture', 'MVVM', 'Design Systems', 'Accessibility', 'Observability',
  ];

  /// Short dictionary words that are also ordinary English words; these only
  /// count when written with their canonical capitalization.
  static const _caseSensitive = {'Go', 'R', 'C', 'Swift', 'Rust', 'Shell', 'Spring', 'Express', 'Flask', 'Provider', 'Bloc', 'Rails', 'Drift', 'Spark', 'REST', 'Security', 'Agile'};

  static final List<String> _roleKeywords = [
    'Software Engineer', 'Full-Stack Engineer', 'Full Stack Engineer', 'Frontend Engineer',
    'Backend Engineer', 'Mobile Engineer', 'Flutter Developer', 'Flutter Engineer',
    'Android Developer', 'Android Engineer', 'iOS Developer', 'iOS Engineer',
    'DevOps Engineer', 'Site Reliability Engineer', 'Cloud Architect', 'Data Engineer', 'Data Scientist',
    'Software Developer', 'Full-Stack Developer', 'Full Stack Developer', 'Frontend Developer',
    'Backend Developer', 'Mobile Developer', 'Web Developer', 'Machine Learning Engineer', 'ML Engineer',
    'Engineering Manager', 'Tech Lead', 'Staff Engineer', 'Principal Engineer', 'QA Engineer',
    'Systems Architect', 'Solutions Architect', 'Product Engineer', 'Platform Engineer',
  ];

  /// Canonical section -> headings that introduce it.
  static const Map<String, List<String>> sectionHeadings = {
    'summary': ['summary', 'professional summary', 'profile', 'about', 'about me', 'objective', 'career objective'],
    'experience': ['experience', 'work experience', 'professional experience', 'employment', 'employment history', 'work history', 'career history', 'relevant experience'],
    'projects': ['projects', 'personal projects', 'side projects', 'key projects', 'selected projects', 'open source'],
    'skills': ['skills', 'technical skills', 'core skills', 'key skills', 'tech stack', 'technologies', 'core competencies', 'tools'],
    'education': ['education', 'academic background', 'academics', 'qualifications', 'education & training'],
    'certifications': ['certifications', 'certificates', 'licenses & certifications', 'courses'],
    'achievements': ['achievements', 'awards', 'honors', 'accomplishments', 'awards & achievements'],
  };

  static const _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, 'jul': 7, 'aug': 8,
    'sep': 9, 'sept': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };
  static const _monthPattern = r'(?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?';
  static final dateRangePattern = RegExp(
    '((?:$_monthPattern\\s+)?(?:\\d{1,2}/)?(?:19|20)\\d{2})\\s*(?:-|–|—|to|until)\\s*((?:$_monthPattern\\s+)?(?:\\d{1,2}/)?(?:19|20)\\d{2}|present|current|now|today|date)',
    caseSensitive: false,
  );
  static final _bulletPrefix = RegExp(r'^[•\-\*▪◦●‣·–]\s*');

  ResumeProfile parseResumeText({
    required String resumeText,
    required String resumeId,
    required String resumeName,
  }) {
    final lines = resumeText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final sections = splitSections(lines);

    final email = _extractEmail(resumeText);
    final phone = _extractPhone(resumeText);
    final linkedin = _extractLinkedIn(resumeText);
    final github = _extractGitHub(resumeText);
    final fullName = _extractName(lines);

    final experience = parseExperience(sections['experience'] ?? const []);
    final targetRole = _extractTargetRole(lines, resumeText, experience);
    final experienceYears = _extractExperienceYears(resumeText) ?? _yearsFromHistory(experience);
    final educationEntries = _educationEntries(sections['education'] ?? const [], lines);
    final education = educationEntries.isEmpty
        ? null
        : ExtractedField(value: educationEntries.first, confidence: ExtractionConfidence.medium, sourceSnippet: educationEntries.first);

    final languages = _extractFromDictionary(resumeText, knownLanguages);
    final frameworks = _extractFromDictionary(resumeText, knownFrameworks);
    final tools = _extractFromDictionary(resumeText, knownTools);
    final domain = _extractFromDictionary(resumeText, knownDomainSkills);

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
      fullName: fullName,
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
      domainSkills: domain,
      rawLines: lines,
      qualityAudit: audit,
      experience: experience,
      educationEntries: educationEntries,
      sections: sections.keys.where((k) => k != 'header').toList(),
      rawText: resumeText,
    );
  }

  // ---------------------------------------------------------------- sections

  static String? headingFor(String line) {
    if (line.length > 40) return null;
    final clean = line.toLowerCase().replaceAll(RegExp(r'[:：\-–—_|#*]+$'), '').replaceAll(RegExp(r'^[#*\s]+'), '').trim();
    for (final entry in sectionHeadings.entries) {
      if (entry.value.contains(clean)) return entry.key;
    }
    return null;
  }

  /// Splits lines into canonical sections. Lines before the first heading
  /// go under "header".
  static Map<String, List<String>> splitSections(List<String> lines) {
    final out = <String, List<String>>{'header': []};
    var current = 'header';
    for (final line in lines) {
      final h = headingFor(line);
      if (h != null) {
        current = h;
        out.putIfAbsent(current, () => []);
        continue;
      }
      out[current]!.add(line);
    }
    return out;
  }

  // -------------------------------------------------------------- experience

  static DateTime? _parseDatePart(String raw, {required bool isEnd}) {
    final s = raw.trim().toLowerCase();
    if (RegExp(r'present|current|now|today|date').hasMatch(s)) return null;
    final year = int.tryParse(RegExp(r'(19|20)\d{2}').firstMatch(s)?.group(0) ?? '');
    if (year == null) return null;
    final monthWord = RegExp(r'[a-z]{3,}').firstMatch(s)?.group(0);
    var month = monthWord == null ? null : _months[monthWord.substring(0, monthWord.startsWith('sept') ? 4 : 3)];
    month ??= int.tryParse(RegExp(r'(\d{1,2})/').firstMatch(s)?.group(1) ?? '');
    return DateTime(year, month ?? (isEnd ? 12 : 1));
  }

  static bool _isBullet(String line) => _bulletPrefix.hasMatch(line);

  static bool _isDateOnly(String line) {
    final m = dateRangePattern.firstMatch(line);
    if (m == null) return false;
    final rest = line.replaceFirst(m.group(0)!, '').replaceAll(RegExp(r'[\s|,()·•\-–—]+'), '');
    return rest.length <= 12; // allow a short location such as "Remote"
  }

  static bool _looksLikeHeader(String line, String? next) {
    if (_isBullet(line) || line.length > 110 || line.endsWith('.')) return false;
    if (dateRangePattern.hasMatch(line)) return true;
    if (next != null && _isDateOnly(next)) return true;
    return false;
  }

  /// Groups the Experience section into roles. A role starts at a line that
  /// carries a date range or is followed by a date-only line; everything
  /// until the next such line is treated as its bullets (PDF exports often
  /// drop the bullet glyphs, so un-prefixed lines count too).
  static List<WorkExperience> parseExperience(List<String> lines) {
    final roles = <WorkExperience>[];
    String? header;
    String? dates;
    final bullets = <String>[];

    void flush() {
      if (header == null) return;
      roles.add(_buildRole(header!, dates, List.of(bullets)));
      header = null;
      dates = null;
      bullets.clear();
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final next = i + 1 < lines.length ? lines[i + 1] : null;
      if (_looksLikeHeader(line, next) && !(header != null && dates == null && _isDateOnly(line))) {
        flush();
        header = line;
        final m = dateRangePattern.firstMatch(line);
        if (m != null) dates = m.group(0);
        continue;
      }
      if (header != null && dates == null && _isDateOnly(line)) {
        dates = dateRangePattern.firstMatch(line)!.group(0);
        continue;
      }
      if (header == null) continue;
      final text = line.replaceFirst(_bulletPrefix, '').trim();
      if (text.isEmpty) continue;
      // Wrapped continuation of the previous bullet (starts lowercase).
      if (bullets.isNotEmpty && !_isBullet(line) && RegExp(r'^[a-z(]').hasMatch(text)) {
        bullets[bullets.length - 1] = '${bullets.last} $text';
      } else {
        bullets.add(text);
      }
    }
    flush();
    return roles;
  }

  static WorkExperience _buildRole(String header, String? dates, List<String> bullets) {
    var h = header;
    if (dates != null) h = h.replaceFirst(dates, '');
    h = h.replaceAll(RegExp(r'\(\s*\)|\s+[|,·•–—-]\s*$'), '').trim();

    String? location;
    // "Role, Company — City" / "Role | Company | City"
    final locSplit = RegExp(r'\s+[—–]\s+').allMatches(h).toList();
    if (locSplit.isNotEmpty) {
      location = h.substring(locSplit.last.end).trim();
      h = h.substring(0, locSplit.last.start).trim();
    }
    String role = h;
    String? company;
    for (final sep in [' | ', ' @ ', ' at ', ', ', ' - ']) {
      final idx = h.indexOf(sep);
      if (idx > 0) {
        role = h.substring(0, idx).trim();
        company = h.substring(idx + sep.length).split(RegExp(r'\s+\|\s+')).first.trim();
        break;
      }
    }
    // If the "role" has no role-ish word but the company does, they're swapped.
    final roleWords = RegExp(r'engineer|developer|manager|lead|intern|architect|analyst|scientist|designer|consultant|founder|head|director|sde', caseSensitive: false);
    if (company != null && !roleWords.hasMatch(role) && roleWords.hasMatch(company)) {
      final t = role;
      role = company;
      company = t;
    }

    DateTime? start;
    DateTime? end;
    var current = false;
    if (dates != null) {
      final m = dateRangePattern.firstMatch(dates)!;
      start = _parseDatePart(m.group(1)!, isEnd: false);
      end = _parseDatePart(m.group(2)!, isEnd: true);
      current = end == null;
    }
    return WorkExperience(
      role: role.replaceAll(RegExp(r'[()]'), '').trim(),
      company: company?.replaceAll(RegExp(r'[()]'), '').trim(),
      location: location,
      dateRange: dates,
      start: start,
      end: end,
      isCurrent: current,
      bullets: bullets,
    );
  }

  /// Total experience from merged role intervals, rounded to half a year.
  static ExtractedField<double>? _yearsFromHistory(List<WorkExperience> roles, {DateTime? now}) {
    final intervals = <(DateTime, DateTime)>[
      for (final r in roles)
        if (r.start != null) (r.start!, r.end ?? (r.isCurrent ? (now ?? DateTime.now()) : r.start!)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    if (intervals.isEmpty) return null;
    var months = 0;
    var (curStart, curEnd) = intervals.first;
    for (final (s, e) in intervals.skip(1)) {
      if (s.isAfter(curEnd)) {
        months += _monthsBetween(curStart, curEnd);
        (curStart, curEnd) = (s, e);
      } else if (e.isAfter(curEnd)) {
        curEnd = e;
      }
    }
    months += _monthsBetween(curStart, curEnd);
    if (months <= 0) return null;
    final years = (months / 12 * 2).round() / 2;
    return ExtractedField(value: years, confidence: ExtractionConfidence.medium, sourceSnippet: '$months months across ${roles.length} roles');
  }

  static int _monthsBetween(DateTime a, DateTime b) => (b.year - a.year) * 12 + b.month - a.month + 1;

  // ----------------------------------------------------------------- contact

  ExtractedField<String>? _extractEmail(String text) {
    final match = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').firstMatch(text);
    if (match == null) return null;
    return ExtractedField(value: match.group(0)!, confidence: ExtractionConfidence.high, sourceSnippet: match.group(0));
  }

  ExtractedField<String>? _extractPhone(String text) {
    // Needs 7-15 digits and must not be a year range like "2019 - 2023".
    final pattern = RegExp(r'(?:\+\d{1,3}[\s.-]?)?(?:\(\d{2,4}\)[\s.-]?)?\d[\d\s.-]{5,16}\d');
    for (final m in pattern.allMatches(text)) {
      final raw = m.group(0)!.trim();
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 7 || digits.length > 15) continue;
      if (dateRangePattern.hasMatch(raw) || RegExp(r'^(19|20)\d{2}\s*[-–]\s*(19|20)\d{2}$').hasMatch(raw)) continue;
      return ExtractedField(value: raw, confidence: raw.startsWith('+') ? ExtractionConfidence.high : ExtractionConfidence.medium, sourceSnippet: raw);
    }
    return null;
  }

  ExtractedField<String>? _extractLinkedIn(String text) {
    final match = RegExp(r'(https?://)?(www\.)?linkedin\.com/in/[a-zA-Z0-9_-]+', caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    var url = match.group(0)!;
    if (!url.startsWith('http')) url = 'https://$url';
    return ExtractedField(value: url, confidence: ExtractionConfidence.high);
  }

  ExtractedField<String>? _extractGitHub(String text) {
    final match = RegExp(r'(https?://)?(www\.)?github\.com/[a-zA-Z0-9_-]+', caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    var url = match.group(0)!;
    if (!url.startsWith('http')) url = 'https://$url';
    return ExtractedField(value: url, confidence: ExtractionConfidence.high);
  }

  /// First short line of 2-4 capitalised words that isn't a heading, role,
  /// or contact line (ApplyOS heuristic, tightened).
  ExtractedField<String>? _extractName(List<String> lines) {
    for (final line in lines.take(6)) {
      final t = line.replaceFirst(RegExp(r'^(name|resume|curriculum vitae|cv)\s*[:\-]?\s*', caseSensitive: false), '').trim();
      if (t.isEmpty || t.length > 40 || headingFor(t) != null) continue;
      if (RegExp(r'[@\d/|:]|http|\.com', caseSensitive: false).hasMatch(t)) continue;
      if (_roleKeywords.any((r) => t.toLowerCase().contains(r.toLowerCase()))) continue;
      final words = t.split(RegExp(r'\s+'));
      if (words.length < 2 || words.length > 4) continue;
      if (!words.every((w) => RegExp(r"^[A-Z][A-Za-z.'’\-]*$").hasMatch(w) || RegExp(r"^[A-Z]+$").hasMatch(w))) continue;
      final name = words.every((w) => w == w.toUpperCase())
          ? words.map((w) => w[0] + w.substring(1).toLowerCase()).join(' ')
          : t;
      return ExtractedField(value: name, confidence: ExtractionConfidence.high, sourceSnippet: line);
    }
    return null;
  }

  ExtractedField<String>? _extractTargetRole(List<String> lines, String fullText, List<WorkExperience> roles) {
    for (final line in lines.take(5)) {
      if (line.contains('@') || line.contains('http') || line.length > 60) continue;
      for (final role in _roleKeywords) {
        if (line.toLowerCase().contains(role.toLowerCase())) {
          return ExtractedField(value: line.trim(), confidence: ExtractionConfidence.high, sourceSnippet: line);
        }
      }
    }
    if (roles.isNotEmpty && roles.first.role.isNotEmpty && roles.first.role.length <= 60) {
      return ExtractedField(value: roles.first.role, confidence: ExtractionConfidence.medium, sourceSnippet: roles.first.role);
    }
    for (final role in _roleKeywords) {
      if (fullText.toLowerCase().contains(role.toLowerCase())) {
        return ExtractedField(value: role, confidence: ExtractionConfidence.medium);
      }
    }
    return null;
  }

  ExtractedField<double>? _extractExperienceYears(String text) {
    final regexes = [
      RegExp(r'(?:experience|exp):\s*(\d+(?:\.\d+)?)\s*(?:\+)?\s*(?:years?|yrs?)?', caseSensitive: false),
      RegExp(r'(\d+(?:\.\d+)?)\s*\+?\s*(?:years?|yrs?)(?:\s+of)?(?:\s+\w+)?\s+experience', caseSensitive: false),
    ];
    for (final regex in regexes) {
      final match = regex.firstMatch(text);
      final val = double.tryParse(match?.group(1) ?? '');
      if (val != null && val < 50) {
        return ExtractedField(value: val, confidence: ExtractionConfidence.high, sourceSnippet: match!.group(0));
      }
    }
    return null;
  }

  static const _degreePattern =
      r"bachelor|master|ph\.?d|doctorate|b\.?\s?tech|m\.?\s?tech|b\.?\s?e\.?\b|m\.?\s?e\.?\b|b\.?\s?s\.?c?\b|m\.?\s?s\.?c?\b|b\.?\s?a\.?\b|m\.?\s?b\.?\s?a|bca|mca|diploma|associate|high school|computer science|information technology";

  List<String> _educationEntries(List<String> section, List<String> all) {
    final degree = RegExp(_degreePattern, caseSensitive: false);
    final source = section.isNotEmpty ? section : all;
    final out = <String>[];
    for (var i = 0; i < source.length; i++) {
      final line = source[i].replaceFirst(_bulletPrefix, '');
      if (!degree.hasMatch(line) || line.length > 160) continue;
      // Join "Degree" + "University (years)" when split over two lines.
      final next = i + 1 < source.length ? source[i + 1] : null;
      if (next != null && !degree.hasMatch(next) && RegExp(r'universit|college|institute|school|iit|nit', caseSensitive: false).hasMatch(next)) {
        out.add('$line, $next');
        i++;
      } else {
        out.add(line);
      }
    }
    return out;
  }

  // ------------------------------------------------------------------ skills

  List<ExtractedField<String>> _extractFromDictionary(String text, List<String> dictionary) {
    final results = <ExtractedField<String>>[];
    final seen = <String>{};
    for (final item in dictionary) {
      final exact = _caseSensitive.contains(item);
      final pattern = RegExp('(?<![A-Za-z0-9_#+.&])${RegExp.escape(item)}(?![A-Za-z0-9_#+&]|\\.[A-Za-z])', caseSensitive: exact);
      if (pattern.hasMatch(text)) {
        // "Golang" and "Go" are one skill.
        final canonical = item == 'Golang' ? 'Go' : item;
        if (seen.add(canonical.toLowerCase())) {
          results.add(ExtractedField(value: canonical, confidence: ExtractionConfidence.high));
        }
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
