import { z } from 'zod';

export const createApplicationSchema = z.object({
  job_id: z.string().uuid().optional().nullable(),
  company: z.string().min(1, 'Company is required'),
  role: z.string().min(1, 'Role is required'),
  salary: z.string().optional().nullable(),
  location: z.string().optional().nullable(),
  url: z.string().optional().nullable(),
  status: z.string().optional().default('applied'),
  applied_at: z.string().optional().nullable(),
  follow_up_date: z.string().optional().nullable(),
  interview_date: z.string().optional().nullable(),
  interview_stage: z.string().optional().nullable(),
  recruiter_name: z.string().optional().nullable(),
  recruiter_contact: z.string().optional().nullable(),
  resume_id: z.string().optional().nullable(),
  resume_used: z.string().optional().nullable(),
  cover_letter_reference: z.string().optional().nullable(),
  next_action: z.string().optional().nullable(),
  notes: z.string().optional().nullable(),
});

export const updateApplicationSchema = createApplicationSchema.partial();

export const queryApplicationsSchema = z.object({
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(50),
  search: z.string().optional(),
  status: z.string().optional(),
  job_id: z.string().uuid().optional(),
  applied_after: z.string().optional(),
  sort: z.enum(['newest', 'oldest', 'applied', 'company']).optional().default('newest'),
});

export type CreateApplicationInput = z.infer<typeof createApplicationSchema>;
export type UpdateApplicationInput = z.infer<typeof updateApplicationSchema>;
export type QueryApplicationsInput = z.infer<typeof queryApplicationsSchema>;
