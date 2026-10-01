import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';

class FreelanceLeadDto {
  final String id;
  final String? externalId;
  final String? clientId;
  final String? projectId;
  final String title;
  final String? clientName;
  final String? contactName;
  final String? contactInfo;
  final String platform;
  final String? description;
  final List<String> skills;
  final double? budget;
  final String currency;
  final String? url;
  final String status;
  final String? proposal;
  final DateTime? deadline;
  final DateTime? followUpDate;
  final String? followUpNote;
  final String? nextAction;
  final String? notes;
  final DateTime? leadDate;
  final double? matchScore;
  final String? matchReason;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FreelanceLeadDto({
    required this.id,
    this.externalId,
    this.clientId,
    this.projectId,
    required this.title,
    this.clientName,
    this.contactName,
    this.contactInfo,
    this.platform = 'Direct',
    this.description,
    this.skills = const [],
    this.budget,
    this.currency = 'USD',
    this.url,
    this.status = 'NEW_LEAD',
    this.proposal,
    this.deadline,
    this.followUpDate,
    this.followUpNote,
    this.nextAction,
    this.notes,
    this.leadDate,
    this.matchScore,
    this.matchReason,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory FreelanceLeadDto.fromJson(Map<String, dynamic> json) {
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

    return FreelanceLeadDto(
      id: json['id']?.toString() ?? '',
      externalId: json['external_id']?.toString(),
      clientId: json['client_id']?.toString(),
      projectId: json['project_id']?.toString(),
      title: json['title']?.toString() ?? '',
      clientName: json['client_name']?.toString(),
      contactName: json['contact_name']?.toString(),
      contactInfo: json['contact_info']?.toString(),
      platform: json['platform']?.toString() ?? 'Direct',
      description: json['description']?.toString(),
      skills: parsedSkills,
      budget: json['budget'] != null ? double.tryParse(json['budget'].toString()) : null,
      currency: json['currency']?.toString() ?? 'USD',
      url: json['url']?.toString(),
      status: json['status']?.toString() ?? 'NEW_LEAD',
      proposal: json['proposal']?.toString(),
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
      followUpDate: json['follow_up_date'] != null ? DateTime.tryParse(json['follow_up_date'].toString()) : null,
      followUpNote: json['follow_up_note']?.toString(),
      nextAction: json['next_action']?.toString(),
      notes: json['notes']?.toString(),
      leadDate: json['lead_date'] != null ? DateTime.tryParse(json['lead_date'].toString()) : null,
      matchScore: json['match_score'] != null ? double.tryParse(json['match_score'].toString()) : null,
      matchReason: json['match_reason']?.toString(),
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
      if (clientId != null) 'client_id': clientId,
      if (projectId != null) 'project_id': projectId,
      'title': title,
      if (clientName != null) 'client_name': clientName,
      if (contactName != null) 'contact_name': contactName,
      if (contactInfo != null) 'contact_info': contactInfo,
      'platform': platform,
      if (description != null) 'description': description,
      'skills': skills,
      if (budget != null) 'budget': budget,
      'currency': currency,
      if (url != null) 'url': url,
      'status': status,
      if (proposal != null) 'proposal': proposal,
      if (deadline != null) 'deadline': deadline!.toIso8601String(),
      if (followUpDate != null) 'follow_up_date': followUpDate!.toIso8601String(),
      if (followUpNote != null) 'follow_up_note': followUpNote,
      if (nextAction != null) 'next_action': nextAction,
      if (notes != null) 'notes': notes,
      if (leadDate != null) 'lead_date': leadDate!.toIso8601String(),
      if (matchScore != null) 'match_score': matchScore,
      if (matchReason != null) 'match_reason': matchReason,
      'metadata': metadata,
    };
  }

  FreelanceLeadsCompanion toCompanion() {
    return FreelanceLeadsCompanion(
      id: drift.Value(id),
      clientId: drift.Value(clientId),
      projectId: drift.Value(projectId),
      title: drift.Value(title),
      clientName: drift.Value(clientName),
      contactName: drift.Value(contactName),
      contactInfo: drift.Value(contactInfo),
      platform: drift.Value(platform),
      description: drift.Value(description),
      skills: drift.Value(skills.join(', ')),
      budget: drift.Value(budget),
      currency: drift.Value(currency),
      url: drift.Value(url),
      status: drift.Value(status),
      proposal: drift.Value(proposal),
      deadline: drift.Value(deadline),
      followUpDate: drift.Value(followUpDate),
      followUpNote: drift.Value(followUpNote),
      nextAction: drift.Value(nextAction),
      notes: drift.Value(notes),
      leadDate: drift.Value(leadDate),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(updatedAt),
    );
  }
}
