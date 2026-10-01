import 'dart:typed_data';
import 'ai_provider_interfaces.dart';

class FakeEmbeddingProvider implements EmbeddingProvider {
  @override
  String get modelId => 'gemini-embedding-001';

  @override
  int get dimensions => 768;

  @override
  Future<List<Float32List>> embed(List<String> texts, {String taskType = 'SEMANTIC_SIMILARITY'}) async {
    return texts.map((_) => Float32List(768)).toList();
  }
}

class FakeMatchingProvider implements MatchingProvider {
  final bool defaultIsRelevant;
  final int defaultScore;

  const FakeMatchingProvider({
    this.defaultIsRelevant = true,
    this.defaultScore = 88,
  });

  @override
  Future<LlmMatchResult> classify({
    required Map<String, dynamic> profileJson,
    required Map<String, dynamic> jobJson,
    required Map<String, dynamic> deterministicFindings,
  }) async {
    return LlmMatchResult(
      isRelevant: defaultIsRelevant,
      confidence: 0.9,
      roleFamily: deterministicFindings['roleFamily']?.toString() ?? 'MOBILE',
      relevanceScore: defaultScore,
      roleMatch: 95,
      skillMatch: 90,
      experienceMatch: 85,
      reason: 'Strong technology and experience alignment with required stack.',
      matchedSkills: const [],
      missingImportantSkills: const [],
      redFlags: const [],
    );
  }
}

class FakeExtractionProvider implements ExtractionProvider {
  @override
  Future<Map<String, dynamic>> extractResume(String text) async {
    return {
      'name': 'Candidate Name',
      'currentRole': 'Software Engineer',
      'experience': <Map<String, dynamic>>[],
      'projects': <Map<String, dynamic>>[],
      'education': <Map<String, dynamic>>[],
    };
  }

  @override
  Future<Map<String, dynamic>> extractJob(String text) async {
    return {
      'title': 'Job Title',
      'company': 'Company',
      'description': text,
    };
  }
}
