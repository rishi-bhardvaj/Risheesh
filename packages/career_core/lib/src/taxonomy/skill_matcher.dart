import 'generic_stoplist.dart';
import 'skills.dart';

enum SkillMatchQuality {
  exact, // Exact canonical name or direct alias
  equivalent, // Alias or direct implication in implied direction
  transferable, // Related edge
  none,
}

class SkillMatchFinding {
  final String canonical;
  final String rawMatch;
  final SkillMatchQuality quality;
  final double weight; // 1.0 for exact, 0.9 for equivalent, related * 0.6 for transferable
  final String? evidence;

  const SkillMatchFinding({
    required this.canonical,
    required this.rawMatch,
    required this.quality,
    required this.weight,
    this.evidence,
  });
}

class SkillMatcher {
  static final Map<String, String> _lookup = {};
  static final Set<String> _ambiguousWords = {'go', 'r', 'c', 'rust', 'swift', 'spring', 'flask', 'express', 'drift', 'spark', 'rest'};
  static bool _initialized = false;

  static void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    for (final skill in SkillTaxonomy.allSkills.values) {
      _lookup[skill.canonical.toLowerCase()] = skill.canonical;
      for (final alias in skill.aliases) {
        _lookup[alias.toLowerCase()] = skill.canonical;
      }
    }
  }

  /// Extracts all technical canonical skills found in [text].
  /// Matches punctuation-sensitive terms (C++, C#, .NET, Node.js, CI/CD) and multi-word n-grams.
  static Set<String> extractCanonicalSkills(String text) {
    _ensureInitialized();
    if (text.isEmpty) return const {};

    final found = <String>{};
    final lower = text.toLowerCase();

    // 1. Explicit multi-word and punctuation token checks
    for (final entry in _lookup.entries) {
      final term = entry.key;
      if (GenericStoplist.isStopword(term)) continue;

      if (_ambiguousWords.contains(term)) {
        if (_matchAmbiguous(lower, text, term)) {
          found.add(entry.value);
        }
        continue;
      }

      if (_containsAsWord(lower, term)) {
        found.add(entry.value);
      }
    }

    return found;
  }

  /// Word-boundary check that respects symbols in terms like C++, C#, .NET, CI/CD.
  static bool _containsAsWord(String corpus, String term) {
    var index = 0;
    while (true) {
      index = corpus.indexOf(term, index);
      if (index == -1) return false;

      final before = index > 0 ? corpus.codeUnitAt(index - 1) : null;
      final afterIndex = index + term.length;
      final after = afterIndex < corpus.length ? corpus.codeUnitAt(afterIndex) : null;

      var validBefore = true;
      if (before != null) {
        // Must not be preceded by letter or digit or # or +
        if (_isAlphaNum(before) || before == 0x23 /* # */ || before == 0x2B /* + */) {
          validBefore = false;
        }
      }

      var validAfter = true;
      if (after != null) {
        // If term is C, after must not be + or #
        if (term == 'c' && (after == 0x2B || after == 0x23)) {
          validAfter = false;
        } else if (_isAlphaNum(after) || after == 0x23 || after == 0x2B) {
          validAfter = false;
        }
      }

      // Edge cases: Go must not match "go-to" or "go live" or "on the go"
      if (term == 'go' && after != null && (after == 0x2D /* - */ || after == 0x5F /* _ */)) {
        validAfter = false;
      }

      if (validBefore && validAfter) {
        return true;
      }

      index += term.length;
    }
  }

  /// Ambiguous words require context or exact capitalization.
  static bool _matchAmbiguous(String lower, String original, String term) {
    if (term == 'r') {
      // "R" must be accompanied by programming / language / stats / r-lang
      final pattern = RegExp(r'\b(r[\s-]?(programming|lang|language|stats|bioconductor))\b|\b(using|in)\s+R\b', caseSensitive: false);
      return pattern.hasMatch(original);
    }
    if (term == 'go') {
      // Must not match "go to", "go-to", "go live", "ongoing"
      final pattern = RegExp(r'\b(golang|go\s+(programming|lang|developer|engineer|backend))\b|\bGo\b');
      if (original.contains(RegExp(r'\b(go-to|go\s+live|ongoing|going)\b', caseSensitive: false))) return false;
      return pattern.hasMatch(original);
    }
    if (term == 'c') {
      // "C" must be distinct from C++ and C#
      final pattern = RegExp(r'\bC\b(?!\+|\#)');
      return pattern.hasMatch(original) && original.contains(RegExp(r'\b(C\s+(programming|language|developer)|embedded\s+C)\b', caseSensitive: false));
    }
    if (term == 'spring') {
      // If "spring boot" matches, that's handled. "spring" must have framework context
      final pattern = RegExp(r'\b(spring\s+(framework|mvc|security|cloud|data))\b|\bSpring\b');
      return pattern.hasMatch(original);
    }
    return _containsAsWord(lower, term);
  }

  static bool _isAlphaNum(int codeUnit) {
    return (codeUnit >= 0x30 && codeUnit <= 0x39) || // 0-9
        (codeUnit >= 0x41 && codeUnit <= 0x5A) || // A-Z
        (codeUnit >= 0x61 && codeUnit <= 0x7A); // a-z
  }

  /// Determines how a candidate's skill matches a required job skill.
  static SkillMatchFinding matchSkill({
    required String jobSkill,
    required Set<String> candidateCanonicalSkills,
  }) {
    _ensureInitialized();
    final jobDef = SkillTaxonomy.lookup(jobSkill);
    final targetCanonical = jobDef?.canonical ?? jobSkill;

    // 1. Exact match
    if (candidateCanonicalSkills.contains(targetCanonical)) {
      return SkillMatchFinding(
        canonical: targetCanonical,
        rawMatch: jobSkill,
        quality: SkillMatchQuality.exact,
        weight: 1.0,
      );
    }

    // 2. Direct implication: if candidate has X and X implies targetCanonical
    for (final cSkill in candidateCanonicalSkills) {
      final cDef = SkillTaxonomy.lookup(cSkill);
      if (cDef != null && cDef.implies.contains(targetCanonical)) {
        return SkillMatchFinding(
          canonical: targetCanonical,
          rawMatch: '$cSkill implies $targetCanonical',
          quality: SkillMatchQuality.equivalent,
          weight: 0.9,
        );
      }
    }

    // 3. Transferable (related edge)
    if (jobDef != null) {
      for (final rel in jobDef.related.entries) {
        if (candidateCanonicalSkills.contains(rel.key)) {
          return SkillMatchFinding(
            canonical: targetCanonical,
            rawMatch: '${rel.key} ~ $targetCanonical',
            quality: SkillMatchQuality.transferable,
            weight: rel.value * 0.6,
          );
        }
      }
    }

    return SkillMatchFinding(
      canonical: targetCanonical,
      rawMatch: jobSkill,
      quality: SkillMatchQuality.none,
      weight: 0.0,
    );
  }
}
