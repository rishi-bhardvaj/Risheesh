import { query } from '../../db';

export interface CheckResult {
  name: string;
  ok: boolean;
  detail: string;
}

const REQUIRED_COLUMNS = ['canonical_url', 'dedupe_key', 'content_hash', 'last_seen_at', 'status', 'match_score', 'match_reason'];
const REQUIRED_INDEXES = [
  'uq_jobs_source_external_id',
  'uq_jobs_canonical_url',
  'uq_jobs_dedupe_key',
  'idx_jobs_status',
  'idx_jobs_last_seen_at',
  'idx_jobs_match_score',
];
const REQUIRED_TABLES = ['jobs', 'import_runs', 'job_sync_locks', 'schema_migrations'];
const REQUIRED_MIGRATION = '005_job_sync.sql';

/** Read-only schema/migration checks shared by `jobs:setup` and `jobs:verify`. */
export async function checkSchema(): Promise<CheckResult[]> {
  const out: CheckResult[] = [];

  const tables = await query<{ table_name: string }>(
    `SELECT table_name FROM information_schema.tables WHERE table_schema = current_schema() AND table_name = ANY($1::text[])`,
    [REQUIRED_TABLES]
  );
  const haveTables = new Set(tables.rows.map((r) => r.table_name));
  const missingTables = REQUIRED_TABLES.filter((t) => !haveTables.has(t));
  out.push({ name: 'tables', ok: missingTables.length === 0, detail: missingTables.length ? `missing: ${missingTables.join(', ')}` : REQUIRED_TABLES.join(', ') });

  const cols = await query<{ column_name: string }>(
    `SELECT column_name FROM information_schema.columns WHERE table_schema = current_schema() AND table_name = 'jobs'`
  );
  const haveCols = new Set(cols.rows.map((r) => r.column_name));
  const missingCols = REQUIRED_COLUMNS.filter((c) => !haveCols.has(c));
  out.push({ name: 'jobs columns', ok: missingCols.length === 0, detail: missingCols.length ? `missing: ${missingCols.join(', ')}` : 'all present' });

  const idx = await query<{ indexname: string }>(
    `SELECT indexname FROM pg_indexes WHERE schemaname = current_schema() AND tablename = 'jobs'`
  );
  const haveIdx = new Set(idx.rows.map((r) => r.indexname));
  const missingIdx = REQUIRED_INDEXES.filter((i) => !haveIdx.has(i));
  out.push({ name: 'indexes', ok: missingIdx.length === 0, detail: missingIdx.length ? `missing: ${missingIdx.join(', ')}` : 'all present' });

  let migrated = false;
  if (haveTables.has('schema_migrations')) {
    const m = await query('SELECT 1 FROM schema_migrations WHERE version = $1', [REQUIRED_MIGRATION]);
    migrated = (m.rowCount ?? 0) > 0;
  }
  out.push({ name: 'migrations', ok: migrated, detail: migrated ? `${REQUIRED_MIGRATION} applied` : `${REQUIRED_MIGRATION} not applied - run: npm run migrate` });

  return out;
}
