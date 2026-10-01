import 'dart:convert';
import 'package:career_core/career_core.dart';
import 'package:crypto/crypto.dart';

class DeviceRecord {
  final String id;
  final String kind; // APP or EXTENSION
  final String name;
  final String refreshTokenHash;
  final DateTime createdAt;
  DateTime lastHeartbeatAt;
  bool isRevoked;

  DeviceRecord({
    required this.id,
    required this.kind,
    required this.name,
    required this.refreshTokenHash,
    required this.createdAt,
    required this.lastHeartbeatAt,
    this.isRevoked = false,
  });
}

class ServerStore {
  String? currentSetupCode;
  final Map<String, DeviceRecord> devices = {};
  final Map<String, String> activeAccessTokens = {}; // tokenHash -> deviceId
  final Map<String, (String code, DateTime expiresAt)> pairingCodes = {}; // code -> (code, expiresAt)
  
  CandidateProfile? activeProfile;
  final List<NormalizedJob> jobs = [];
  final Map<String, MatchEvaluationResult> jobMatches = {};
  final List<UserFeedbackRecord> feedback = [];
  final Set<String> seenJobIds = {};
  final List<Map<String, dynamic>> events = [];

  ServerStore() {
    currentSetupCode = 'BOOT1234';
  }

  static String hash(String input) => sha256.convert(utf8.encode(input)).toString();
}
