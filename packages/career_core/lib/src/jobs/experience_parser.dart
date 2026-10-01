class JobExperienceRequirement {
  final int minMonths;
  final int? maxMonths;

  const JobExperienceRequirement({required this.minMonths, this.maxMonths});
}

class ExperienceRequirementParser {
  ExperienceRequirementParser._();

  static JobExperienceRequirement parse(String text) {
    final lower = text.toLowerCase();

    // 0. Fresher
    if (RegExp(r'\b(fresher|entry level|0\s*years?)\b').hasMatch(lower)) {
      return const JobExperienceRequirement(minMonths: 0, maxMonths: 12);
    }

    // 1. Range: "3-5 years", "3 to 5 yrs", "2 - 4 years"
    final rangeMatch = RegExp(r'\b(\d+)\s*(?:-|to)\s*(\d+)\s*(?:years?|yrs?)\b').firstMatch(lower);
    if (rangeMatch != null) {
      final min = int.parse(rangeMatch.group(1)!);
      final max = int.parse(rangeMatch.group(2)!);
      return JobExperienceRequirement(minMonths: min * 12, maxMonths: max * 12);
    }

    // 2. Minimum: "3+ years", "minimum 4 years", "at least 5 yrs", "3+ yrs of experience"
    final minMatch = RegExp(r'(?:minimum|at least|\b)\s*(\d+)\+?\s*(?:years?|yrs?)(?:\s+of\s+experience|\s+relevant)?\b').firstMatch(lower);
    if (minMatch != null) {
      final min = int.parse(minMatch.group(1)!);
      // Avoid company age e.g. "founded 25 years ago"
      if (!lower.contains('${min} years ago') && min <= 20) {
        return JobExperienceRequirement(minMonths: min * 12);
      }
    }

    return const JobExperienceRequirement(minMonths: 0);
  }
}
