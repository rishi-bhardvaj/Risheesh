/// Stoplist of generic terms that must never count as technical skills
/// or contribute toward role family matches when alone.
class GenericStoplist {
  GenericStoplist._();

  static const Set<String> words = {
    'software',
    'developer',
    'development',
    'engineer',
    'engineering',
    'programming',
    'coding',
    'technology',
    'technical',
    'it',
    'computer',
    'digital',
    'data',
    'ai',
    'analytics',
    'cloud',
    'solutions',
    'systems',
    'platform',
    'tools',
    'agile',
    'communication',
    'problem solving',
    'teamwork',
    'collaboration',
    'leadership',
    'management',
  };

  static bool isStopword(String term) =>
      words.contains(term.trim().toLowerCase());
}
