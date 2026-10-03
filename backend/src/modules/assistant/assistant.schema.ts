import { z } from 'zod';

/**
 * Parses either a relative duration string (e.g. '24h', '7d', '30d')
 * or an ISO timestamp string into a Date object.
 */
export function parseDateParam(val?: string | null): Date | undefined {
  if (!val) return undefined;
  const trimmed = val.trim();
  if (!trimmed) return undefined;

  const durationMatch = /^(\d+)\s*(h|d|w|m)$/i.exec(trimmed);
  if (durationMatch) {
    const num = parseInt(durationMatch[1], 10);
    const unit = durationMatch[2].toLowerCase();
    const now = Date.now();
    let ms = 0;
    if (unit === 'h') ms = num * 3600 * 1000;
    else if (unit === 'd') ms = num * 86400 * 1000;
    else if (unit === 'w') ms = num * 7 * 86400 * 1000;
    else if (unit === 'm') ms = num * 60 * 1000;
    return new Date(now - ms);
  }

  const parsed = new Date(trimmed);
  if (!isNaN(parsed.getTime())) {
    return parsed;
  }
  return undefined;
}

export const queryAssistantJobsSchema = z.object({
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(25),
  since: z.string().optional(),
  until: z.string().optional(),
  status: z.enum(['OPEN', 'STALE', 'CLOSED', 'UNKNOWN', 'ALL']).optional().default('OPEN'),
  min_score: z.coerce.number().min(0).max(100).optional(),
  remote: z.enum(['true', 'false']).optional(),
  location: z.string().optional(),
  source: z.string().optional(),
  search: z.string().optional(),
  sort: z.enum(['relevance', 'newest', 'oldest', 'company', 'title']).optional().default('relevance'),
});

export const queryAssistantFreelanceSchema = z.object({
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(25),
  since: z.string().optional(),
  until: z.string().optional(),
  status: z.string().optional(),
  platform: z.string().optional(),
  min_score: z.coerce.number().min(0).max(100).optional(),
  search: z.string().optional(),
  sort: z.enum(['newest', 'oldest', 'budget', 'title']).optional().default('newest'),
});

export const queryAssistantApplicationsSchema = z.object({
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(50),
  since: z.string().optional(),
  until: z.string().optional(),
  status: z.string().optional(),
  search: z.string().optional(),
  sort: z.enum(['newest', 'oldest', 'applied', 'company']).optional().default('newest'),
});

export const queryAssistantSummarySchema = z.object({
  since: z.string().optional().default('24h'),
  until: z.string().optional(),
});

export type QueryAssistantJobsInput = z.infer<typeof queryAssistantJobsSchema>;
export type QueryAssistantFreelanceInput = z.infer<typeof queryAssistantFreelanceSchema>;
export type QueryAssistantApplicationsInput = z.infer<typeof queryAssistantApplicationsSchema>;
export type QueryAssistantSummaryInput = z.infer<typeof queryAssistantSummarySchema>;
