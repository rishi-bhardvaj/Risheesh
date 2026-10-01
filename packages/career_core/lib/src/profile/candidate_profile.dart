import 'dart:convert';

enum ExperienceLevel {
  junior,
  mid,
  senior,
  staff,
}

enum RemotePreferenceMode {
  any,
  remoteOnly,
  hybridOk,
  onsiteOk,
}

class CandidateEducation {
  final String degree;
  final String level; // BACHELOR, MASTER, DOCTORATE, DIPLOMA, OTHER
  final String specialization;
  final String institution;
  final String? start;
  final String? end;
  final String? score;

  const CandidateEducation({
    required this.degree,
    this.level = 'BACHELOR',
    this.specialization = '',
    this.institution = '',
    this.start,
    this.end,
    this.score,
  });

  Map<String, dynamic> toJson() => {
        'degree': degree,
        'level': level,
        'specialization': specialization,
        'institution': institution,
        'start': start,
        'end': end,
        'score': score,
      };

  factory CandidateEducation.fromJson(Map<String, dynamic> json) => CandidateEducation(
        degree: json['degree']?.toString() ?? '',
        level: json['level']?.toString() ?? 'BACHELOR',
        specialization: json['specialization']?.toString() ?? '',
        institution: json['institution']?.toString() ?? '',
        start: json['start']?.toString(),
        end: json['end']?.toString(),
        score: json['score']?.toString(),
      );
}

class CandidateExperience {
  final String company;
  final String role;
  final String? start;
  final String? end;
  final int months;
  final List<String> responsibilities;
  final List<String> technologies;
  final List<String> achievements;
  final String evidence;

  const CandidateExperience({
    required this.company,
    required this.role,
    this.start,
    this.end,
    this.months = 0,
    this.responsibilities = const [],
    this.technologies = const [],
    this.achievements = const [],
    this.evidence = '',
  });

  Map<String, dynamic> toJson() => {
        'company': company,
        'role': role,
        'start': start,
        'end': end,
        'months': months,
        'responsibilities': responsibilities,
        'technologies': technologies,
        'achievements': achievements,
        'evidence': evidence,
      };

  factory CandidateExperience.fromJson(Map<String, dynamic> json) => CandidateExperience(
        company: json['company']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
        start: json['start']?.toString(),
        end: json['end']?.toString(),
        months: (json['months'] as num?)?.toInt() ?? 0,
        responsibilities: (json['responsibilities'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        technologies: (json['technologies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        achievements: (json['achievements'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        evidence: json['evidence']?.toString() ?? '',
      );
}

class CandidateProject {
  final String name;
  final String description;
  final List<String> technologies;
  final String architecture;
  final List<String> responsibilities;
  final String domain;
  final String evidence;

  const CandidateProject({
    required this.name,
    this.description = '',
    this.technologies = const [],
    this.architecture = '',
    this.responsibilities = const [],
    this.domain = '',
    this.evidence = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'technologies': technologies,
        'architecture': architecture,
        'responsibilities': responsibilities,
        'domain': domain,
        'evidence': evidence,
      };

  factory CandidateProject.fromJson(Map<String, dynamic> json) => CandidateProject(
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        technologies: (json['technologies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        architecture: json['architecture']?.toString() ?? '',
        responsibilities: (json['responsibilities'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        domain: json['domain']?.toString() ?? '',
        evidence: json['evidence']?.toString() ?? '',
      );
}

class CandidateProfile {
  final String name;
  final String currentRole;
  final List<String> roles;
  final String primaryRoleFamily;
  final List<String> adjacentRoleFamilies;
  final int experienceMonths;
  final ExperienceLevel experienceLevel;
  final List<CandidateEducation> education;
  final List<String> primarySkills;
  final List<String> secondarySkills;
  final List<String> familiarSkills;
  final List<String> frameworks;
  final List<String> databases;
  final List<String> cloud;
  final List<String> devops;
  final List<String> aiMl;
  final List<String> testing;
  final List<String> tools;
  final List<CandidateExperience> experience;
  final List<CandidateProject> projects;
  final List<String> certifications;
  final List<String> domains;
  final String currentLocation;
  final List<String> preferredLocations;
  final RemotePreferenceMode remotePreference;
  final List<String> employmentTypes;
  final bool willRelocate;
  final List<String> countries;

  // Metadata
  final int parserVersion;
  final String sourceResumeSha256;
  final List<String> warnings;
  final List<String> overriddenFields;
  final String? embeddingKey;

  const CandidateProfile({
    required this.name,
    this.currentRole = '',
    this.roles = const [],
    this.primaryRoleFamily = 'MOBILE',
    this.adjacentRoleFamilies = const [],
    this.experienceMonths = 0,
    this.experienceLevel = ExperienceLevel.mid,
    this.education = const [],
    this.primarySkills = const [],
    this.secondarySkills = const [],
    this.familiarSkills = const [],
    this.frameworks = const [],
    this.databases = const [],
    this.cloud = const [],
    this.devops = const [],
    this.aiMl = const [],
    this.testing = const [],
    this.tools = const [],
    this.experience = const [],
    this.projects = const [],
    this.certifications = const [],
    this.domains = const [],
    this.currentLocation = '',
    this.preferredLocations = const [],
    this.remotePreference = RemotePreferenceMode.any,
    this.employmentTypes = const ['FULL_TIME'],
    this.willRelocate = false,
    this.countries = const ['IN'],
    this.parserVersion = 1,
    this.sourceResumeSha256 = '',
    this.warnings = const [],
    this.overriddenFields = const [],
    this.embeddingKey,
  });

  /// Canonical all skills set.
  Set<String> get allCanonicalSkills => {
        ...primarySkills,
        ...secondarySkills,
        ...familiarSkills,
        ...frameworks,
        ...databases,
        ...cloud,
        ...devops,
        ...aiMl,
        ...testing,
        ...tools,
      };

  Map<String, dynamic> toJson() => {
        'candidate': {
          'name': name,
          'currentRole': currentRole,
          'roles': roles,
          'roleFamilies': {
            'primary': primaryRoleFamily,
            'adjacent': adjacentRoleFamilies,
          },
          'experienceMonths': experienceMonths,
          'experienceLevel': experienceLevel.name.toUpperCase(),
          'education': education.map((e) => e.toJson()).toList(),
          'skills': {
            'primary': primarySkills,
            'secondary': secondarySkills,
            'familiar': familiarSkills,
          },
          'frameworks': frameworks,
          'databases': databases,
          'cloud': cloud,
          'devops': devops,
          'ai_ml': aiMl,
          'testing': testing,
          'tools': tools,
          'experience': experience.map((e) => e.toJson()).toList(),
          'projects': projects.map((p) => p.toJson()).toList(),
          'certifications': certifications,
          'domains': domains,
          'locations': {
            'current': currentLocation,
            'preferred': preferredLocations,
          },
          'careerPreferences': {
            'remote': remotePreference.name.toUpperCase(),
            'employmentTypes': employmentTypes,
            'relocate': willRelocate,
            'countries': countries,
          },
        },
        'meta': {
          'parserVersion': parserVersion,
          'sourceResumeSha256': sourceResumeSha256,
          'warnings': warnings,
          'overriddenFields': overriddenFields,
          if (embeddingKey != null) 'embeddingKey': embeddingKey,
        },
      };

  factory CandidateProfile.fromJson(Map<String, dynamic> json) {
    // Check if legacy ResumeProfile format
    if (json.containsKey('fullName') || (json.containsKey('contact') && !json.containsKey('candidate'))) {
      return CandidateProfile.fromLegacyJson(json);
    }

    final c = json['candidate'] as Map<String, dynamic>? ?? json;
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};

    final roleFam = c['roleFamilies'] as Map<String, dynamic>? ?? const {};
    final sk = c['skills'] as Map<String, dynamic>? ?? const {};
    final locs = c['locations'] as Map<String, dynamic>? ?? const {};
    final prefs = c['careerPreferences'] as Map<String, dynamic>? ?? const {};

    return CandidateProfile(
      name: c['name']?.toString() ?? '',
      currentRole: c['currentRole']?.toString() ?? '',
      roles: (c['roles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      primaryRoleFamily: roleFam['primary']?.toString() ?? 'MOBILE',
      adjacentRoleFamilies: (roleFam['adjacent'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      experienceMonths: (c['experienceMonths'] as num?)?.toInt() ?? 0,
      experienceLevel: _parseExpLevel(c['experienceLevel']?.toString()),
      education: (c['education'] as List?)?.map((e) => CandidateEducation.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
      primarySkills: (sk['primary'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      secondarySkills: (sk['secondary'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      familiarSkills: (sk['familiar'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      frameworks: (c['frameworks'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      databases: (c['databases'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      cloud: (c['cloud'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      devops: (c['devops'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      aiMl: (c['ai_ml'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      testing: (c['testing'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      tools: (c['tools'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      experience: (c['experience'] as List?)?.map((e) => CandidateExperience.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
      projects: (c['projects'] as List?)?.map((e) => CandidateProject.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
      certifications: (c['certifications'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      domains: (c['domains'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      currentLocation: locs['current']?.toString() ?? '',
      preferredLocations: (locs['preferred'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      remotePreference: _parseRemotePref(prefs['remote']?.toString()),
      employmentTypes: (prefs['employmentTypes'] as List?)?.map((e) => e.toString()).toList() ?? const ['FULL_TIME'],
      willRelocate: prefs['relocate'] as bool? ?? false,
      countries: (prefs['countries'] as List?)?.map((e) => e.toString()).toList() ?? const ['IN'],
      parserVersion: (meta['parserVersion'] as num?)?.toInt() ?? 1,
      sourceResumeSha256: meta['sourceResumeSha256']?.toString() ?? '',
      warnings: (meta['warnings'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      overriddenFields: (meta['overriddenFields'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      embeddingKey: meta['embeddingKey']?.toString(),
    );
  }

  factory CandidateProfile.fromLegacyJson(Map<String, dynamic> legacy) {
    String extractField(dynamic val) {
      if (val is Map && val.containsKey('value')) return val['value']?.toString() ?? '';
      return val?.toString() ?? '';
    }

    final name = extractField(legacy['fullName']);
    final targetRole = extractField(legacy['targetRole']);
    final skills = (legacy['skills'] as List?)?.map((s) => s.toString()).toList() ?? const [];

    return CandidateProfile(
      name: name,
      currentRole: targetRole,
      roles: targetRole.isNotEmpty ? [targetRole] : const [],
      primaryRoleFamily: 'MOBILE',
      adjacentRoleFamilies: const ['FULLSTACK'],
      primarySkills: skills.take(10).toList(),
      secondarySkills: skills.skip(10).take(10).toList(),
      familiarSkills: skills.skip(20).toList(),
      warnings: const ['Migrated from legacy profile format'],
    );
  }

  CandidateProfile applyOverrides(Map<String, dynamic> overrides) {
    return CandidateProfile(
      name: overrides['name']?.toString() ?? name,
      currentRole: overrides['currentRole']?.toString() ?? currentRole,
      roles: (overrides['roles'] as List?)?.map((e) => e.toString()).toList() ?? roles,
      primaryRoleFamily: overrides['primaryRoleFamily']?.toString() ?? primaryRoleFamily,
      adjacentRoleFamilies: (overrides['adjacentRoleFamilies'] as List?)?.map((e) => e.toString()).toList() ?? adjacentRoleFamilies,
      experienceMonths: (overrides['experienceMonths'] as num?)?.toInt() ?? experienceMonths,
      experienceLevel: overrides['experienceLevel'] != null ? _parseExpLevel(overrides['experienceLevel'].toString()) : experienceLevel,
      education: education,
      primarySkills: (overrides['primarySkills'] as List?)?.map((e) => e.toString()).toList() ?? primarySkills,
      secondarySkills: (overrides['secondarySkills'] as List?)?.map((e) => e.toString()).toList() ?? secondarySkills,
      familiarSkills: (overrides['familiarSkills'] as List?)?.map((e) => e.toString()).toList() ?? familiarSkills,
      frameworks: frameworks,
      databases: databases,
      cloud: cloud,
      devops: devops,
      aiMl: aiMl,
      testing: testing,
      tools: tools,
      experience: experience,
      projects: projects,
      certifications: certifications,
      domains: domains,
      currentLocation: overrides['currentLocation']?.toString() ?? currentLocation,
      preferredLocations: (overrides['preferredLocations'] as List?)?.map((e) => e.toString()).toList() ?? preferredLocations,
      remotePreference: overrides['remotePreference'] != null ? _parseRemotePref(overrides['remotePreference'].toString()) : remotePreference,
      employmentTypes: employmentTypes,
      willRelocate: overrides['willRelocate'] as bool? ?? willRelocate,
      countries: countries,
      parserVersion: parserVersion,
      sourceResumeSha256: sourceResumeSha256,
      warnings: warnings,
      overriddenFields: overrides.keys.toList(),
      embeddingKey: embeddingKey,
    );
  }

  static ExperienceLevel _parseExpLevel(String? s) {
    if (s == null) return ExperienceLevel.mid;
    switch (s.toLowerCase()) {
      case 'junior':
        return ExperienceLevel.junior;
      case 'senior':
        return ExperienceLevel.senior;
      case 'staff':
      case 'principal':
        return ExperienceLevel.staff;
      default:
        return ExperienceLevel.mid;
    }
  }

  static RemotePreferenceMode _parseRemotePref(String? s) {
    if (s == null) return RemotePreferenceMode.any;
    switch (s.toLowerCase()) {
      case 'remote_only':
      case 'remote':
        return RemotePreferenceMode.remoteOnly;
      case 'hybrid_ok':
      case 'hybrid':
        return RemotePreferenceMode.hybridOk;
      case 'onsite_ok':
      case 'onsite':
        return RemotePreferenceMode.onsiteOk;
      default:
        return RemotePreferenceMode.any;
    }
  }
}
