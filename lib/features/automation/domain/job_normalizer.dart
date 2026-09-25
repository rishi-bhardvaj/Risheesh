import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import 'automation_models.dart';

class JobNormalizer {
  static final _uuid = const Uuid();

  static JobsCompanion normalize(RawJobItem raw) {
    final cleanTitle = _sanitizeString(raw.title) ?? 'Untitled Position';
    final cleanCompany = _sanitizeString(raw.company) ?? 'Unknown Company';
    final cleanLocation = _sanitizeString(raw.location) ?? (raw.isRemote ? 'Remote' : null);
    final cleanSkills = _sanitizeString(raw.skills);
    final cleanUrl = _sanitizeString(raw.url);
    final cleanDescription = _sanitizeDescription(raw.description);
    final cleanSalary = _sanitizeString(raw.salary);
    final now = DateTime.now();

    return JobsCompanion(
      id: Value(_uuid.v4()),
      title: Value(cleanTitle),
      company: Value(cleanCompany),
      location: Value(cleanLocation),
      skills: Value(cleanSkills),
      url: Value(cleanUrl),
      description: Value(cleanDescription),
      salary: Value(cleanSalary),
      employmentType: Value(raw.isRemote ? 'Remote' : 'Full-time'),
      discoveredAt: Value(raw.publishedAt ?? now),
      isSaved: const Value(false),
      source: Value(raw.company.isNotEmpty ? raw.company : 'Automated Search'),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }

  static String? _sanitizeString(String? input) {
    if (input == null) return null;
    final trimmed = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _sanitizeDescription(String? rawHtml) {
    if (rawHtml == null) return null;
    // Strip HTML tags safely
    final unhtmled = rawHtml.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
    final clean = unhtmled.replaceAll(RegExp(r'\s+'), ' ');
    return clean.isEmpty ? null : clean;
  }
}
