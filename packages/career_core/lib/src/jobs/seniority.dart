enum SeniorityLevel {
  intern(0),
  junior(1),
  mid(2),
  senior(3),
  leadOrStaff(4),
  principalOrArchitect(5),
  management(6);

  final int rank;
  const SeniorityLevel(this.rank);
}

class SeniorityParser {
  SeniorityParser._();

  static SeniorityLevel parse(String title) {
    final lower = title.toLowerCase();

    if (RegExp(r'\b(intern|internship|trainee|apprentice)\b').hasMatch(lower)) {
      return SeniorityLevel.intern;
    }
    if (RegExp(r'\b(junior|jr|associate|entry[\s-]level|fresher|grad|graduate|level\s*1|l1|sde[\s-]?1|sde[\s-]?i)\b').hasMatch(lower)) {
      return SeniorityLevel.junior;
    }
    if (RegExp(r'\b(manager|director|vp|vice president|head of|engineering manager|tech manager)\b').hasMatch(lower)) {
      return SeniorityLevel.management;
    }
    if (RegExp(r'\b(principal|architect|distinguished|fellow)\b').hasMatch(lower)) {
      return SeniorityLevel.principalOrArchitect;
    }
    if (RegExp(r'\b(lead|staff|tech lead|team lead|sde[\s-]?4|sde[\s-]?iv)\b').hasMatch(lower)) {
      return SeniorityLevel.leadOrStaff;
    }
    if (RegExp(r'\b(senior|sr|lead|sde[\s-]?3|sde[\s-]?iii|level\s*3|l3)\b').hasMatch(lower)) {
      return SeniorityLevel.senior;
    }

    return SeniorityLevel.mid;
  }
}
