/// Detects sections and splits resume text into logical blocks.
class ResumeSection {
  final String heading;
  final String canonicalSection; // summary, experience, projects, skills, education, certifications, achievements
  final String content;

  const ResumeSection({
    required this.heading,
    required this.canonicalSection,
    required this.content,
  });
}

class SectionDetector {
  SectionDetector._();

  static const Map<String, List<String>> sectionHeadings = {
    'summary': ['summary', 'professional summary', 'profile', 'about', 'about me', 'objective', 'career objective'],
    'experience': ['experience', 'work experience', 'professional experience', 'employment', 'employment history', 'work history', 'career history', 'relevant experience'],
    'projects': ['projects', 'personal projects', 'side projects', 'key projects', 'selected projects', 'open source'],
    'skills': ['skills', 'technical skills', 'core skills', 'key skills', 'tech stack', 'technologies', 'core competencies', 'tools', 'areas of expertise'],
    'education': ['education', 'academic background', 'academics', 'qualifications', 'education & training'],
    'certifications': ['certifications', 'certificates', 'licenses & certifications', 'courses'],
    'achievements': ['achievements', 'awards', 'honors', 'accomplishments', 'awards & achievements'],
  };

  static List<ResumeSection> detectSections(String text) {
    if (text.trim().isEmpty) return const [];

    final lines = text.split('\n');
    final detected = <ResumeSection>[];
    String currentSection = 'summary';
    String currentHeading = 'Summary';
    final currentBuffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final matchedCanonical = _matchHeading(trimmed);
      if (matchedCanonical != null) {
        if (currentBuffer.isNotEmpty) {
          detected.add(ResumeSection(
            heading: currentHeading,
            canonicalSection: currentSection,
            content: currentBuffer.toString().trim(),
          ));
          currentBuffer.clear();
        }
        currentSection = matchedCanonical;
        currentHeading = trimmed;
      } else {
        currentBuffer.writeln(line);
      }
    }

    if (currentBuffer.isNotEmpty) {
      detected.add(ResumeSection(
        heading: currentHeading,
        canonicalSection: currentSection,
        content: currentBuffer.toString().trim(),
      ));
    }

    return detected;
  }

  static String? _matchHeading(String line) {
    if (line.length > 50) return null;
    final lower = line.toLowerCase().replaceAll(RegExp(r'[^a-z\s&]'), '').trim();
    for (final entry in sectionHeadings.entries) {
      for (final heading in entry.value) {
        if (lower == heading || lower == '$heading:') {
          return entry.key;
        }
      }
    }
    return null;
  }
}
