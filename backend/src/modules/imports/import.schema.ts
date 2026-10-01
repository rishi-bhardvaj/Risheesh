import { z } from 'zod';

export const jobImportItemSchema = z.object({
  external_id: z.string().optional().nullable(),
  title: z.string().min(1, 'Title is required'),
  company: z.string().min(1, 'Company is required'),
  location: z.string().optional().nullable(),
  remote: z.boolean().optional().nullable(),
  employment_type: z.string().optional().nullable(),
  experience_requirement: z.string().optional().nullable(),
  salary: z.string().optional().nullable(),
  url: z.string().optional().nullable(),
  source: z.string().min(1, 'Source is required'),
  description: z.string().optional().nullable(),
  skills: z.array(z.string()).optional().default([]),
  posted_date: z.string().optional().nullable(),
  discovered_at: z.string().optional().nullable(),
  match_score: z.number().optional().nullable(),
  match_reason: z.string().optional().nullable(),
  metadata: z.record(z.any()).optional().default({}),
}).refine((data) => (data.url && data.url.trim().length > 0) || (data.external_id && data.external_id.trim().length > 0), {
  message: 'Either url or external_id must be provided for job deduplication',
  path: ['url'],
});

export const jobsImportBatchSchema = z.object({
  schema_version: z.string().default('1.0'),
  data_type: z.literal('jobs'),
  generated_at: z.string().optional(),
  source: z.string().min(1, 'Source is required'),
  jobs: z.array(z.any()), // Checked individually for graceful rejection
});

export const freelanceImportItemSchema = z.object({
  external_id: z.string().optional().nullable(),
  title: z.string().min(1, 'Title is required'),
  client_name: z.string().optional().nullable(),
  platform: z.string().min(1, 'Platform is required'),
  description: z.string().optional().nullable(),
  skills: z.array(z.string()).optional().default([]),
  budget: z.number().optional().nullable(),
  currency: z.string().optional().default('USD'),
  url: z.string().optional().nullable(),
  contact_info: z.string().optional().nullable(),
  deadline: z.string().optional().nullable(),
  posted_date: z.string().optional().nullable(),
  discovered_at: z.string().optional().nullable(),
  match_score: z.number().optional().nullable(),
  match_reason: z.string().optional().nullable(),
  metadata: z.record(z.any()).optional().default({}),
}).refine((data) => (data.url && data.url.trim().length > 0) || (data.external_id && data.external_id.trim().length > 0), {
  message: 'Either url or external_id must be provided for freelance project deduplication',
  path: ['url'],
});

export const freelanceImportBatchSchema = z.object({
  schema_version: z.string().default('1.0'),
  data_type: z.literal('freelance'),
  generated_at: z.string().optional(),
  source: z.string().min(1, 'Source is required'),
  projects: z.array(z.any()), // Checked individually for graceful rejection
});

export type JobImportItem = z.infer<typeof jobImportItemSchema>;
export type JobsImportBatch = z.infer<typeof jobsImportBatchSchema>;
export type FreelanceImportItem = z.infer<typeof freelanceImportItemSchema>;
export type FreelanceImportBatch = z.infer<typeof freelanceImportBatchSchema>;
