import { z } from 'zod';

export const createJobSchema = z.object({
  external_id: z.string().optional().nullable(),
  title: z.string().min(1, 'Title is required'),
  company: z.string().min(1, 'Company is required'),
  location: z.string().optional().nullable(),
  salary: z.string().optional().nullable(),
  employment_type: z.string().optional().nullable(),
  experience_requirement: z.string().optional().nullable(),
  url: z.string().optional().nullable(),
  source: z.string().optional().default('Manual'),
  description: z.string().optional().nullable(),
  skills: z.array(z.string()).optional().default([]),
  posted_date: z.string().optional().nullable(),
  match_score: z.number().optional().nullable(),
  match_reason: z.string().optional().nullable(),
  is_saved: z.boolean().optional().default(false),
  notes: z.string().optional().nullable(),
  metadata: z.record(z.any()).optional().default({}),
});

export const updateJobSchema = createJobSchema.partial();

export const queryJobsSchema = z.object({
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(25),
  search: z.string().optional(),
  company: z.string().optional(),
  location: z.string().optional(),
  remote: z.enum(['true', 'false']).optional(),
  employment_type: z.string().optional(),
  source: z.string().optional(),
  saved: z.enum(['true', 'false']).optional(),
  // OPEN by default so closed/stale postings drop out of the live feed; ALL disables the filter.
  status: z.enum(['OPEN', 'STALE', 'CLOSED', 'UNKNOWN', 'ALL']).optional().default('OPEN'),
  min_score: z.coerce.number().min(0).max(100).optional(),
  posted_after: z.string().datetime({ offset: true }).or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)).optional(),
  sort: z.enum(['relevance', 'newest', 'oldest', 'company', 'title']).optional().default('relevance'),
});

export type CreateJobInput = z.infer<typeof createJobSchema>;
export type UpdateJobInput = z.infer<typeof updateJobSchema>;
export type QueryJobsInput = z.infer<typeof queryJobsSchema>;
