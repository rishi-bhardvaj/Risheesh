import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../domain/resume_profile_models.dart';
import 'resume_parser_service.dart';
import 'resume_text_extractor.dart';

class ResumeIngestResult {
  final String text;
  final ResumeProfile profile;

  const ResumeIngestResult(this.text, this.profile);
}

class ProfileApplyResult {
  final List<String> fieldsFilled;
  final int skillsAdded;

  const ProfileApplyResult(this.fieldsFilled, this.skillsAdded);
}

/// Runs on a worker isolate: synchronous file read + PDF parse.
String _extractInBackground(String path) =>
    ResumeTextExtractor.extractFromBytes(File(path).readAsBytesSync(), fileName: path);

/// Resume file -> text -> [ResumeProfile] -> database (resume row, career
/// profile, and skills tracker).
class ResumeIngestService {
  final AppDatabase db;
  static final _parser = ResumeParserService();
  static const _uuid = Uuid();

  ResumeIngestService(this.db);

  /// Extracts text off the UI isolate (PDF parsing can take a moment on
  /// low-end phones) and parses it.
  static Future<ResumeIngestResult> fromFile(String path, {required String resumeId, required String resumeName}) async {
    final text = await compute(_extractInBackground, path);
    return fromText(text, resumeId: resumeId, resumeName: resumeName);
  }

  static ResumeIngestResult fromText(String text, {required String resumeId, required String resumeName}) {
    final normalized = ResumeTextExtractor.normalize(text);
    if (normalized.length < 60) {
      throw const ResumeExtractionException('Not enough text to parse. Paste the full resume or upload a text-based PDF.');
    }
    return ResumeIngestResult(
      normalized,
      _parser.parseResumeText(resumeText: normalized, resumeId: resumeId, resumeName: resumeName),
    );
  }

  Future<void> saveParsed(String resumeId, ResumeProfile profile) async {
    await (db.update(db.resumes)..where((r) => r.id.equals(resumeId))).write(ResumesCompanion(
      parsedDataJson: Value(profile.toJsonString()),
      extractionStatus: const Value('PARSED'),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> markFailed(String resumeId) async {
    await (db.update(db.resumes)..where((r) => r.id.equals(resumeId)))
        .write(const ResumesCompanion(extractionStatus: Value('FAILED')));
  }

  static List<String> _splitList(String? s) =>
      (s ?? '').split(RegExp(r'[,\n;]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  static String _mergeList(String? existing, Iterable<String> extra) {
    final out = <String>[];
    final seen = <String>{};
    for (final v in [..._splitList(existing), ...extra]) {
      if (seen.add(v.toLowerCase())) out.add(v);
    }
    return out.join(', ');
  }

  /// Fills empty profile fields from the resume and merges skill lists.
  /// Values the user already entered are kept unless [overwrite] is true.
  Future<ProfileApplyResult> applyToProfile(ResumeProfile p, {bool overwrite = false}) async {
    final existing = await db.getProfile();
    final filled = <String>[];
    final now = DateTime.now();

    bool isEmpty(String? v) => v == null || v.trim().isEmpty;
    Value<String?> pick(String label, String? current, String? extracted) {
      if (isEmpty(extracted)) return const Value.absent();
      if (!overwrite && !isEmpty(current)) return const Value.absent();
      filled.add(label);
      return Value(extracted!.trim());
    }

    final defaultName = existing == null ||
        existing.name == AppConstants.defaultUserName ||
        existing.name == 'Engineer';
    final name = p.fullName?.value;
    final languages = p.programmingLanguages.map((e) => e.value);
    final frameworks = p.frameworks.map((e) => e.value);

    final companion = UserProfilesCompanion(
      id: Value(existing?.id ?? _uuid.v4()),
      name: (name != null && (overwrite || defaultName))
          ? (() {
              filled.add('Name');
              return Value(name);
            })()
          : Value(existing?.name ?? AppConstants.defaultUserName),
      currentRole: pick('Current role', existing?.currentRole, p.targetRole?.value),
      preferredRoles: pick('Target roles', existing?.preferredRoles, p.targetRole?.value),
      education: pick('Education', existing?.education, p.educationEntries.isEmpty ? p.education?.value : p.educationEntries.join('\n')),
      email: pick('Email', existing?.email, p.email?.value),
      phone: pick('Phone', existing?.phone, p.phone?.value),
      linkedinUrl: pick('LinkedIn', existing?.linkedinUrl, p.linkedin?.value),
      githubUrl: pick('GitHub', existing?.githubUrl, p.github?.value),
      experienceYears: (p.experienceYears != null && (overwrite || (existing?.experienceYears ?? 0) == 0))
          ? (() {
              filled.add('Experience');
              return Value(p.experienceYears!.value);
            })()
          : const Value.absent(),
      skills: p.allUniqueSkills.isEmpty ? const Value.absent() : Value(_mergeList(existing?.skills, p.allUniqueSkills)),
      programmingLanguages: languages.isEmpty ? const Value.absent() : Value(_mergeList(existing?.programmingLanguages, languages)),
      frameworks: frameworks.isEmpty ? const Value.absent() : Value(_mergeList(existing?.frameworks, frameworks)),
      createdAt: Value(existing?.createdAt ?? now),
      updatedAt: Value(now),
    );
    if (p.allUniqueSkills.isNotEmpty) filled.add('Skills');

    if (existing == null) {
      await db.upsertProfile(companion);
    } else {
      await (db.update(db.userProfiles)..where((u) => u.id.equals(existing.id))).write(companion);
    }

    // Skills tracker: add any skill not already tracked.
    final tracked = (await db.getAllSkills()).map((s) => s.name.toLowerCase()).toSet();
    final newSkills = <LearningSkillsCompanion>[];
    void addAll(Iterable<ExtractedField<String>> items, String category) {
      for (final s in items) {
        if (tracked.add(s.value.toLowerCase())) {
          newSkills.add(LearningSkillsCompanion(
            id: Value(_uuid.v4()),
            name: Value(s.value),
            category: Value(category),
            currentLevel: Value(SkillLevel.intermediate.value),
            targetLevel: Value(SkillLevel.advanced.value),
            notes: const Value('Imported from resume'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ));
        }
      }
    }

    addAll(p.programmingLanguages, 'Language');
    addAll(p.frameworks, 'Framework');
    addAll(p.toolsAndCloud, 'Tools & Cloud');
    addAll(p.domainSkills, 'Domain');
    if (newSkills.isNotEmpty) {
      await db.batch((b) => b.insertAll(db.learningSkills, newSkills));
    }
    return ProfileApplyResult(filled, newSkills.length);
  }
}
