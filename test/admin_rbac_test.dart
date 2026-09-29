import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/core/auth/profile_auth_provider.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Admin RBAC and Permissions Flow', () {
    test('First user is automatically created as Admin with ALL permissions', () async {
      await db.registerNewProfile(
        id: 'admin-1',
        name: 'Rishi Bhardwaj',
        email: 'rishi@example.com',
        currentRole: 'Lead Architect',
      );

      final admin = await db.getProfileById('admin-1');
      expect(admin, isNotNull);
      expect(admin!.isAdmin, isTrue);
      expect(admin.status, equals('APPROVED'));
      expect(admin.permissions, equals('ALL'));
      expect(admin.isUserAdmin, isTrue);
      expect(admin.isApproved, isTrue);
      expect(admin.hasPermission('jobs'), isTrue);
      expect(admin.hasPermission('freelance'), isTrue);
      expect(admin.hasPermission('dsa'), isTrue);
    });

    test('Second user registers as PENDING and generates an admin alert notification', () async {
      // 1. Create first user (admin)
      await db.registerNewProfile(
        id: 'admin-1',
        name: 'Rishi Bhardwaj',
        email: 'rishi@example.com',
      );

      // 2. Second user registers
      await db.registerNewProfile(
        id: 'user-2',
        name: 'John Doe',
        email: 'john@example.com',
        currentRole: 'Flutter Dev',
      );

      final secondUser = await db.getProfileById('user-2');
      expect(secondUser, isNotNull);
      expect(secondUser!.isAdmin, isFalse);
      expect(secondUser.status, equals('PENDING'));
      expect(secondUser.permissions, equals(''));
      expect(secondUser.isPending, isTrue);
      expect(secondUser.hasPermission('jobs'), isFalse);

      // Verify admin notification was logged
      final pendingCount = await db.getPendingProfileCount();
      expect(pendingCount, equals(1));

      final hasNotif = await db.hasNotificationBeenSent('new_user_user-2');
      expect(hasNotif, isTrue);
    });

    test('Admin manually assigns permissions and approves user', () async {
      await db.registerNewProfile(id: 'admin-1', name: 'Rishi');
      await db.registerNewProfile(id: 'user-2', name: 'John Doe');

      // Admin grants only 'jobs' and 'dsa' permissions
      await db.setProfilePermissions('user-2', 'jobs,dsa');
      await db.setProfileStatus('user-2', 'APPROVED');

      final updated = await db.getProfileById('user-2');
      expect(updated!.status, equals('APPROVED'));
      expect(updated.isApproved, isTrue);
      expect(updated.hasPermission('jobs'), isTrue);
      expect(updated.hasPermission('dsa'), isTrue);
      expect(updated.hasPermission('freelance'), isFalse);
      expect(updated.hasPermission('ai'), isFalse);
    });

    test('Admin rejects user which revokes access even if permissions exist', () async {
      await db.registerNewProfile(id: 'admin-1', name: 'Rishi');
      await db.registerNewProfile(id: 'user-2', name: 'Spammer');

      await db.setProfileStatus('user-2', 'REJECTED');
      await db.setProfilePermissions('user-2', 'jobs');

      final rejected = await db.getProfileById('user-2');
      expect(rejected!.isRejected, isTrue);
      expect(rejected.hasPermission('jobs'), isFalse);
    });

    test('Admin can delete profile', () async {
      await db.registerNewProfile(id: 'admin-1', name: 'Rishi');
      await db.registerNewProfile(id: 'user-2', name: 'Temp');

      final countBefore = (await db.getAllProfiles()).length;
      expect(countBefore, equals(2));

      await db.deleteProfile('user-2');

      final countAfter = (await db.getAllProfiles()).length;
      expect(countAfter, equals(1));
    });
  });
}
