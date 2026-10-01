// Renders each main screen with seed data to PNGs for visual review.
// Run: flutter test test_preview --update-goldens
import 'dart:io';

import 'package:career_os/core/ai/ai_keys.dart';
import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/core/theme/app_theme.dart';
import 'package:career_os/core/theme/theme_provider.dart';
import 'package:career_os/features/career/presentation/career_screen.dart';
import 'package:career_os/features/freelance/presentation/business_lead_screen.dart';
import 'package:career_os/features/freelance/presentation/freelance_screen.dart';
import 'package:career_os/features/home/presentation/home_screen.dart';
import 'package:career_os/features/settings/presentation/ai_keys_screen.dart';
import 'package:career_os/features/track/presentation/track_screen.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter';
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String f) async => ByteData.sublistView(await File('$dir/$f').readAsBytes());
  final roboto = FontLoader('Roboto');
  for (final f in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-black.ttf', 'roboto-light.ttf']) {
    if (File('$dir/$f').existsSync()) roboto.addFont(read(f));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(read('materialicons-regular.otf'))).load();
}

Future<void> _seed(AppDatabase db) async {
  final now = DateTime.now();
  await db.upsertProfile(UserProfilesCompanion.insert(
    id: 'u',
    name: 'Risheesh Upadhyay',
    currentRole: const Value('Flutter Developer'),
    experienceYears: const Value(4),
    skills: const Value('Flutter, Dart, Riverpod, Firebase, Kotlin, Node.js, PostgreSQL, Docker'),
    preferredRoles: const Value('Flutter Developer, Mobile Engineer'),
    preferredLocations: const Value('Bengaluru, Remote'),
    remotePreference: const Value('remote'),
    createdAt: Value(now),
    updatedAt: Value(now),
  ));
  final jobs = [
    ('Senior Flutter Engineer', 'Razorpay', 'Bengaluru · Remote', r'₹35L – ₹48L', 'Flutter, Dart, Riverpod, Firebase', 'Greenhouse', 2),
    ('Mobile Engineer, Payments', 'Stripe', 'Remote - India', r'$140k – $190k', 'Kotlin, Flutter, Dart', 'Greenhouse', 5),
    ('Staff Software Engineer', 'Notion', 'San Francisco', r'$211k – $290k', 'TypeScript, React, Node.js', 'Ashby', 20),
    ('Flutter Developer', 'Groww', 'Bengaluru', null, 'Flutter, Dart, Firebase, Riverpod', 'AI search', 8),
    ('Backend Engineer, IAM', 'Reddit', 'Remote', null, 'Go, PostgreSQL, Kubernetes', 'WeWorkRemotely', 30),
  ];
  for (var i = 0; i < jobs.length; i++) {
    final j = jobs[i];
    await db.insertJob(JobsCompanion.insert(
      id: 'j$i',
      title: j.$1,
      company: j.$2,
      location: Value(j.$3),
      salary: Value(j.$4),
      skills: Value(j.$5),
      source: Value(j.$6),
      atsProvider: const Value('GREENHOUSE'),
      postedDate: Value(now.subtract(Duration(hours: j.$7))),
      discoveredAt: Value(now.subtract(Duration(hours: j.$7))),
      isSaved: Value(i == 1),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }
  await db.into(db.jobApplications).insert(JobApplicationsCompanion.insert(
        id: 'a1',
        company: 'Swiggy',
        role: 'SDE II – Mobile',
        status: const Value('interview'),
        appliedAt: Value(now.subtract(const Duration(days: 9))),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
  final leads = [
    ('Shree Balaji Textiles', 'Textile manufacturer', 'Surat', 1.2e8, 'NO_WEBSITE', 88, 'Only an IndiaMART page, no own website'),
    ('Kalyan Spices & Masala', 'Spice exporter', 'Kochi', 4.5e7, 'NEEDS_WEBSITE', 74, 'Not mobile-friendly (no viewport)\nLast updated around 2019'),
    ('Mehta Handicrafts', 'Home decor D2C', 'Jaipur', 2.5e7, 'SHOPIFY', 61, 'Shopify store\nAssets on cdn.shopify.com'),
  ];
  for (var i = 0; i < leads.length; i++) {
    final l = leads[i];
    await db.into(db.businessLeads).insert(BusinessLeadsCompanion.insert(
          id: 'b$i',
          name: l.$1,
          industry: Value(l.$2),
          city: Value(l.$3),
          turnoverInr: Value(l.$4),
          turnoverEvidence: const Value('IndiaMART profile lists Annual Turnover: 5 - 25 Cr and a GST registration since 2011.'),
          turnoverSourceUrl: const Value('https://www.indiamart.com/example'),
          webPresence: Value(l.$5),
          needScore: Value(l.$6),
          presenceNotes: Value(l.$7),
          phone: const Value('+91 98765 43210'),
          pitch: const Value('Sells ₹10 Cr+ a year through distributors but has no site buyers can find or order from.'),
          linksJson: const Value('[{"label":"IndiaMART","url":"https://indiamart.com/x"},{"label":"Instagram","url":"https://instagram.com/x"}]'),
          discoveredAt: Value(now.subtract(Duration(hours: i * 3))),
        ));
  }
  final problems = [
    ('1. Two Sum', 'EASY', 'Arrays & Hashing', 'SOLVED'),
    ('3. Longest Substring Without Repeating Characters', 'MEDIUM', 'Sliding Window', 'SOLVED'),
    ('4. Median of Two Sorted Arrays', 'HARD', 'Binary Search', 'TODO'),
    ('20. Valid Parentheses', 'EASY', 'Stack', 'TODO'),
    ('146. LRU Cache', 'MEDIUM', 'Linked List', 'ATTEMPTED'),
  ];
  for (var i = 0; i < problems.length; i++) {
    final p = problems[i];
    await db.insertDSAProblem(DSAProblemsCompanion.insert(
      id: 'p$i',
      title: p.$1,
      difficulty: Value(p.$2),
      topic: Value(p.$3),
      status: Value(p.$4),
      url: const Value('https://leetcode.com/problems/two-sum/'),
      notes: const Value('Acceptance: 49.2%'),
    ));
  }
  await db.insertHabit(HabitsCompanion.insert(id: 'h1', name: 'Solve 2 LeetCode problems', icon: const Value('code')));
  await db.insertHabit(HabitsCompanion.insert(id: 'h2', name: 'Workout 30 min', icon: const Value('fitness'), colorValue: const Value(0xFFFFB84D)));
  final today = DateTime(now.year, now.month, now.day);
  for (var d = 0; d < 4; d++) {
    await db.setHabitDone('h1', today.subtract(Duration(days: d)), true, 'l$d');
  }
}

void main() {
  setUpAll(_loadFonts);

  final screens = <String, Widget Function()>{
    'home': () => const HomeScreen(),
    'career_jobs': () => const CareerScreen(),
    'freelance_leads': () => const FreelanceScreen(),
    'lead_detail': () => const BusinessLeadScreen(leadId: 'b0'),
    'track_leetcode': () => const TrackScreen(),
    'ai_keys': () => const AiKeysScreen(firstRun: true),
  };

  for (final entry in screens.entries) {
    testWidgets('preview ${entry.key}', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'live_jobs_last_sync_ms': DateTime.now().millisecondsSinceEpoch});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(() => _seed(db));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          aiKeyStoreProvider.overrideWithValue(MemoryAiKeyStore()),
          initialAiKeysProvider.overrideWithValue(
            entry.key == 'ai_keys' ? const AiKeys().copyWith(AiProvider.claude, 'x') : const AiKeys().copyWith(AiProvider.claude, 'x').copyWith(AiProvider.gemini, 'y'),
          ),
        ],
        child: MaterialApp(debugShowCheckedModeBanner: false, theme: AppTheme.darkTheme, home: entry.value()),
      ));
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${entry.key}.png'));
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(db.close);
    });
  }
}
