import 'dart:convert';
import 'package:career_core/career_core.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';

class JobScoredData {
  final String id;
  final int score;
  final String tier;
  final String matchJson;
  final String roleFamily;
  final bool isRemote;
  final double? salaryMinInr;
  final double? salaryMaxInr;

  const JobScoredData({
    required this.id,
    required this.score,
    required this.tier,
    required this.matchJson,
    required this.roleFamily,
    required this.isRemote,
    this.salaryMinInr,
    this.salaryMaxInr,
  });
}

class JobScoringPayload {
  final String id;
  final String title;
  final String company;
  final String? location;
  final String? description;
  final String? salary;
  final String? skills;
  final String? employmentType;
  final String? source;
  final String? atsProvider;
  final String? externalId;

  const JobScoringPayload({
    required this.id,
    required this.title,
    required this.company,
    this.location,
    this.description,
    this.salary,
    this.skills,
    this.employmentType,
    this.source,
    this.atsProvider,
    this.externalId,
  });

  factory JobScoringPayload.fromJob(Job j) => JobScoringPayload(
        id: j.id,
        title: j.title,
        company: j.company,
        location: j.location,
        description: j.description,
        salary: j.salary,
        skills: j.skills,
        employmentType: j.employmentType,
        source: j.source,
        atsProvider: j.atsProvider,
        externalId: j.externalId,
      );
}

class JobScoringService {
  /// Computes a stable hash of the candidate profile to know when to re-score.
  static String computeProfileVersion(CandidateProfile profile) {
    final raw = '${profile.name}|${profile.currentRole}|${profile.primaryRoleFamily}|'
        '${profile.primarySkills.join(',')}|${profile.secondarySkills.join(',')}|'
        '${profile.experienceMonths}|${profile.remotePreference.name}';
    return sha256.convert(utf8.encode(raw)).toString().substring(0, 16);
  }

  /// Builds a [CandidateProfile] from the database [UserProfile] and primary [Resume].
  static CandidateProfile buildCandidateProfile({
    UserProfile? profile,
    Resume? primaryResume,
  }) {
    List<String> primarySkills = [];
    List<String> secondarySkills = [];
    String name = profile?.name ?? 'Candidate';
    String currentRole = profile?.currentRole ?? 'Software Engineer';
    int expMonths = ((profile?.experienceYears ?? 2.0) * 12).round();

    if (primaryResume?.parsedDataJson != null && primaryResume!.parsedDataJson!.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(primaryResume.parsedDataJson!);
        if (data['skills'] is Map) {
          final sMap = data['skills'] as Map;
          if (sMap['primary'] is List) {
            primarySkills = (sMap['primary'] as List).map((e) => e.toString()).toList();
          }
          if (sMap['secondary'] is List) {
            secondarySkills = (sMap['secondary'] as List).map((e) => e.toString()).toList();
          }
        }
        if (data['summary'] is Map && data['summary']['headline'] != null) {
          currentRole = data['summary']['headline'].toString();
        }
      } catch (_) {}
    }

    if (primarySkills.isEmpty && profile?.skills != null) {
      primarySkills = profile!.skills!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    if (primarySkills.isEmpty) {
      primarySkills = ['Flutter', 'Dart', 'Mobile Development', 'REST APIs'];
    }

    RemotePreferenceMode remoteMode = RemotePreferenceMode.any;
    if (profile?.remotePreference == 'remote') {
      remoteMode = RemotePreferenceMode.remoteOnly;
    } else if (profile?.remotePreference == 'hybrid') {
      remoteMode = RemotePreferenceMode.hybridOk;
    }

    final roleFamily = RoleClassifier.classify(title: currentRole);

    return CandidateProfile(
      name: name,
      currentRole: currentRole,
      primaryRoleFamily: roleFamily.isEmpty ? 'MOBILE' : roleFamily,
      primarySkills: primarySkills,
      secondarySkills: secondarySkills,
      experienceMonths: expMonths,
      remotePreference: remoteMode,
    );
  }

  /// Scores a batch of jobs in a background isolate using [compute].
  static Future<List<JobScoredData>> scoreJobsInIsolate(
    List<JobScoringPayload> payloads,
    CandidateProfile candidate,
  ) async {
    return compute(_scoreJobsWorker, {
      'payloads': payloads,
      'candidate': candidate,
    });
  }

  static Future<List<JobScoredData>> _scoreJobsWorker(Map<String, dynamic> args) async {
    final payloads = args['payloads'] as List<JobScoringPayload>;
    final candidate = args['candidate'] as CandidateProfile;
    final engine = RelevanceEngine(
      matchingProvider: const FakeMatchingProvider(),
      embeddingProvider: FakeEmbeddingProvider(),
    );
    final results = <JobScoredData>[];

    for (final p in payloads) {
      final normJob = NormalizedJob.fromRaw(
        id: p.id,
        rawTitle: p.title,
        rawCompany: p.company,
        rawLocation: p.location,
        rawDescription: p.description,
        rawSalary: p.salary,
        rawSkills: p.skills,
        rawEmploymentType: p.employmentType,
        source: p.source,
        atsProvider: p.atsProvider,
        externalId: p.externalId,
      );

      final eval = await engine.evaluate(job: normJob, candidate: candidate);

      final tierStr = switch (eval.tier) {
        RelevanceTier.highlyRelevant => 'STRONG_MATCH',
        RelevanceTier.relevant => 'RELEVANT',
        RelevanceTier.possibleMatch => 'LOW_MATCH',
        RelevanceTier.notRelevant => 'NOT_RELEVANT',
        RelevanceTier.unscored => 'NOT_RELEVANT',
      };

      final matchJsonMap = {
        'score': eval.score,
        'tier': tierStr,
        'roleFamily': normJob.roleFamily,
        'workMode': normJob.workMode.name,
        'matchedSkills': eval.explainability.matchedSkills,
        'missingRequired': eval.explainability.missingRequiredSkills,
        'missingPreferred': eval.explainability.missingPreferredSkills,
        'reason': eval.explainability.summaryReason,
      };

      results.add(JobScoredData(
        id: p.id,
        score: eval.score,
        tier: tierStr,
        matchJson: jsonEncode(matchJsonMap),
        roleFamily: normJob.roleFamily,
        isRemote: normJob.workMode == WorkMode.remote,
        salaryMinInr: normJob.salaryMin,
        salaryMaxInr: normJob.salaryMax,
      ));
    }

    return results;
  }

  /// Re-scores all jobs in the database in batches of 200, updating Drift in background.
  static Future<void> reScoreAllJobs(
    AppDatabase db, {
    UserProfile? profile,
    Resume? primaryResume,
  }) async {
    final candidate = buildCandidateProfile(profile: profile, primaryResume: primaryResume);
    final version = computeProfileVersion(candidate);
    final allJobs = await db.getAllJobs();
    if (allJobs.isEmpty) return;

    final payloads = allJobs.map((j) => JobScoringPayload.fromJob(j)).toList();
    const batchSize = 200;

    for (var i = 0; i < payloads.length; i += batchSize) {
      final end = (i + batchSize < payloads.length) ? i + batchSize : payloads.length;
      final chunk = payloads.sublist(i, end);
      final scored = await scoreJobsInIsolate(chunk, candidate);

      await db.batch((batch) {
        for (final s in scored) {
          batch.update(
            db.jobs,
            JobsCompanion(
              matchScore: Value(s.score),
              matchTier: Value(s.tier),
              matchJson: Value(s.matchJson),
              roleFamily: Value(s.roleFamily),
              isRemote: Value(s.isRemote),
              salaryMinInr: Value(s.salaryMinInr),
              salaryMaxInr: Value(s.salaryMaxInr),
              matchProfileVersion: Value(version),
              updatedAt: Value(DateTime.now()),
            ),
            where: (j) => j.id.equals(s.id),
          );
        }
      });
    }
  }
}
