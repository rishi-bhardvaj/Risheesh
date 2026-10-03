/**
 * Manual / local job sync. Uses the SAME JobSyncService as POST /api/v1/internal/jobs/sync.
 *
 *   npm run jobs:sync                      # full sync
 *   npm run jobs:sync -- --dry-run         # fetch + filter, write nothing
 *   npm run jobs:sync -- --providers=lever,ashby
 */
import { pool } from '../src/db';
import { JobSyncService } from '../src/modules/job-sync/job-sync.service';
import { redact } from '../src/utils/logger';

async function main(): Promise<number> {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');
  const providerArg = args.find((a) => a.startsWith('--providers='));
  const providers = providerArg ? providerArg.split('=')[1].split(',').map((s) => s.trim().toLowerCase()).filter(Boolean) : undefined;

  const service = new JobSyncService();
  const s = await service.run({ trigger: 'cli', dryRun, providers });

  console.log(`\nSync ${s.status}${dryRun ? ' (dry run - nothing written)' : ''}`);
  console.log(
    `  discovered=${s.jobsDiscovered} accepted=${s.jobsAccepted} inserted=${s.jobsInserted} updated=${s.jobsUpdated} ` +
      `deduplicated=${s.jobsDeduplicated} rejected=${s.jobsRejected} skipped=${s.jobsSkipped} stale=${s.jobsMarkedStale} closed=${s.jobsMarkedClosed}`
  );
  for (const p of s.providers) {
    console.log(`  - ${p.provider.padEnd(15)} ${p.status.padEnd(8)} discovered=${p.discovered} inserted=${p.inserted} rejected=${p.rejected} (${p.durationMs}ms)${p.errors[0] ? `  ! ${redact(p.errors[0])}` : ''}`);
  }
  if (Object.keys(s.rejectionReasons).length) console.log(`  rejection reasons: ${JSON.stringify(s.rejectionReasons)}`);

  return s.status === 'FAILED' ? 1 : 0;
}

main()
  .then(async (code) => {
    await pool.end();
    process.exit(code);
  })
  .catch(async (err) => {
    console.error('Sync failed:', redact(err));
    await pool.end().catch(() => undefined);
    process.exit(1);
  });
