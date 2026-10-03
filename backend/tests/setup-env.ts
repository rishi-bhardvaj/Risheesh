// Deterministic, obviously-fake secret so tests never depend on (or leak) a real one.
process.env.JOB_SYNC_SECRET = 'test-only-job-sync-secret-0123456789';
