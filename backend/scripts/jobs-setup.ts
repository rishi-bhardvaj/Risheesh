/**
 * Idempotent, non-destructive setup for the hourly job sync:
 *   1. creates backend/.env from .env.example if it does not exist
 *   2. generates a local JOB_SYNC_SECRET if missing (never printed, never in production)
 *   3. applies pending migrations
 *   4. verifies tables / columns / indexes and prints provider configuration
 *
 * Safe to run any number of times.
 */
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';

const backendDir = path.resolve(__dirname, '..');
const envPath = path.join(backendDir, '.env');
const examplePath = path.join(backendDir, '.env.example');

function ensureLocalEnv(): string[] {
  const notes: string[] = [];
  if (process.env.NODE_ENV === 'production') return ['production: skipping local .env management'];

  if (!fs.existsSync(envPath) && fs.existsSync(examplePath)) {
    fs.copyFileSync(examplePath, envPath);
    notes.push('created backend/.env from .env.example');
  }
  if (fs.existsSync(envPath)) {
    let text = fs.readFileSync(envPath, 'utf8');
    const line = /^JOB_SYNC_SECRET=(.*)$/m.exec(text);
    if (!line || line[1].trim().length < 24) {
      const secret = crypto.randomBytes(32).toString('hex');
      text = line ? text.replace(/^JOB_SYNC_SECRET=.*$/m, `JOB_SYNC_SECRET=${secret}`) : `${text.replace(/\s*$/, '\n')}JOB_SYNC_SECRET=${secret}\n`;
      fs.writeFileSync(envPath, text);
      notes.push('generated JOB_SYNC_SECRET in backend/.env (value not printed)');
    }
  }
  return notes;
}

async function main(): Promise<number> {
  let failed = false;
  const mark = (ok: boolean, label: string, detail = '') => {
    if (!ok) failed = true;
    console.log(`${ok ? '✓' : '✗'} ${label}${detail ? ` - ${detail}` : ''}`);
  };

  for (const n of ensureLocalEnv()) console.log(`• ${n}`);

  // Load config only after .env was possibly created/updated.
  const dotenv = await import('dotenv');
  dotenv.config({ path: envPath, override: true });

  if (!process.env.DATABASE_URL) {
    mark(false, 'DATABASE_URL', 'not set (backend/.env or environment)');
    return 1;
  }
  mark(true, 'DATABASE_URL', 'set');

  const { config } = await import('../src/config');
  const { pool, checkDatabaseConnection } = await import('../src/db');
  const { runMigrations } = await import('./run-migrations');
  const { checkSchema } = await import('../src/modules/job-sync/job-sync.health');
  const { loadJobSyncConfig } = await import('../src/modules/job-sync/job-sync.config');
  const { MIN_SECRET_LENGTH } = await import('../src/middleware/jobSyncAuth');

  mark(config.jobSyncSecret.length >= MIN_SECRET_LENGTH, 'JOB_SYNC_SECRET', `${config.jobSyncSecret.length >= MIN_SECRET_LENGTH ? 'configured' : `must be >= ${MIN_SECRET_LENGTH} chars`}`);

  const dbOk = await checkDatabaseConnection();
  mark(dbOk, 'database connection');
  if (!dbOk) {
    await pool.end().catch(() => undefined);
    return 1;
  }

  try {
    await runMigrations();
  } catch {
    mark(false, 'migrations', 'failed to apply (see error above)');
    await pool.end().catch(() => undefined);
    return 1;
  }

  for (const c of await checkSchema()) mark(c.ok, c.name, c.detail);

  const cfg = loadJobSyncConfig();
  mark(cfg.enabledProviders.length > 0, 'providers', cfg.enabledProviders.join(', ') || 'none enabled');
  console.log(
    `  boards: greenhouse=${cfg.greenhouseBoards.length} lever=${cfg.leverOrgs.length} ashby=${cfg.ashbyOrgs.length} | ` +
      `min score=${cfg.minMatchScore}, max years=${cfg.profile.maxYearsExperience}, stale after ${cfg.staleAfterHours}h`
  );

  console.log(failed ? '\nSetup finished with problems (see ✗ above).' : '\nSetup OK. Next: npm run jobs:verify  then  npm run jobs:sync');
  await pool.end().catch(() => undefined);
  return failed ? 1 : 0;
}

main().then((code) => process.exit(code)).catch((err) => {
  console.error('Setup failed:', err instanceof Error ? err.message : err);
  process.exit(1);
});
