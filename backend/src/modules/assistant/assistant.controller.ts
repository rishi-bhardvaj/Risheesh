import { NextFunction, Request, Response } from 'express';
import { checkDatabaseConnection } from '../../db';
import { jobsRepository } from '../jobs/jobs.repository';
import { freelanceRepository } from '../freelance/freelance.repository';
import { applicationsRepository } from '../applications/applications.repository';
import { assistantRepository } from './assistant.repository';
import {
  parseDateParam,
  queryAssistantJobsSchema,
  queryAssistantFreelanceSchema,
  queryAssistantApplicationsSchema,
  queryAssistantSummarySchema,
} from './assistant.schema';

export class AssistantController {
  /**
   * Connectivity & Auth verification endpoint
   */
  async getHealth(_req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const dbConnected = await checkDatabaseConnection();
      res.status(200).json({
        success: true,
        generatedAt: new Date().toISOString(),
        status: dbConnected ? 'ok' : 'degraded',
        database: dbConnected ? 'connected' : 'disconnected',
        access: 'read_only',
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * Read-only jobs endpoint for ChatGPT personal assistant routines
   */
  async getJobs(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const parsed = queryAssistantJobsSchema.parse(req.query);
      const fromDate = parseDateParam(parsed.since);
      const postedAfter = fromDate ? fromDate.toISOString() : undefined;

      const result = await jobsRepository.findMany({
        page: parsed.page,
        limit: parsed.limit,
        search: parsed.search,
        location: parsed.location,
        remote: parsed.remote,
        source: parsed.source,
        status: parsed.status,
        min_score: parsed.min_score,
        posted_after: postedAfter,
        sort: parsed.sort,
      });

      const sanitizedJobs = result.items.map((row: any) => {
        const isRemote =
          (typeof row.location === 'string' && /remote/i.test(row.location)) ||
          (typeof row.employment_type === 'string' && /remote/i.test(row.employment_type)) ||
          Boolean(row.metadata?.isRemote);

        return {
          id: row.id,
          externalId: row.external_id || null,
          title: row.title,
          company: row.company,
          location: row.location || null,
          remote: isRemote,
          employmentType: row.employment_type || null,
          experienceRequirement: row.experience_requirement || null,
          salary: row.salary || null,
          source: row.source || null,
          url: row.url || null,
          postedDate: row.posted_date || null,
          discoveredAt: row.discovered_at || null,
          matchScore: row.match_score !== null && row.match_score !== undefined ? Number(row.match_score) : null,
          matchReason: row.match_reason || null,
          skills: Array.isArray(row.skills) ? row.skills : [],
          status: row.status || 'OPEN',
        };
      });

      res.status(200).json({
        success: true,
        generatedAt: new Date().toISOString(),
        filters: {
          status: parsed.status,
          since: fromDate ? fromDate.toISOString() : null,
          limit: parsed.limit,
          minScore: parsed.min_score ?? null,
        },
        stats: {
          returned: sanitizedJobs.length,
          totalMatching: result.pagination.total,
        },
        pagination: result.pagination,
        jobs: sanitizedJobs,
        data: sanitizedJobs,
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * Read-only freelance leads endpoint for ChatGPT personal assistant routines
   */
  async getFreelance(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const parsed = queryAssistantFreelanceSchema.parse(req.query);
      const fromDate = parseDateParam(parsed.since);
      const createdAfter = fromDate ? fromDate.toISOString() : undefined;

      const result = await freelanceRepository.findMany({
        page: parsed.page,
        limit: parsed.limit,
        search: parsed.search,
        platform: parsed.platform,
        status: parsed.status,
        min_score: parsed.min_score,
        created_after: createdAfter,
        sort: parsed.sort,
      });

      const sanitizedLeads = result.items.map((row: any) => ({
        id: row.id,
        externalId: row.external_id || null,
        title: row.title,
        clientName: row.client_name || null,
        contactName: row.contact_name || null,
        platform: row.platform || null,
        description: row.description || null,
        skills: Array.isArray(row.skills) ? row.skills : [],
        budget: row.budget !== null && row.budget !== undefined ? Number(row.budget) : null,
        currency: row.currency || 'USD',
        url: row.url || null,
        status: row.status || 'NEW_LEAD',
        proposal: row.proposal || null,
        deadline: row.deadline || null,
        leadDate: row.lead_date || null,
        matchScore: row.match_score !== null && row.match_score !== undefined ? Number(row.match_score) : null,
        matchReason: row.match_reason || null,
        followUpDate: row.follow_up_date || null,
        nextAction: row.next_action || null,
      }));

      res.status(200).json({
        success: true,
        generatedAt: new Date().toISOString(),
        filters: {
          status: parsed.status || null,
          platform: parsed.platform || null,
          since: fromDate ? fromDate.toISOString() : null,
          limit: parsed.limit,
        },
        stats: {
          returned: sanitizedLeads.length,
          totalMatching: result.pagination.total,
        },
        pagination: result.pagination,
        leads: sanitizedLeads,
        data: sanitizedLeads,
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * Read-only job applications endpoint for ChatGPT personal assistant routines
   */
  async getApplications(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const parsed = queryAssistantApplicationsSchema.parse(req.query);
      const fromDate = parseDateParam(parsed.since);
      const appliedAfter = fromDate ? fromDate.toISOString() : undefined;

      const result = await applicationsRepository.findMany({
        page: parsed.page,
        limit: parsed.limit,
        search: parsed.search,
        status: parsed.status,
        applied_after: appliedAfter,
        sort: parsed.sort,
      });

      const sanitizedApps = result.items.map((row: any) => ({
        id: row.id,
        jobId: row.job_id || null,
        company: row.company,
        role: row.role,
        salary: row.salary || null,
        location: row.location || null,
        url: row.url || null,
        status: row.status || 'applied',
        appliedAt: row.applied_at || null,
        followUpDate: row.follow_up_date || null,
        interviewDate: row.interview_date || null,
        interviewStage: row.interview_stage || null,
        recruiterName: row.recruiter_name || null,
        nextAction: row.next_action || null,
        notes: row.notes || null,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      }));

      res.status(200).json({
        success: true,
        generatedAt: new Date().toISOString(),
        filters: {
          status: parsed.status || null,
          since: fromDate ? fromDate.toISOString() : null,
          limit: parsed.limit,
        },
        stats: {
          returned: sanitizedApps.length,
          totalMatching: result.pagination.total,
        },
        pagination: result.pagination,
        applications: sanitizedApps,
        data: sanitizedApps,
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * Aggregate statistics across jobs, freelance leads, and applications
   */
  async getSummary(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const parsed = queryAssistantSummarySchema.parse(req.query);
      const fromDate = parseDateParam(parsed.since) || new Date(Date.now() - 24 * 3600 * 1000);
      const toDate = parseDateParam(parsed.until) || new Date();

      const summary = await assistantRepository.getSummary(fromDate, toDate);

      res.status(200).json({
        success: true,
        generatedAt: new Date().toISOString(),
        period: summary.period,
        jobs: summary.jobs,
        freelance: summary.freelance,
        applications: summary.applications,
        data: {
          jobs: summary.jobs,
          freelance: summary.freelance,
          applications: summary.applications,
        },
      });
    } catch (err) {
      next(err);
    }
  }
}

export const assistantController = new AssistantController();
