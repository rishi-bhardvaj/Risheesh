import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/core/theme/app_theme.dart';
import 'package:career_os/features/settings/presentation/admin_users_screen.dart';
import 'package:career_os/features/settings/presentation/system_status_screen.dart';

void main() {
  const testWidths = [320.0, 360.0, 411.0, 600.0, 840.0];
  const testScales = [1.0, 1.3];

  for (final width in testWidths) {
    for (final scale in testScales) {
      testWidgets('AdminUsersScreen renders without overflow on width ${width}dp, scale $scale', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final db = AppDatabase(NativeDatabase.memory());
        await db.registerNewProfile(id: 'admin', name: 'Rishi', email: 'rishi@example.com');
        await db.registerNewProfile(id: 'user-2', name: 'Applicant One', email: 'applicant@example.com');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 800),
                  textScaler: TextScaler.linear(scale),
                ),
                child: const AdminUsersScreen(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('User Accounts & RBAC'), findsOneWidget);
        await db.close();
      });

      testWidgets('SystemStatusScreen renders without overflow on width ${width}dp, scale $scale', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 800),
                textScaler: TextScaler.linear(scale),
              ),
              child: const SystemStatusScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('System Status & Diagnostics'), findsOneWidget);
      });
    }
  }
}
