import 'package:career_os/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// A v8 install created before the `ats_provider` / resume-parsing columns
/// existed must upgrade cleanly; previously every Jobs query failed with
/// "no such column: ats_provider" on such devices.
void main() {
  test('v8 database without generated-only columns upgrades to v9', () async {
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('''CREATE TABLE user_profiles (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL,
        current_role TEXT, experience_years REAL NOT NULL DEFAULT 0.0, skills TEXT, programming_languages TEXT,
        frameworks TEXT, preferred_roles TEXT, preferred_locations TEXT, remote_preference TEXT NOT NULL DEFAULT 'any',
        expected_salary TEXT, preferred_employment_type TEXT, notice_period TEXT, education TEXT,
        resume_preferences TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
      raw.execute('''CREATE TABLE resumes (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL,
        version TEXT NOT NULL DEFAULT 'v1.0', target_role TEXT, file_path TEXT NOT NULL, file_name TEXT NOT NULL,
        notes TEXT, is_primary INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
      raw.execute('''CREATE TABLE jobs (id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, company TEXT NOT NULL,
        location TEXT, salary TEXT, employment_type TEXT, experience_requirement TEXT, url TEXT, source TEXT,
        description TEXT, skills TEXT, posted_date INTEGER, discovered_at INTEGER NOT NULL,
        is_saved INTEGER NOT NULL DEFAULT 0, notes TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''');
      raw.execute("INSERT INTO jobs (id, title, company, discovered_at, created_at, updated_at) VALUES ('old', 'Old Job', 'Acme', 0, 0, 0)");
      raw.execute("INSERT INTO resumes (id, name, file_path, file_name, created_at, updated_at) VALUES ('r1', 'CV', '/cv.pdf', 'cv.pdf', 0, 0)");
      raw.execute('PRAGMA user_version = 8');
    }));
    addTearDown(db.close);

    final jobs = await db.getAllJobs();
    expect(jobs.single.title, 'Old Job');
    expect(jobs.single.atsProvider, isNull);

    final resume = (await db.select(db.resumes).get()).single;
    expect(resume.extractionStatus, 'NOT_PARSED');
    expect(resume.isActive, isTrue);

    await db.upsertProfile(UserProfilesCompanion.insert(
      id: 'u',
      name: 'Me',
      email: const Value('me@example.com'),
      createdAt: Value(DateTime(2026)),
      updatedAt: Value(DateTime(2026)),
    ));
    expect((await db.getProfile())!.email, 'me@example.com');

    // New v9 tables exist.
    expect(await db.select(db.habits).get(), isEmpty);
    expect(await db.select(db.dailyReflections).get(), isEmpty);
  });
}
