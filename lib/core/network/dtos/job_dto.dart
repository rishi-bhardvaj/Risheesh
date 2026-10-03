import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

class JobDto {
  final String id;
  final String? externalId;
  final String title;
  final String company;
  final String? location;
  final String? salary;
  final String? employmentType;
  final String? experienceRequirement;
  final String? url;
  final String? source;
  final String? description;
  final List<String> skills;
  final DateTime? postedDate;
  final DateTime discoveredAt;
  final double? matchScore;
  final String? matchReason;
  final bool isSaved;
  final String? notes;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobDto({
    required this.id,
    this.externalId,
    required this.title,
    required this.company,
    this.location,
    this.salary,
    this.employmentType,
    this.experienceRequirement,
    this.url,
    this.source,
    this.description,
    this.skills = const [],
    this.postedDate,
    required this.discoveredAt,
    this.matchScore,
    this.matchReason,
    this.isSaved = false,
    this.notes,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobDto.fromJson(Map<String, dynamic> json) {
    List<String> parsedSkills = [];
    if (json['skills'] is List) {
      parsedSkills = (json['skills'] as List).map((s) => s.toString()).toList();
    } else if (json['skills'] is String) {
      try {
        final decoded = jsonDecode(json['skills']);
        if (decoded is List) {
          parsedSkills = decoded.map((s) => s.toString()).toList();
        } else {
          parsedSkills = (json['skills'] as String).split(',').map((s) => s.trim()).toList();
        }
      } catch (_) {
        parsedSkills = (json['skills'] as String).split(',').map((s) => s.trim()).toList();
      }
    }

    return JobDto(
      id: json['id']?.toString() ?? '',
      externalId: json['external_id']?.toString(),
      title: json['title']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      location: json['location']?.toString(),
      salary: json['salary']?.toString(),
      employmentType: json['employment_type']?.toString(),
      experienceRequirement: json['experience_requirement']?.toString(),
      url: json['url']?.toString(),
      source: json['source']?.toString(),
      description: json['description']?.toString(),
      skills: parsedSkills,
      postedDate: json['posted_date'] != null ? DateTime.tryParse(json['posted_date'].toString()) : null,
      discoveredAt: json['discovered_at'] != null
          ? DateTime.tryParse(json['discovered_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      matchScore: json['match_score'] != null ? double.tryParse(json['match_score'].toString()) : null,
      matchReason: json['match_reason']?.toString(),
      isSaved: json['is_saved'] == true,
      notes: json['notes']?.toString(),
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : const {},
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (externalId != null) 'external_id': externalId,
      'title': title,
      'company': company,
      if (location != null) 'location': location,
      if (salary != null) 'salary': salary,
      if (employmentType != null) 'employment_type': employmentType,
      if (experienceRequirement != null) 'experience_requirement': experienceRequirement,
      if (url != null) 'url': url,
      if (source != null) 'source': source,
      if (description != null) 'description': description,
      'skills': skills,
      if (postedDate != null) 'posted_date': postedDate!.toIso8601String(),
      'discovered_at': discoveredAt.toIso8601String(),
      if (matchScore != null) 'match_score': matchScore,
      if (matchReason != null) 'match_reason': matchReason,
      'is_saved': isSaved,
      if (notes != null) 'notes': notes,
      'metadata': metadata,
    };
  }

  /// Local `atsProvider` tag the Jobs screen uses to recognise synced (non-manual) jobs.
  static const _atsBySource = {
    'greenhouse': 'GREENHOUSE',
    'lever': 'LEVER',
    'ashby': 'ASHBY',
    'remoteok': 'REMOTEOK',
    'weworkremotely': 'WWR',
  };

  String? get atsProvider => _atsBySource[(source ?? '').toLowerCase()];

  /// Fields the backend owns. Deliberately excludes `isSaved`, `notes` and `matchScore` so a
  /// refresh never wipes what the user did locally or the per-resume score computed on-device.
  JobsCompanion toBackendUpdateCompanion() {
    return JobsCompanion(
      title: Value(title),
      company: Value(company),
      location: Value(location),
      salary: Value(salary),
      employmentType: Value(employmentType),
      experienceRequirement: Value(experienceRequirement),
      url: Value(url),
      source: Value(source ?? 'Remote'),
      description: Value(description),
      skills: Value(skills.join(', ')),
      postedDate: Value(postedDate),
      atsProvider: Value(atsProvider),
      externalId: Value(externalId),
      updatedAt: Value(updatedAt),
    );
  }

  JobsCompanion toCompanion() {
    return JobsCompanion(
      id: Value(id),
      title: Value(title),
      company: Value(company),
      location: Value(location),
      salary: Value(salary),
      employmentType: Value(employmentType),
      experienceRequirement: Value(experienceRequirement),
      url: Value(url),
      source: Value(source ?? 'Remote'),
      description: Value(description),
      skills: Value(skills.join(', ')),
      postedDate: Value(postedDate),
      atsProvider: Value(atsProvider),
      discoveredAt: Value(discoveredAt),
      isSaved: Value(isSaved),
      notes: Value(notes),
      externalId: Value(externalId),
      matchScore: Value(matchScore?.round()),
      matchTier: Value(matchScore != null ? (matchScore! >= 80 ? 'STRONG' : 'MODERATE') : null),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}
