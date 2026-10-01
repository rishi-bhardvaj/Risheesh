/// Deterministic entity extractors for resumes: contacts, links, education, locations.
class EntityExtractors {
  EntityExtractors._();

  static final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
  static final phoneRegex = RegExp(r'(?:\+91[\-\s]?)?[6-9]\d{9}|\+?\d{1,3}[\s.-]?\(?\d{2,4}\)?[\s.-]?\d{3,4}[\s.-]?\d{3,4}');
  static final linkedinRegex = RegExp(r'(?:https?:\/\/)?(?:www\.)?linkedin\.com\/in\/[a-zA-Z0-9_-]+', caseSensitive: false);
  static final githubRegex = RegExp(r'(?:https?:\/\/)?(?:www\.)?github\.com\/[a-zA-Z0-9_-]+', caseSensitive: false);

  static const List<String> indianCities = [
    'Bengaluru', 'Bangalore', 'Hyderabad', 'Pune', 'Mumbai', 'Delhi', 'New Delhi',
    'Noida', 'Gurugram', 'Gurgaon', 'Chennai', 'Kolkata', 'Ahmedabad', 'Kochi',
    'Indore', 'Jaipur', 'Chandigarh', 'Coimbatore', 'Bhubaneswar', 'Thiruvananthapuram',
  ];

  static String? extractEmail(String text) => emailRegex.firstMatch(text)?.group(0);

  static String? extractPhone(String text) => phoneRegex.firstMatch(text)?.group(0);

  static String? extractLinkedIn(String text) => linkedinRegex.firstMatch(text)?.group(0);

  static String? extractGitHub(String text) => githubRegex.firstMatch(text)?.group(0);

  static String? extractLocation(String text) {
    final lower = text.toLowerCase();
    for (final city in indianCities) {
      if (lower.contains(city.toLowerCase())) {
        return city == 'Bangalore' ? 'Bengaluru' : (city == 'Gurgaon' ? 'Gurugram' : city);
      }
    }
    return null;
  }

  static String detectDegreeLevel(String text) {
    final lower = text.toLowerCase();
    if (lower.contains(RegExp(r'\b(ph\.?d|doctorate)\b'))) return 'DOCTORATE';
    if (lower.contains(RegExp(r'\b(m\.?tech|m\.?s|m\.?sc|mca|mba|master)\b'))) return 'MASTER';
    if (lower.contains(RegExp(r'\b(b\.?tech|b\.?e|b\.?sc|bca|bba|bachelor)\b'))) return 'BACHELOR';
    if (lower.contains(RegExp(r'\b(diploma)\b'))) return 'DIPLOMA';
    return 'BACHELOR';
  }
}
