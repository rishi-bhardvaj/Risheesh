import { getClient, query } from '../../db';
import { v4 as uuidv4 } from 'uuid';
import {
  jobsImportBatchSchema,
  jobImportItemSchema,
  freelanceImportBatchSchema,
  freelanceImportItemSchema,
  JobImportItem,
  FreelanceImportItem,
} from './import.schema';
import { normalizeUrl, normalizeText } from '../../utils/normalizer';
import { ValidationError } from '../../utils/errors';

export interface ImportStats {
  run_id: string;
  data_type: string;
  source: string;
  received: number;
  inserted: number;
  updated: number;
  duplicates: number;
  rejected: number;
  rejection_details: Array<{ index: number; error: string }>;
}

export class ImportService {
  async importJobs(payload: any): Promise<ImportStats> {
    // 1. Validate batch envelope
    const parsedBatch = jobsImportBatchSchema.safeParse(payload);
    if (!parsedBatch.success) {
      throw new ValidationError(
        'Invalid jobs batch payload',
        parsedBatch.error.errors.map((e) => ({ path: e.path.join('.'), message: e.message }))
      );
    }

    const { jobs: rawJobs, source } = parsedBatch.data;
    const runId = uuidv4();
    const client = await getClient();

    let inserted = 0;
    let updated = 0;
    let duplicates = 0;
    let rejected = 0;
    const rejectionDetails: Array<{ index: number; error: string }> = [];

    try {
      await client.query('BEGIN');

      // Record import run start
      await client.query(
        `INSERT INTO import_runs (id, data_type, source, received_count, status)
         VALUES ($1, 'jobs', $2, $3, 'IN_PROGRESS')`,
        [runId, source, rawJobs.length]
      );

      for (let i = 0; i < rawJobs.length; i++) {
        const itemResult = jobImportItemSchema.safeParse(rawJobs[i]);
        if (!itemResult.success) {
          rejected++;
          rejectionDetails.push({
            index: i,
            error: itemResult.error.errors.map((e) => e.message).join('; '),
          });
          continue;
        }

        const job: JobImportItem = itemResult.data;
        const normUrl = normalizeUrl(job.url);
        const extId = job.external_id?.trim() || null;
        const normTitle = normalizeText(job.title);

        // Deduplication lookup
        let existingJob: any = null;

        if (extId) {
          const res = await client.query(
            `SELECT id, title, company, location, salary, employment_type, experience_requirement, url, description, skills, match_score, match_reason
             FROM jobs WHERE source = $1 AND external_id = $2 LIMIT 1`,
            [job.source, extId]
          );
          if (res.rows.length > 0) existingJob = res.rows[0];
        }

        if (!existingJob && normUrl) {
          const res = await client.query(
            `SELECT id, title, company, location, salary, employment_type, experience_requirement, url, description, skills, match_score, match_reason
             FROM jobs WHERE source = $1 AND url = $2 LIMIT 1`,
            [job.source, normUrl]
          );
          if (res.rows.length > 0) existingJob = res.rows[0];
        }

        if (!existingJob) {
          const res = await client.query(
            `SELECT id, title, company, location, salary, employment_type, experience_requirement, url, description, skills, match_score, match_reason
             FROM jobs WHERE source = $1 AND LOWER(TRIM(company)) = LOWER(TRIM($2)) AND LOWER(TRIM(title)) = LOWER(TRIM($3)) LIMIT 1`,
            [job.source, job.company, job.title]
          );
          if (res.rows.length > 0) existingJob = res.rows[0];
        }

        const rawDataJson = JSON.stringify(rawJobs[i]);
        const skillsJson = JSON.stringify(job.skills || []);
        const metadataJson = JSON.stringify(job.metadata || {});

        if (!existingJob) {
          // Insert new job record
          const newId = uuidv4();
          await client.query(
            `INSERT INTO jobs (
              id, external_id, title, company, location, salary, employment_type,
              experience_requirement, url, source, description, skills,
              posted_date, discovered_at, match_score, match_reason, is_saved,
              metadata, raw_data, created_at, updated_at
            ) VALUES (
              $1, $2, $3, $4, $5, $6, $7,
              $8, $9, $10, $11, $12::jsonb,
              $13, $14, $15, $16, FALSE,
              $17::jsonb, $18::jsonb, NOW(), NOW()
            )`,
            [
              newId,
              extId,
              job.title.trim(),
              job.company.trim(),
              job.location?.trim() || null,
              job.salary?.trim() || null,
              job.employment_type?.trim() || null,
              job.experience_requirement?.trim() || null,
              normUrl,
              job.source.trim(),
              job.description?.trim() || null,
              skillsJson,
              job.posted_date ? new Date(job.posted_date) : null,
              job.discovered_at ? new Date(job.discovered_at) : new Date(),
              job.match_score ?? null,
              job.match_reason || null,
              metadataJson,
              rawDataJson,
            ]
          );
          inserted++;
        } else {
          // Check if incoming research fields changed
          const isIdentical =
            existingJob.title === job.title.trim() &&
            existingJob.company === job.company.trim() &&
            (existingJob.location || null) === (job.location?.trim() || null) &&
            (existingJob.salary || null) === (job.salary?.trim() || null) &&
            (existingJob.description || null) === (job.description?.trim() || null);

          if (isIdentical) {
            duplicates++;
          } else {
            // Update research fields ONLY, preserve user fields (is_saved, notes)
            await client.query(
              `UPDATE jobs SET
                title = $1,
                company = $2,
                location = $3,
                salary = $4,
                employment_type = $5,
                experience_requirement = $6,
                url = $7,
                description = $8,
                skills = $9::jsonb,
                posted_date = COALESCE($10, posted_date),
                match_score = COALESCE($11, match_score),
                match_reason = COALESCE($12, match_reason),
                metadata = $13::jsonb,
                raw_data = $14::jsonb,
                updated_at = NOW()
              WHERE id = $15`,
              [
                job.title.trim(),
                job.company.trim(),
                job.location?.trim() || null,
                job.salary?.trim() || null,
                job.employment_type?.trim() || null,
                job.experience_requirement?.trim() || null,
                normUrl,
                job.description?.trim() || null,
                skillsJson,
                job.posted_date ? new Date(job.posted_date) : null,
                job.match_score ?? null,
                job.match_reason || null,
                metadataJson,
                rawDataJson,
                existingJob.id,
              ]
            );
            updated++;
          }
        }
      }

      // Update import_runs completion
      const finalStatus = rejected > 0 ? (inserted + updated > 0 ? 'PARTIAL' : 'FAILED') : 'SUCCESS';
      await client.query(
        `UPDATE import_runs SET
          completed_at = NOW(),
          inserted_count = $1,
          updated_count = $2,
          duplicate_count = $3,
          rejected_count = $4,
          status = $5,
          metadata = $6::jsonb
        WHERE id = $7`,
        [
          inserted,
          updated,
          duplicates,
          rejected,
          finalStatus,
          JSON.stringify({ rejection_details: rejectionDetails }),
          runId,
        ]
      );

      await client.query('COMMIT');

      return {
        run_id: runId,
        data_type: 'jobs',
        source,
        received: rawJobs.length,
        inserted,
        updated,
        duplicates,
        rejected,
        rejection_details: rejectionDetails,
      };
    } catch (err: any) {
      await client.query('ROLLBACK');
      await query(
        `UPDATE import_runs SET
          completed_at = NOW(),
          status = 'FAILED',
          error_message = $1
        WHERE id = $2`,
        [err.message || 'Unknown error', runId]
      ).catch(() => {});
      throw err;
    } finally {
      client.release();
    }
  }

  async importFreelance(payload: any): Promise<ImportStats> {
    // 1. Validate freelance batch envelope
    const parsedBatch = freelanceImportBatchSchema.safeParse(payload);
    if (!parsedBatch.success) {
      throw new ValidationError(
        'Invalid freelance batch payload',
        parsedBatch.error.errors.map((e) => ({ path: e.path.join('.'), message: e.message }))
      );
    }

    const { projects: rawProjects, source } = parsedBatch.data;
    const runId = uuidv4();
    const client = await getClient();

    let inserted = 0;
    let updated = 0;
    let duplicates = 0;
    let rejected = 0;
    const rejectionDetails: Array<{ index: number; error: string }> = [];

    try {
      await client.query('BEGIN');

      await client.query(
        `INSERT INTO import_runs (id, data_type, source, received_count, status)
         VALUES ($1, 'freelance', $2, $3, 'IN_PROGRESS')`,
        [runId, source, rawProjects.length]
      );

      for (let i = 0; i < rawProjects.length; i++) {
        const itemResult = freelanceImportItemSchema.safeParse(rawProjects[i]);
        if (!itemResult.success) {
          rejected++;
          rejectionDetails.push({
            index: i,
            error: itemResult.error.errors.map((e) => e.message).join('; '),
          });
          continue;
        }

        const proj: FreelanceImportItem = itemResult.data;
        const normUrl = normalizeUrl(proj.url);
        const extId = proj.external_id?.trim() || null;

        // Deduplication lookup
        let existingLead: any = null;

        if (extId) {
          const res = await client.query(
            `SELECT id, title, client_name, platform, description, budget, currency, url, match_score, match_reason
             FROM freelance_leads WHERE platform = $1 AND external_id = $2 LIMIT 1`,
            [proj.platform, extId]
          );
          if (res.rows.length > 0) existingLead = res.rows[0];
        }

        if (!existingLead && normUrl) {
          const res = await client.query(
            `SELECT id, title, client_name, platform, description, budget, currency, url, match_score, match_reason
             FROM freelance_leads WHERE platform = $1 AND url = $2 LIMIT 1`,
            [proj.platform, normUrl]
          );
          if (res.rows.length > 0) existingLead = res.rows[0];
        }

        if (!existingLead && proj.client_name) {
          const res = await client.query(
            `SELECT id, title, client_name, platform, description, budget, currency, url, match_score, match_reason
             FROM freelance_leads WHERE platform = $1 AND LOWER(TRIM(client_name)) = LOWER(TRIM($2)) AND LOWER(TRIM(title)) = LOWER(TRIM($3)) LIMIT 1`,
            [proj.platform, proj.client_name, proj.title]
          );
          if (res.rows.length > 0) existingLead = res.rows[0];
        }

        const rawDataJson = JSON.stringify(rawProjects[i]);
        const skillsJson = JSON.stringify(proj.skills || []);
        const metadataJson = JSON.stringify(proj.metadata || {});

        if (!existingLead) {
          const newId = uuidv4();
          await client.query(
            `INSERT INTO freelance_leads (
              id, external_id, title, client_name, contact_name, contact_info,
              platform, description, skills, budget, currency, url,
              status, proposal, deadline, follow_up_date, follow_up_note,
              next_action, notes, lead_date, match_score, match_reason,
              metadata, raw_data, created_at, updated_at
            ) VALUES (
              $1, $2, $3, $4, NULL, $5,
              $6, $7, $8::jsonb, $9, $10, $11,
              'NEW_LEAD', NULL, $12, NULL, NULL,
              NULL, NULL, $13, $14, $15,
              $16::jsonb, $17::jsonb, NOW(), NOW()
            )`,
            [
              newId,
              extId,
              proj.title.trim(),
              proj.client_name?.trim() || null,
              proj.contact_info?.trim() || null,
              proj.platform.trim(),
              proj.description?.trim() || null,
              skillsJson,
              proj.budget ?? null,
              proj.currency || 'USD',
              normUrl,
              proj.deadline ? new Date(proj.deadline) : null,
              proj.posted_date ? new Date(proj.posted_date) : new Date(),
              proj.match_score ?? null,
              proj.match_reason || null,
              metadataJson,
              rawDataJson,
            ]
          );
          inserted++;
        } else {
          // Check if identical
          const isIdentical =
            existingLead.title === proj.title.trim() &&
            (existingLead.client_name || null) === (proj.client_name?.trim() || null) &&
            (existingLead.description || null) === (proj.description?.trim() || null) &&
            Number(existingLead.budget || 0) === Number(proj.budget || 0);

          if (isIdentical) {
            duplicates++;
          } else {
            // Update research fields ONLY, preserve user-managed lifecycle fields:
            // (status, proposal, deadline, follow_up_date, follow_up_note, next_action, notes, client_id, project_id)
            await client.query(
              `UPDATE freelance_leads SET
                title = $1,
                client_name = $2,
                contact_info = COALESCE($3, contact_info),
                platform = $4,
                description = $5,
                skills = $6::jsonb,
                budget = COALESCE($7, budget),
                currency = COALESCE($8, currency),
                url = $9,
                match_score = COALESCE($10, match_score),
                match_reason = COALESCE($11, match_reason),
                metadata = $12::jsonb,
                raw_data = $13::jsonb,
                updated_at = NOW()
              WHERE id = $14`,
              [
                proj.title.trim(),
                proj.client_name?.trim() || null,
                proj.contact_info?.trim() || null,
                proj.platform.trim(),
                proj.description?.trim() || null,
                skillsJson,
                proj.budget ?? null,
                proj.currency || 'USD',
                normUrl,
                proj.match_score ?? null,
                proj.match_reason || null,
                metadataJson,
                rawDataJson,
                existingLead.id,
              ]
            );
            updated++;
          }
        }
      }

      const finalStatus = rejected > 0 ? (inserted + updated > 0 ? 'PARTIAL' : 'FAILED') : 'SUCCESS';
      await client.query(
        `UPDATE import_runs SET
          completed_at = NOW(),
          inserted_count = $1,
          updated_count = $2,
          duplicate_count = $3,
          rejected_count = $4,
          status = $5,
          metadata = $6::jsonb
        WHERE id = $7`,
        [
          inserted,
          updated,
          duplicates,
          rejected,
          finalStatus,
          JSON.stringify({ rejection_details: rejectionDetails }),
          runId,
        ]
      );

      await client.query('COMMIT');

      return {
        run_id: runId,
        data_type: 'freelance',
        source,
        received: rawProjects.length,
        inserted,
        updated,
        duplicates,
        rejected,
        rejection_details: rejectionDetails,
      };
    } catch (err: any) {
      await client.query('ROLLBACK');
      await query(
        `UPDATE import_runs SET
          completed_at = NOW(),
          status = 'FAILED',
          error_message = $1
        WHERE id = $2`,
        [err.message || 'Unknown error', runId]
      ).catch(() => {});
      throw err;
    } finally {
      client.release();
    }
  }

  async getImportRuns(limit = 20) {
    const res = await query(
      `SELECT * FROM import_runs ORDER BY created_at DESC LIMIT $1`,
      [limit]
    );
    return res.rows;
  }
}

export const importService = new ImportService();
