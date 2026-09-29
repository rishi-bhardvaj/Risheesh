import 'dart:math' as math;

import '../domain/resume_profile_models.dart';
import 'resume_parser_service.dart';

class AtsFactor {
  final String name;
  final int score;
  final int maxScore;
  final List<String> notes;

  const AtsFactor(this.name, this.score, this.maxScore, [this.notes = const []]);

  double get ratio => maxScore == 0 ? 0 : score / maxScore;
}

class AtsReport {
  final int total; // 0-100
  final AtsFactor keywords;
  final AtsFactor sections;
  final AtsFactor impact;
  final AtsFactor formatting;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final List<String> suggestions;
  final bool scoredAgainstJob;

  const AtsReport({
    required this.total,
    required this.keywords,
    required this.sections,
    required this.impact,
    required this.formatting,
    required this.matchedKeywords,
    required this.missingKeywords,
    required this.suggestions,
    required this.scoredAgainstJob,
  });

  List<AtsFactor> get factors => [keywords, sections, impact, formatting];

  String get grade => total >= 85
      ? 'Excellent'
      : total >= 70
          ? 'Strong'
          : total >= 55
              ? 'Fair'
              : 'Needs work';
}

/// Multi-factor ATS score (0-100):
///  * Keywords (40): TF-weighted overlap between the job description's
///    technical and domain terms and the resume. Without a job description,
///    breadth of recognised skills is used instead.
///  * Sections (25): contact, experience, education, skills, projects.
///  * Impact (20): share of experience bullets with numbers/%/$ and strong
///    action verbs.
///  * Formatting (15): length, contact clarity, links, bullet density.
class AtsScoringService {
  static const _actionVerbs = {
    'accelerated', 'achieved', 'added', 'architected', 'automated', 'boosted', 'built', 'championed',
    'collaborated', 'created', 'cut', 'decreased', 'delivered', 'deployed', 'designed', 'developed',
    'drove', 'eliminated', 'enabled', 'engineered', 'established', 'expanded', 'founded', 'generated',
    'grew', 'implemented', 'improved', 'increased', 'integrated', 'introduced', 'launched', 'led',
    'managed', 'mentored', 'migrated', 'modernized', 'optimized', 'orchestrated', 'owned', 'pioneered',
    'rebuilt', 'redesigned', 'reduced', 'refactored', 'resolved', 'restructured', 'saved', 'scaled',
    'shipped', 'simplified', 'spearheaded', 'streamlined', 'strengthened', 'transformed', 'unified', 'upgraded',
    'wrote', 'coordinated', 'maintained', 'analyzed', 'researched', 'trained', 'tested', 'secured',
  };

  static const _weakOpeners = {'responsible', 'worked', 'helped', 'assisted', 'involved', 'participated', 'tasked', 'duties'};

  static final _metric = RegExp(r'\d+(\.\d+)?\s*(%|x\b|k\b|m\b|\+)|[$€£₹]\s?\d|\b\d{2,}\b|\b\d+(\.\d+)?\s*(ms|s|sec|seconds|hours|days|weeks|users|customers|requests|tps|qps)\b', caseSensitive: false);

  static const _stopWords = {
    'the', 'and', 'for', 'with', 'you', 'our', 'are', 'will', 'your', 'have', 'this', 'that', 'from', 'work',
    'team', 'teams', 'about', 'what', 'who', 'able', 'more', 'their', 'they', 'can', 'into', 'across', 'role',
    'join', 'years', 'year', 'experience', 'strong', 'skills', 'including', 'within', 'using', 'build', 'building',
    'help', 'new', 'all', 'also', 'such', 'other', 'well', 'must', 'plus', 'etc', 'job', 'company', 'candidate',
    'responsibilities', 'requirements', 'qualifications', 'preferred', 'benefits', 'salary', 'equal', 'opportunity',
    'employer', 'apply', 'position', 'location', 'remote', 'office', 'based', 'working', 'ability', 'great',
    'people', 'world', 'products', 'product', 'customers', 'we', 'us', 'an', 'or', 'of', 'to', 'in', 'on', 'is',
    'be', 'as', 'at', 'by', 'it', 'if', 'a', 'looking', 'engineer', 'engineering', 'software', 'developer',
    'excellent', 'communication', 'understanding', 'knowledge', 'familiarity', 'proficiency', 'environment',
    'high', 'quality', 'culture', 'health', 'time', 'paid', 'range', 'per', 'hiring', 'process',
  };

  static List<String> get _techDictionary => [
        ...ResumeParserService.knownLanguages,
        ...ResumeParserService.knownFrameworks,
        ...ResumeParserService.knownTools,
        ...ResumeParserService.knownDomainSkills,
      ];

  static bool _containsTerm(String haystackLower, String term) {
    final t = RegExp.escape(term.toLowerCase());
    return RegExp('(?<![a-z0-9_#+.])$t(?![a-z0-9_#+]|\\.[a-z])').hasMatch(haystackLower);
  }

  /// Weighted keywords for a job: dictionary skills (weight 3 + frequency)
  /// plus frequent non-generic terms (bigrams weigh double).
  static Map<String, double> jobKeywords(String jobText) {
    final lower = jobText.toLowerCase();
    final weights = <String, double>{};
    for (final term in _techDictionary) {
      if (term.length <= 2 && term != 'Go') continue; // 'R', 'C' are too noisy in prose
      if (!_containsTerm(lower, term)) continue;
      final count = RegExp('(?<![a-z0-9])${RegExp.escape(term.toLowerCase())}(?![a-z0-9])').allMatches(lower).length;
      weights[term] = 3 + math.min(count, 5).toDouble();
    }
    final tokens = lower.replaceAll(RegExp(r'[^a-z0-9+#./\s-]'), ' ').split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
    final freq = <String, int>{};
    for (var i = 0; i < tokens.length; i++) {
      final w = tokens[i];
      if (_stopWords.contains(w) || RegExp(r'^\d+$').hasMatch(w)) continue;
      freq[w] = (freq[w] ?? 0) + 1;
      if (i + 1 < tokens.length && !_stopWords.contains(tokens[i + 1]) && tokens[i + 1].length > 2) {
        final bigram = '$w ${tokens[i + 1]}';
        freq[bigram] = (freq[bigram] ?? 0) + 1;
      }
    }
    final covered = weights.keys.map((k) => k.toLowerCase()).toSet();
    final extras = freq.entries.where((e) => e.value >= 2 && !covered.contains(e.key)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in extras.take(12)) {
      weights[e.key] = math.min(e.value, 4) * (e.key.contains(' ') ? 1.0 : 0.5);
    }
    return weights;
  }

  static int? requiredYears(String jobText) {
    final m = RegExp(r'(\d{1,2})\s*\+?\s*(?:-\s*\d{1,2}\s*)?(?:years?|yrs?)', caseSensitive: false).firstMatch(jobText);
    final v = int.tryParse(m?.group(1) ?? '');
    return (v != null && v <= 20) ? v : null;
  }

  AtsReport evaluate(ResumeProfile profile, {String? jobDescription, String? jobTitle}) {
    final text = profile.rawText ?? profile.rawLines.join('\n');
    final lower = text.toLowerCase();
    final suggestions = <String>[];
    final hasJob = jobDescription != null && jobDescription.trim().length > 40;

    // 1. Keywords (40)
    final matched = <String>[];
    final missing = <String>[];
    int keywordScore;
    final keywordNotes = <String>[];
    if (hasJob) {
      final weights = jobKeywords('${jobTitle ?? ''}\n$jobDescription');
      var total = 0.0, hit = 0.0;
      final ranked = weights.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      for (final e in ranked) {
        total += e.value;
        if (_containsTerm(lower, e.key)) {
          hit += e.value;
          matched.add(e.key);
        } else {
          missing.add(e.key);
        }
      }
      final coverage = total == 0 ? 0.0 : hit / total;
      keywordScore = (coverage * 40).round();
      keywordNotes.add('${(coverage * 100).round()}% weighted keyword coverage (${matched.length}/${weights.length} terms)');
      final techMissing = missing.where((k) => _techDictionary.contains(k)).take(6).toList();
      if (techMissing.isNotEmpty) {
        suggestions.add('Missing keywords: ${techMissing.join(', ')}. Add the ones you genuinely have to Skills or bullets.');
      }
      final needYears = requiredYears(jobDescription);
      final haveYears = profile.experienceYears?.value;
      if (needYears != null && haveYears != null && haveYears + 0.5 < needYears) {
        keywordScore = math.max(0, keywordScore - 5);
        keywordNotes.add('Job asks for $needYears+ years; resume shows ${haveYears.toStringAsFixed(1)}');
        suggestions.add('The role asks for $needYears+ years. Highlight scope and ownership to offset the gap.');
      }
    } else {
      final skills = profile.allUniqueSkills.length;
      keywordScore = (math.min(skills, 18) / 18 * 40).round();
      matched.addAll(profile.allUniqueSkills);
      keywordNotes.add('$skills recognised skills (score against a job for exact keyword gaps)');
      if (skills < 10) suggestions.add('List more concrete technologies (languages, frameworks, databases, cloud) in a Skills section.');
    }

    // 2. Sections (25)
    final present = profile.sections.toSet();
    final hasContact = profile.email != null && profile.phone != null;
    var sectionScore = 0;
    final sectionNotes = <String>[];
    void section(bool ok, int pts, String label, String advice) {
      if (ok) {
        sectionScore += pts;
      } else {
        sectionNotes.add('Missing: $label');
        suggestions.add(advice);
      }
    }

    section(hasContact, 6, 'contact details', 'Put both an email address and a phone number in the header.');
    section(present.contains('experience') || profile.experience.isNotEmpty, 7, 'Experience section',
        'Add an “Experience” section with role, company, dates and bullet points.');
    section(present.contains('education') || profile.education != null, 4, 'Education section', 'Add an “Education” section with degree, school and year.');
    section(present.contains('skills'), 4, 'Skills section', 'Add a dedicated “Skills” section. ATS parsers look for it by name.');
    section(present.contains('projects'), 2, 'Projects section', 'Add a “Projects” section with 1–3 shipped projects and links.');
    section(present.contains('summary'), 2, 'Summary', 'Open with a 2–3 line summary that names your target role and core stack.');

    // 3. Impact (20)
    final bullets = profile.experience.expand((e) => e.bullets).toList();
    int impactScore;
    final impactNotes = <String>[];
    if (bullets.isEmpty) {
      impactScore = 0;
      impactNotes.add('No experience bullets detected');
      suggestions.add('Describe each role with 3–5 bullets that start with an action verb and include a number.');
    } else {
      final quantified = bullets.where(_metric.hasMatch).length;
      final action = bullets.where((b) => _actionVerbs.contains(_firstWord(b))).length;
      final weak = bullets.where((b) => _weakOpeners.contains(_firstWord(b))).length;
      final qRatio = quantified / bullets.length;
      final aRatio = action / bullets.length;
      impactScore = (math.min(qRatio / 0.6, 1) * 13 + math.min(aRatio / 0.8, 1) * 7).round();
      impactNotes.add('$quantified of ${bullets.length} bullets quantified; $action start with an action verb');
      if (qRatio < 0.5) {
        suggestions.add('Add quantified metrics in your Experience section (%, \$, users, latency). Only ${(qRatio * 100).round()}% of bullets have one.');
      }
      if (weak > 0) {
        suggestions.add('Replace weak openers like “Responsible for” / “Worked on” ($weak bullets) with verbs such as Built, Led, Reduced.');
      }
    }

    // 4. Formatting (15)
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    var formatScore = 0;
    final formatNotes = <String>[];
    if (words >= 300 && words <= 1000) {
      formatScore += 5;
    } else if (words >= 180 && words <= 1300) {
      formatScore += 3;
      formatNotes.add('$words words');
      suggestions.add(words < 300
          ? 'Your resume is short ($words words). Aim for 400–800 words with more detail on impact.'
          : 'Your resume is long ($words words). Trim to 1–2 pages; ATS and recruiters skim.');
    } else {
      formatNotes.add('$words words');
      suggestions.add(words < 180 ? 'Very little text was found. If this is a scanned PDF, upload a text-based export.' : 'Cut the resume to at most 2 pages.');
    }
    final head = profile.rawLines.take(6).join(' ');
    if (profile.email != null && head.contains(profile.email!.value)) {
      formatScore += 4;
    } else if (profile.email != null) {
      formatScore += 2;
      formatNotes.add('Contact info is not at the top');
      suggestions.add('Move your contact details to the first lines. Some ATS only read the header.');
    }
    if (profile.linkedin != null || profile.github != null) {
      formatScore += 3;
    } else {
      suggestions.add('Include your LinkedIn and/or GitHub URL.');
    }
    final longBullets = bullets.where((b) => b.split(' ').length > 40).length;
    if (bullets.length >= 3 && longBullets == 0) {
      formatScore += 3;
    } else if (longBullets > 0) {
      formatNotes.add('$longBullets overly long bullets');
      suggestions.add('Split long bullets (over 40 words) into concise one or two line statements.');
    }

    final total = (keywordScore + sectionScore + impactScore + formatScore).clamp(0, 100);
    return AtsReport(
      total: total,
      keywords: AtsFactor('Keyword match', keywordScore, 40, keywordNotes),
      sections: AtsFactor('Section completeness', sectionScore, 25, sectionNotes),
      impact: AtsFactor('Quantified impact', impactScore, 20, impactNotes),
      formatting: AtsFactor('Formatting', formatScore, 15, formatNotes),
      matchedKeywords: matched,
      missingKeywords: missing,
      suggestions: suggestions,
      scoredAgainstJob: hasJob,
    );
  }

  static String _firstWord(String bullet) =>
      bullet.trim().split(RegExp(r'\s+')).first.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
}
