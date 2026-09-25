import 'dart:convert';

enum ExtractionConfidence {
  high,
  medium,
  low,
}

class ExtractedField<T> {
  final T value;
  final ExtractionConfidence confidence;
  final String? sourceSnippet;

  const ExtractedField({
    required this.value,
    this.confidence = ExtractionConfidence.high,
    this.sourceSnippet,
  });

  Map<String, dynamic> toJson() => {
        'value': value,
        'confidence': confidence.name,
        if (sourceSnippet != null) 'sourceSnippet': sourceSnippet,
      };

  factory ExtractedField.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) parser,
  ) {
    return ExtractedField<T>(
      value: parser(json['value']),
      confidence: ExtractionConfidence.values.byName(
        json['confidence'] ?? 'medium',
      ),
      sourceSnippet: json['sourceSnippet'] as String?,
    );
  }
}

class ResumeQualityAudit {
  final int score; // 0 - 100
  final bool hasContactInfo;
  final bool hasLinkedInOrGitHub;
  final bool hasEducation;
  final bool hasTargetRole;
  final bool hasSufficientSkills;
  final List<String> passedChecks;
  final List<String> improvementSuggestions;

  const ResumeQualityAudit({
    required this.score,
    required this.hasContactInfo,
    required this.hasLinkedInOrGitHub,
    required this.hasEducation,
    required this.hasTargetRole,
    required this.hasSufficientSkills,
    required this.passedChecks,
    required this.improvementSuggestions,
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'hasContactInfo': hasContactInfo,
        'hasLinkedInOrGitHub': hasLinkedInOrGitHub,
        'hasEducation': hasEducation,
        'hasTargetRole': hasTargetRole,
        'hasSufficientSkills': hasSufficientSkills,
        'passedChecks': passedChecks,
        'improvementSuggestions': improvementSuggestions,
      };

  factory ResumeQualityAudit.fromJson(Map<String, dynamic> json) {
    return ResumeQualityAudit(
      score: (json['score'] as num?)?.toInt() ?? 0,
      hasContactInfo: json['hasContactInfo'] as bool? ?? false,
      hasLinkedInOrGitHub: json['hasLinkedInOrGitHub'] as bool? ?? false,
      hasEducation: json['hasEducation'] as bool? ?? false,
      hasTargetRole: json['hasTargetRole'] as bool? ?? false,
      hasSufficientSkills: json['hasSufficientSkills'] as bool? ?? false,
      passedChecks: (json['passedChecks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      improvementSuggestions:
          (json['improvementSuggestions'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
    );
  }
}

class ResumeProfile {
  final String resumeId;
  final String resumeName;
  final ExtractedField<String>? fullName;
  final ExtractedField<String>? email;
  final ExtractedField<String>? phone;
  final ExtractedField<String>? linkedin;
  final ExtractedField<String>? github;
  final ExtractedField<String>? targetRole;
  final ExtractedField<double>? experienceYears;
  final ExtractedField<String>? education;
  final List<ExtractedField<String>> programmingLanguages;
  final List<ExtractedField<String>> frameworks;
  final List<ExtractedField<String>> toolsAndCloud;
  final List<ExtractedField<String>> domainSkills;
  final List<String> rawLines;
  final ResumeQualityAudit qualityAudit;

  const ResumeProfile({
    required this.resumeId,
    required this.resumeName,
    this.fullName,
    this.email,
    this.phone,
    this.linkedin,
    this.github,
    this.targetRole,
    this.experienceYears,
    this.education,
    this.programmingLanguages = const [],
    this.frameworks = const [],
    this.toolsAndCloud = const [],
    this.domainSkills = const [],
    this.rawLines = const [],
    required this.qualityAudit,
  });

  List<String> get allUniqueSkills {
    final set = <String>{};
    for (final l in programmingLanguages) {
      set.add(l.value);
    }
    for (final f in frameworks) {
      set.add(f.value);
    }
    for (final t in toolsAndCloud) {
      set.add(t.value);
    }
    for (final d in domainSkills) {
      set.add(d.value);
    }
    return set.toList();
  }

  Map<String, dynamic> toJson() => {
        'resumeId': resumeId,
        'resumeName': resumeName,
        if (fullName != null) 'fullName': fullName!.toJson(),
        if (email != null) 'email': email!.toJson(),
        if (phone != null) 'phone': phone!.toJson(),
        if (linkedin != null) 'linkedin': linkedin!.toJson(),
        if (github != null) 'github': github!.toJson(),
        if (targetRole != null) 'targetRole': targetRole!.toJson(),
        if (experienceYears != null)
          'experienceYears': experienceYears!.toJson(),
        if (education != null) 'education': education!.toJson(),
        'programmingLanguages':
            programmingLanguages.map((e) => e.toJson()).toList(),
        'frameworks': frameworks.map((e) => e.toJson()).toList(),
        'toolsAndCloud': toolsAndCloud.map((e) => e.toJson()).toList(),
        'domainSkills': domainSkills.map((e) => e.toJson()).toList(),
        'qualityAudit': qualityAudit.toJson(),
      };

  factory ResumeProfile.fromJson(Map<String, dynamic> json) {
    return ResumeProfile(
      resumeId: json['resumeId'] as String? ?? '',
      resumeName: json['resumeName'] as String? ?? '',
      fullName: json['fullName'] != null
          ? ExtractedField<String>.fromJson(
              json['fullName'] as Map<String, dynamic>, (v) => v.toString())
          : null,
      email: json['email'] != null
          ? ExtractedField<String>.fromJson(
              json['email'] as Map<String, dynamic>, (v) => v.toString())
          : null,
      phone: json['phone'] != null
          ? ExtractedField<String>.fromJson(
              json['phone'] as Map<String, dynamic>, (v) => v.toString())
          : null,
      linkedin: json['linkedin'] != null
          ? ExtractedField<String>.fromJson(
              json['linkedin'] as Map<String, dynamic>, (v) => v.toString())
          : null,
      github: json['github'] != null
          ? ExtractedField<String>.fromJson(
              json['github'] as Map<String, dynamic>, (v) => v.toString())
          : null,
      targetRole: json['targetRole'] != null
          ? ExtractedField<String>.fromJson(
              json['targetRole'] as Map<String, dynamic>, (v) => v.toString())
          : null,
      experienceYears: json['experienceYears'] != null
          ? ExtractedField<double>.fromJson(
              json['experienceYears'] as Map<String, dynamic>,
              (v) => (v as num).toDouble())
          : null,
      education: json['education'] != null
          ? ExtractedField<String>.fromJson(
              json['education'] as Map<String, dynamic>, (v) => v.toString())
          : null,
      programmingLanguages: (json['programmingLanguages'] as List<dynamic>?)
              ?.map((e) => ExtractedField<String>.fromJson(
                  e as Map<String, dynamic>, (v) => v.toString()))
              .toList() ??
          [],
      frameworks: (json['frameworks'] as List<dynamic>?)
              ?.map((e) => ExtractedField<String>.fromJson(
                  e as Map<String, dynamic>, (v) => v.toString()))
              .toList() ??
          [],
      toolsAndCloud: (json['toolsAndCloud'] as List<dynamic>?)
              ?.map((e) => ExtractedField<String>.fromJson(
                  e as Map<String, dynamic>, (v) => v.toString()))
              .toList() ??
          [],
      domainSkills: (json['domainSkills'] as List<dynamic>?)
              ?.map((e) => ExtractedField<String>.fromJson(
                  e as Map<String, dynamic>, (v) => v.toString()))
              .toList() ??
          [],
      qualityAudit: json['qualityAudit'] != null
          ? ResumeQualityAudit.fromJson(
              json['qualityAudit'] as Map<String, dynamic>)
          : const ResumeQualityAudit(
              score: 50,
              hasContactInfo: false,
              hasLinkedInOrGitHub: false,
              hasEducation: false,
              hasTargetRole: false,
              hasSufficientSkills: false,
              passedChecks: [],
              improvementSuggestions: [],
            ),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static ResumeProfile? fromJsonString(String? jsonStr) {
    if (jsonStr == null || jsonStr.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ResumeProfile.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}

class ProfileDiffItem {
  final String fieldName;
  final String label;
  final String? currentValue;
  final String extractedValue;
  final ExtractionConfidence confidence;
  final bool selectedByDefault;

  const ProfileDiffItem({
    required this.fieldName,
    required this.label,
    this.currentValue,
    required this.extractedValue,
    this.confidence = ExtractionConfidence.high,
    this.selectedByDefault = true,
  });
}
