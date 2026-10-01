import path from 'path';
import fs from 'fs';
import Database from 'better-sqlite3';
import { Pool } from 'pg';
import dotenv from 'dotenv';
import { v4 as uuidv4 } from 'uuid';

dotenv.config({ path: path.resolve(__dirname, '../.env') });

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  console.error('Error: DATABASE_URL is not defined.');
  process.exit(1);
}

const pool = new Pool({ connectionString });

function findDefaultSqliteDb(): string | null {
  // Common locations where Flutter / Drift stores SQLite files on Windows / Linux / macOS
  const candidates = [
    path.resolve(process.env.APPDATA || '', 'com.risheesh.career_os/app_database.sqlite'),
    path.resolve(process.env.APPDATA || '', 'career_os/app_database.sqlite'),
    path.resolve(process.env.LOCALAPPDATA || '', 'career_os/app_database.sqlite'),
    path.resolve(process.cwd(), '../app_database.sqlite'),
    path.resolve(process.cwd(), 'app_database.sqlite'),
  ];

  for (const p of candidates) {
    if (fs.existsSync(p)) return p;
  }
  return null;
}

export async function migrateSqliteToPostgres(sqlitePath: string): Promise<void> {
  console.log(`Starting migration from SQLite database: ${sqlitePath}`);

  if (!fs.existsSync(sqlitePath)) {
    throw new Error(`SQLite database file not found at: ${sqlitePath}`);
  }

  const sqlite = new Database(sqlitePath, { readonly: true });
  const client = await pool.connect();

  let usersMigrated = 0;
  let jobsMigrated = 0;
  let applicationsMigrated = 0;
  let leadsMigrated = 0;
  let clientsMigrated = 0;
  let projectsMigrated = 0;
  let paymentsMigrated = 0;
  let errors = 0;

  try {
    await client.query('BEGIN');

    // Helper to check if a table exists in SQLite
    const hasTable = (tableName: string): boolean => {
      const row = sqlite
        .prepare("SELECT name FROM sqlite_master WHERE type='table' AND name=?")
        .get(tableName);
      return !!row;
    };

    // 1. Migrate Clients (needed before leads and projects for FKs)
    if (hasTable('clients')) {
      const rows = sqlite.prepare('SELECT * FROM clients').all() as any[];
      for (const r of rows) {
        try {
          const id = r.id || uuidv4();
          await client.query(
            `INSERT INTO clients (id, name, contact_name, email, phone, platform, location, status, notes, created_at, updated_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, COALESCE($10, NOW()), COALESCE($11, NOW()))
             ON CONFLICT (id) DO UPDATE SET
               name = EXCLUDED.name,
               contact_name = EXCLUDED.contact_name,
               email = EXCLUDED.email,
               status = EXCLUDED.status,
               updated_at = NOW()`,
            [
              id,
              r.name,
              r.contact_name || null,
              r.email || null,
              r.phone || null,
              r.platform || null,
              r.location || null,
              r.status || 'PROSPECT',
              r.notes || null,
              r.created_at ? new Date(r.created_at) : null,
              r.updated_at ? new Date(r.updated_at) : null,
            ]
          );
          clientsMigrated++;
        } catch (e) {
          errors++;
          console.error(`Error migrating client ${r.id}:`, e);
        }
      }
    }

    // 2. Migrate FreelanceLeads
    if (hasTable('freelance_leads')) {
      const rows = sqlite.prepare('SELECT * FROM freelance_leads').all() as any[];
      for (const r of rows) {
        try {
          const id = r.id || uuidv4();
          const skillsJson = r.skills
            ? JSON.stringify(r.skills.split(',').map((s: string) => s.trim()))
            : '[]';

          await client.query(
            `INSERT INTO freelance_leads (
              id, external_id, client_id, project_id, title, client_name,
              contact_name, contact_info, platform, description, skills,
              budget, currency, url, status, proposal, deadline,
              follow_up_date, follow_up_note, next_action, notes, lead_date,
              created_at, updated_at
            ) VALUES (
              $1, $2, $3, $4, $5, $6,
              $7, $8, $9, $10, $11::jsonb,
              $12, $13, $14, $15, $16, $17,
              $18, $19, $20, $21, $22,
              COALESCE($23, NOW()), COALESCE($24, NOW())
            ) ON CONFLICT (id) DO NOTHING`,
            [
              id,
              r.external_id || null,
              r.client_id || null,
              r.project_id || null,
              r.title,
              r.client_name || null,
              r.contact_name || null,
              r.contact_info || null,
              r.platform || 'Direct',
              r.description || null,
              skillsJson,
              r.budget || null,
              r.currency || 'USD',
              r.url || null,
              r.status || 'NEW_LEAD',
              r.proposal || null,
              r.deadline ? new Date(r.deadline) : null,
              r.follow_up_date ? new Date(r.follow_up_date) : null,
              r.follow_up_note || null,
              r.next_action || null,
              r.notes || null,
              r.lead_date ? new Date(r.lead_date) : null,
              r.created_at ? new Date(r.created_at) : null,
              r.updated_at ? new Date(r.updated_at) : null,
            ]
          );
          leadsMigrated++;
        } catch (e) {
          errors++;
          console.error(`Error migrating lead ${r.id}:`, e);
        }
      }
    }

    // 3. Migrate Projects
    if (hasTable('projects')) {
      const rows = sqlite.prepare('SELECT * FROM projects').all() as any[];
      for (const r of rows) {
        try {
          const id = r.id || uuidv4();
          await client.query(
            `INSERT INTO projects (
              id, name, description, status, progress, tech_stack,
              github_url, live_url, deadline, notes, client_id, lead_id,
              is_freelance, created_at, updated_at
            ) VALUES (
              $1, $2, $3, $4, $5, $6,
              $7, $8, $9, $10, $11, $12,
              $13, COALESCE($14, NOW()), COALESCE($15, NOW())
            ) ON CONFLICT (id) DO NOTHING`,
            [
              id,
              r.name,
              r.description || null,
              r.status || 'in_progress',
              r.progress || 0.0,
              r.tech_stack || null,
              r.github_url || null,
              r.live_url || null,
              r.deadline ? new Date(r.deadline) : null,
              r.notes || null,
              r.client_id || null,
              r.lead_id || null,
              r.is_freelance === 1 || r.is_freelance === true,
              r.created_at ? new Date(r.created_at) : null,
              r.updated_at ? new Date(r.updated_at) : null,
            ]
          );
          projectsMigrated++;
        } catch (e) {
          errors++;
          console.error(`Error migrating project ${r.id}:`, e);
        }
      }
    }

    // 4. Migrate FreelancePayments
    if (hasTable('freelance_payments')) {
      const rows = sqlite.prepare('SELECT * FROM freelance_payments').all() as any[];
      for (const r of rows) {
        try {
          const id = r.id || uuidv4();
          await client.query(
            `INSERT INTO freelance_payments (
              id, client_id, project_id, amount, currency, payment_date,
              status, description, notes, created_at, updated_at
            ) VALUES (
              $1, $2, $3, $4, $5, COALESCE($6, NOW()),
              $7, $8, $9, COALESCE($10, NOW()), COALESCE($11, NOW())
            ) ON CONFLICT (id) DO NOTHING`,
            [
              id,
              r.client_id,
              r.project_id || null,
              r.amount,
              r.currency || 'USD',
              r.payment_date ? new Date(r.payment_date) : null,
              r.status || 'EXPECTED',
              r.description || null,
              r.notes || null,
              r.created_at ? new Date(r.created_at) : null,
              r.updated_at ? new Date(r.updated_at) : null,
            ]
          );
          paymentsMigrated++;
        } catch (e) {
          errors++;
          console.error(`Error migrating payment ${r.id}:`, e);
        }
      }
    }

    // 5. Migrate Jobs
    if (hasTable('jobs')) {
      const rows = sqlite.prepare('SELECT * FROM jobs').all() as any[];
      for (const r of rows) {
        try {
          const id = r.id || uuidv4();
          const skillsJson = r.skills
            ? JSON.stringify(r.skills.split(',').map((s: string) => s.trim()))
            : '[]';

          await client.query(
            `INSERT INTO jobs (
              id, external_id, title, company, location, salary, employment_type,
              experience_requirement, url, source, description, skills,
              posted_date, discovered_at, match_score, match_reason, is_saved, notes,
              created_at, updated_at
            ) VALUES (
              $1, $2, $3, $4, $5, $6, $7,
              $8, $9, $10, $11, $12::jsonb,
              $13, COALESCE($14, NOW()), $15, $16, $17, $18,
              COALESCE($19, NOW()), COALESCE($20, NOW())
            ) ON CONFLICT (id) DO NOTHING`,
            [
              id,
              r.external_id || null,
              r.title,
              r.company,
              r.location || null,
              r.salary || null,
              r.employment_type || null,
              r.experience_requirement || null,
              r.url || null,
              r.source || 'Manual',
              r.description || null,
              skillsJson,
              r.posted_date ? new Date(r.posted_date) : null,
              r.discovered_at ? new Date(r.discovered_at) : null,
              r.match_score || null,
              r.match_reason || null,
              r.is_saved === 1 || r.is_saved === true,
              r.notes || null,
              r.created_at ? new Date(r.created_at) : null,
              r.updated_at ? new Date(r.updated_at) : null,
            ]
          );
          jobsMigrated++;
        } catch (e) {
          errors++;
          console.error(`Error migrating job ${r.id}:`, e);
        }
      }
    }

    // 6. Migrate JobApplications
    if (hasTable('job_applications')) {
      const rows = sqlite.prepare('SELECT * FROM job_applications').all() as any[];
      for (const r of rows) {
        try {
          const id = r.id || uuidv4();
          await client.query(
            `INSERT INTO job_applications (
              id, job_id, company, role, salary, location, url,
              status, applied_at, follow_up_date, interview_date, interview_stage,
              recruiter_name, recruiter_contact, resume_id, resume_used,
              cover_letter_reference, next_action, notes, created_at, updated_at
            ) VALUES (
              $1, $2, $3, $4, $5, $6, $7,
              $8, $9, $10, $11, $12,
              $13, $14, $15, $16,
              $17, $18, $19, COALESCE($20, NOW()), COALESCE($21, NOW())
            ) ON CONFLICT (id) DO NOTHING`,
            [
              id,
              r.job_id || null,
              r.company,
              r.role,
              r.salary || null,
              r.location || null,
              r.url || null,
              r.status || 'applied',
              r.applied_at ? new Date(r.applied_at) : null,
              r.follow_up_date ? new Date(r.follow_up_date) : null,
              r.interview_date ? new Date(r.interview_date) : null,
              r.interview_stage || null,
              r.recruiter_name || null,
              r.recruiter_contact || null,
              r.resume_id || null,
              r.resume_used || null,
              r.cover_letter_reference || null,
              r.next_action || null,
              r.notes || null,
              r.created_at ? new Date(r.created_at) : null,
              r.updated_at ? new Date(r.updated_at) : null,
            ]
          );
          applicationsMigrated++;
        } catch (e) {
          errors++;
          console.error(`Error migrating application ${r.id}:`, e);
        }
      }
    }

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    sqlite.close();
    client.release();
  }

  console.log('\nMigration Summary:');
  console.log('---------------------------------');
  console.log(`Users migrated: ${usersMigrated}`);
  console.log(`Jobs migrated: ${jobsMigrated}`);
  console.log(`Applications migrated: ${applicationsMigrated}`);
  console.log(`Freelance leads migrated: ${leadsMigrated}`);
  console.log(`Clients migrated: ${clientsMigrated}`);
  console.log(`Projects migrated: ${projectsMigrated}`);
  console.log(`Payments migrated: ${paymentsMigrated}`);
  console.log(`Errors: ${errors}`);
  console.log('---------------------------------');
}

async function main() {
  const customPath = process.argv[2];
  const dbPath = customPath || findDefaultSqliteDb();

  if (!dbPath) {
    console.log('No SQLite database file specified or detected.');
    console.log('Usage: tsx scripts/migrate_sqlite_to_postgres.ts <path-to-sqlite-db>');
    console.log('\nMigration Summary (dry-run):');
    console.log('---------------------------------');
    console.log('Users migrated: 0');
    console.log('Jobs migrated: 0');
    console.log('Applications migrated: 0');
    console.log('Freelance leads migrated: 0');
    console.log('Clients migrated: 0');
    console.log('Projects migrated: 0');
    console.log('Payments migrated: 0');
    console.log('Errors: 0');
    console.log('---------------------------------');
    await pool.end();
    return;
  }

  try {
    await migrateSqliteToPostgres(dbPath);
  } finally {
    await pool.end();
  }
}

if (require.main === module) {
  main().catch((err) => {
    console.error('Fatal error during SQLite migration:', err);
    process.exit(1);
  });
}
