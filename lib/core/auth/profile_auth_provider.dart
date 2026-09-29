import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../theme/theme_provider.dart';

const String kActiveProfileKey = 'active_profile_id';

class ActiveProfileIdNotifier extends StateNotifier<String?> {
  final SharedPreferences _prefs;
  ActiveProfileIdNotifier(this._prefs) : super(_prefs.getString(kActiveProfileKey));

  Future<void> setActiveProfileId(String? id) async {
    state = id;
    if (id == null) {
      await _prefs.remove(kActiveProfileKey);
    } else {
      await _prefs.setString(kActiveProfileKey, id);
    }
  }
}

final activeProfileIdProvider = StateNotifierProvider<ActiveProfileIdNotifier, String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ActiveProfileIdNotifier(prefs);
});

final activeUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final db = ref.watch(databaseProvider);
  final activeId = ref.watch(activeProfileIdProvider);
  if (activeId != null && activeId.isNotEmpty) {
    return (db.select(db.userProfiles)..where((p) => p.id.equals(activeId))).watchSingleOrNull();
  }
  return db.watchProfile();
});

final allProfilesStreamProvider = StreamProvider<List<UserProfile>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllProfiles();
});

final pendingProfilesCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.userProfiles)..where((p) => p.status.equals('PENDING')))
      .watch()
      .map((list) => list.length);
});

extension UserProfileRbac on UserProfile {
  bool get isUserAdmin => isAdmin ?? false;
  bool get isApproved => status == 'APPROVED';
  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';

  bool hasPermission(String service) {
    if (isUserAdmin) return true;
    if (status != 'APPROVED') return false;
    final p = permissions ?? '';
    if (p == 'ALL') return true;
    final set = p.split(',').map((s) => s.trim().toLowerCase()).toSet();
    return set.contains(service.toLowerCase());
  }
}
