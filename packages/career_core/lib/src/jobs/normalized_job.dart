import '../util/text_normalize.dart';
import 'canonical_url.dart';
import 'experience_parser.dart';
import 'fingerprint.dart';
import 'html_sanitizer.dart';
import 'location_parser.dart';
import 'role_classifier.dart';
import 'salary_parser.dart';
import 'section_splitter.dart';
import 'seniority.dart';

class NormalizedJob {
  final String id;
  final String canonicalUrl;
  final String fingerprint;
  final String company;
  final String companyNorm;
  final String title;
  final String titleNorm;
  final String roleFamily;
  final SeniorityLevel seniority;
  final String location;
  final String city;
  final String country;
  final WorkMode workMode;
  final String employmentType;
  final int expMinMonths;
  final int? expMaxMonths;
  final String? eduRequirement;
  final double? salaryMin;
  final double? salaryMax;
  final String? salaryCurrency;
  final String descriptionText;
  final String contentHash;
  final DateTime? postedAt;
  final DateTime? sourceUpdatedAt;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final String source;
  final String? atsProvider;
  final String? externalId;
  final List<JobSkillRequirement> skills;

  const NormalizedJob({
    required this.id,
    required this.canonicalUrl,
    required this.fingerprint,
    required this.company,
    required this.companyNorm,
    required this.title,
    required this.titleNorm,
    required this.roleFamily,
    required this.seniority,
    required this.location,
    required this.city,
    required this.country,
    required this.workMode,
    required this.employmentType,
    required this.expMinMonths,
    this.expMaxMonths,
    this.eduRequirement,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency,
    required this.descriptionText,
    required this.contentHash,
    this.postedAt,
    this.sourceUpdatedAt,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.source,
    this.atsProvider,
    this.externalId,
    required this.skills,
  });

  factory NormalizedJob.fromRaw({
    required String id,
    required String rawTitle,
    required String rawCompany,
    String? rawLocation,
    String? rawDescription,
    String? rawUrl,
    String? rawSalary,
    String? rawEmploymentType,
    String? rawSkills,
    String? source,
    String? atsProvider,
    String? externalId,
    DateTime? publishedAt,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now().toUtc();
    final cleanDesc = HtmlSanitizer.sanitize(rawDescription);
    final canonUrl = CanonicalUrl.normalize(rawUrl);
    final compNorm = TextNormalize.normalizeCompany(rawCompany);
    final tNorm = TextNormalize.normalizeTitle(rawTitle);

    final locDetails = LocationParser.parse(
      location: rawLocation,
      title: rawTitle,
      description: cleanDesc,
    );

    final fp = JobFingerprint.compute(
      company: rawCompany,
      title: rawTitle,
      locationOrRemote: locDetails.workMode == WorkMode.remote ? 'remote' : locDetails.city,
    );

    final roleFam = RoleClassifier.classify(
      title: rawTitle,
      description: cleanDesc,
    );

    final sen = SeniorityParser.parse(rawTitle);
    final expReq = ExperienceRequirementParser.parse('$rawTitle\n$cleanDesc');
    final sal = SalaryParser.parse(rawSalary);

    final skillReqs = SectionSplitter.extractJobSkills(
      title: rawTitle,
      description: cleanDesc,
      explicitSkills: rawSkills,
    );

    return NormalizedJob(
      id: id,
      canonicalUrl: canonUrl,
      fingerprint: fp,
      company: rawCompany.trim(),
      companyNorm: compNorm,
      title: rawTitle.trim(),
      titleNorm: tNorm,
      roleFamily: roleFam,
      seniority: sen,
      location: rawLocation?.trim() ?? '',
      city: locDetails.city,
      country: locDetails.country,
      workMode: locDetails.workMode,
      employmentType: rawEmploymentType?.trim() ?? 'FULL_TIME',
      expMinMonths: expReq.minMonths,
      expMaxMonths: expReq.maxMonths,
      salaryMin: sal?.min,
      salaryMax: sal?.max,
      salaryCurrency: sal?.currency,
      descriptionText: cleanDesc,
      contentHash: TextNormalize.sha1Hex(cleanDesc),
      postedAt: publishedAt,
      firstSeenAt: effectiveNow,
      lastSeenAt: effectiveNow,
      source: source ?? 'unknown',
      atsProvider: atsProvider,
      externalId: externalId,
      skills: skillReqs,
    );
  }
}
