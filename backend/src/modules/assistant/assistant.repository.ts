import { query } from '../../db';

export interface AssistantSummaryResult {
  period: {
    from: string;
    to: string;
  };
  jobs: {
    new: number;
    open: number;
    highMatch: number;
    saved: number;
  };
  freelance: {
    new: number;
    open: number;
    highMatch: number;
  };
  applications: {
    submitted: number;
    pending: number;
    needsFollowUp: number;
    responses: number;
  };
}

export class AssistantRepository {
  /**
   * Retrieves aggregated summary statistics across jobs, freelance leads,
   * and job applications for the given time window.
   */
  async getSummary(fromDate: Date, toDate: Date): Promise<AssistantSummaryResult> {
    const fromIso = fromDate.toISOString();
    const toIso = toDate.toISOString();

    // 1. Jobs summary
    const jobsSql = `
      SELECT
        COUNT(*) FILTER (
          WHERE COALESCE(posted_date, discovered_at) >= $1
            AND COALESCE(posted_date, discovered_at) <= $2
        )::int AS new_count,
        COUNT(*) FILTER (
          WHERE status = 'OPEN'
        )::int AS open_count,
        COUNT(*) FILTER (
          WHERE status = 'OPEN' AND match_score >= 80
        )::int AS high_match_count,
        COUNT(*) FILTER (
          WHERE is_saved = true
        )::int AS saved_count
      FROM jobs;
    `;
    const jobsRes = await query(jobsSql, [fromIso, toIso]);
    const jobRow = jobsRes.rows[0] || {};

    // 2. Freelance summary
    const freelanceSql = `
      SELECT
        COUNT(*) FILTER (
          WHERE created_at >= $1 AND created_at <= $2
        )::int AS new_count,
        COUNT(*) FILTER (
          WHERE status NOT IN ('LOST', 'ARCHIVED', 'REJECTED')
        )::int AS open_count,
        COUNT(*) FILTER (
          WHERE match_score >= 80
        )::int AS high_match_count
      FROM freelance_leads;
    `;
    const freelanceRes = await query(freelanceSql, [fromIso, toIso]);
    const freelanceRow = freelanceRes.rows[0] || {};

    // 3. Applications summary
    const appsSql = `
      SELECT
        COUNT(*) FILTER (
          WHERE applied_at >= $1 AND applied_at <= $2
        )::int AS submitted_count,
        COUNT(*) FILTER (
          WHERE LOWER(status) IN ('applied', 'reviewing', 'screening')
        )::int AS pending_count,
        COUNT(*) FILTER (
          WHERE follow_up_date IS NOT NULL
            AND follow_up_date <= NOW()
            AND LOWER(status) NOT IN ('rejected', 'offer', 'accepted')
        )::int AS needs_follow_up_count,
        COUNT(*) FILTER (
          WHERE LOWER(status) IN ('interviewing', 'offer', 'accepted')
        )::int AS responses_count
      FROM job_applications;
    `;
    const appsRes = await query(appsSql, [fromIso, toIso]);
    const appRow = appsRes.rows[0] || {};

    return {
      period: {
        from: fromIso,
        to: toIso,
      },
      jobs: {
        new: jobRow.new_count || 0,
        open: jobRow.open_count || 0,
        highMatch: jobRow.high_match_count || 0,
        saved: jobRow.saved_count || 0,
      },
      freelance: {
        new: freelanceRow.new_count || 0,
        open: freelanceRow.open_count || 0,
        highMatch: freelanceRow.high_match_count || 0,
      },
      applications: {
        submitted: appRow.submitted_count || 0,
        pending: appRow.pending_count || 0,
        needsFollowUp: appRow.needs_follow_up_count || 0,
        responses: appRow.responses_count || 0,
      },
    };
  }
}

export const assistantRepository = new AssistantRepository();
