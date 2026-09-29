import 'package:career_os/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v10 database upgrades cleanly to v11 with RBAC, new tables, diet and scoring columns', () async {
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      // 1. Create v10 UserProfiles table
      raw.execute('''CREATE TABLE user_profiles (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        current_role TEXT,
        experience_years REAL NOT NULL DEFAULT 0.0,
        skills TEXT,
        programming_languages TEXT,
        frameworks TEXT,
        preferred_roles TEXT,
        preferred_locations TEXT,
        remote_preference TEXT NOT NULL DEFAULT 'any',
        expected_salary TEXT,
        preferred_employment_type TEXT,
        notice_period TEXT,
        education TEXT,
        resume_preferences TEXT,
        email TEXT,
        phone TEXT,
        linkedin_url TEXT,
        github_url TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )''');

      // 2. Create v10 Resumes table
      raw.execute('''CREATE TABLE resumes (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        version TEXT NOT NULL DEFAULT 'v1.0',
        target_role TEXT,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        notes TEXT,
        is_primary INTEGER NOT NULL DEFAULT 0,
        parsed_data_json TEXT,
        extraction_status TEXT NOT NULL DEFAULT 'NOT_PARSED',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )''');

      // 3. Create v10 Jobs table
      raw.execute('''CREATE TABLE jobs (
        id TEXT NOT NULL PRIMARY KEY,
        title TEXT NOT NULL,
        company TEXT NOT NULL,
        location TEXT,
        salary TEXT,
        employment_type TEXT,
        experience_requirement TEXT,
        url TEXT,
        source TEXT,
        description TEXT,
        skills TEXT,
        posted_date INTEGER,
        discovered_at INTEGER NOT NULL,
        is_saved INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        ats_provider TEXT,
        raw_json TEXT,
        external_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )''');

      // 4. Create v10 Habits table
      raw.execute('''CREATE TABLE habits (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'check',
        color_value INTEGER NOT NULL DEFAULT 16738745,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )''');

      // 5. Create v10 BusinessLeads table
      raw.execute('''CREATE TABLE business_leads (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        industry TEXT,
        city TEXT,
        country TEXT NOT NULL DEFAULT 'India',
        turnover_inr REAL,
        turnover_evidence TEXT,
        turnover_source_url TEXT,
        website_url TEXT,
        web_presence TEXT NOT NULL DEFAULT 'NO_WEBSITE',
        presence_notes TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        links_json TEXT,
        sources_json TEXT,
        pitch TEXT,
        need_score INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'NEW',
        notes TEXT,
        discovered_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )''');

      // Insert mock data into v10
      raw.execute("INSERT INTO jobs (id, title, company, raw_json, discovered_at, created_at, updated_at) VALUES ('j1', 'Flutter Dev', 'Google', '{\"payload\": 123}', 1700000000, 1700000000, 1700000000)");
      raw.execute("INSERT INTO resumes (id, name, file_path, file_name, created_at, updated_at) VALUES ('r1', 'Main CV', '/cv.pdf', 'cv.pdf', 1700000000, 1700000000)");
      raw.execute("INSERT INTO habits (id, name, created_at) VALUES ('h1', 'LeetCode Daily', 1700000000)");
      raw.execute("INSERT INTO user_profiles (id, name, created_at, updated_at) VALUES ('u1', 'Risheesh Admin', 1700000000, 1700000000)");

      // Set user_version to 10
      raw.execute('PRAGMA user_version = 10');
    }));
    addTearDown(db.close);

    // Assert v11 schema upgrade
    expect(db.schemaVersion, equals(11));

    // 1. Verify jobs table migration & raw_json diet
    final j1 = await db.getJobById('j1');
    expect(j1, isNotNull);
    expect(j1!.title, equals('Flutter Dev'));
    expect(j1.rawJson, isNull, reason: 'raw_json must be cleared as part of the database diet');
    expect(j1.matchScore, isNull);
    expect(j1.matchTier, isNull);
    expect(j1.salaryMinInr, isNull);

    // 2. Verify UserProfiles v11 fields & RBAC
    final admin = await db.getProfileById('u1');
    expect(admin, isNotNull);
    expect(admin!.isAdmin, isFalse); // default false in migrated row
    expect(admin.status, equals('APPROVED'));
    expect(admin.permissions, equals('ALL'));
    expect(admin.expectedSalaryCurrency, equals('INR'));

    // 3. Verify Resumes v11 fields
    final resume = (await db.select(db.resumes).get()).first;
    expect(resume.jobId, isNull);
    expect(resume.latexSource, isNull);
    expect(resume.atsScore, isNull);

    // 4. Verify Habits v11 reminderTime field
    final habit = (await db.select(db.habits).get()).first;
    expect(habit.reminderTime, isNull);

    // 5. Verify New Tables exist and are usable
    expect(await db.select(db.fxRates).get(), isEmpty);
    expect(await db.select(db.notificationLogs).get(), isEmpty);
    expect(await db.select(db.aiUsages).get(), isEmpty);
    expect(await db.select(db.aiCaches).get(), isEmpty);

    // 6. Test Multi-Profile RBAC Registration & Notification
    await db.registerNewProfile(
      id: 'u2',
      name: 'John Applicant',
      email: 'john@example.com',
      currentRole: 'Backend Engineer',
    );

    final john = await db.getProfileById('u2');
    expect(john, isNotNull);
    expect(john!.isAdmin, isFalse);
    expect(john.status, equals('PENDING'));
    expect(john.permissions, equals(''));

    // Admin should have received an in-app notification about John
    final notifications = await db.getRecentNotifications();
    expect(notifications.length, equals(1));
    expect(notifications.first.notificationKey, equals('new_user_u2'));
    expect(notifications.first.channel, equals('admin_alerts'));
    expect(notifications.first.body, contains('John Applicant'));

    // Admin updates John's permissions
    await db.setProfilePermissions('u2', 'jobs,dsa');
    await db.setProfileStatus('u2', 'APPROVED');
    final updatedJohn = await db.getProfileById('u2');
    expect(updatedJohn!.permissions, equals('jobs,dsa'));
    expect(updatedJohn.status, equals('APPROVED'));

    // 7. Test FxRates & AiCache
    await db.saveFxRate('INR', '{"USD": 0.012}');
    final rate = await db.getLatestFxRate('INR');
    expect(rate, isNotNull);
    expect(rate!.ratesJson, contains('0.012'));

    await db.saveAiCache('key1', 'task_search', 'hash123', 'results_content', const Duration(hours: 24));
    final cached = await db.getCachedAiResponse('key1');
    expect(cached, equals('results_content'));

    // 8. Test watchJobPage and getJobTierCounts
    final tierCounts = await db.getJobTierCounts();
    expect(tierCounts['all'], equals(1));
    expect(tierCounts['strong'], equals(0));

    final page = await db.watchJobPage(limit: 10).first;
    expect(page.length, equals(1));
    expect(page.first.title, equals('Flutter Dev'));
  });
}
