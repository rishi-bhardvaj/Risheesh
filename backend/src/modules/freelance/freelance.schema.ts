import { z } from 'zod';

export const createLeadSchema = z.object({
  external_id: z.string().optional().nullable(),
  client_id: z.string().uuid().optional().nullable(),
  project_id: z.string().uuid().optional().nullable(),
  title: z.string().min(1, 'Title is required'),
  client_name: z.string().optional().nullable(),
  contact_name: z.string().optional().nullable(),
  contact_info: z.string().optional().nullable(),
  platform: z.string().optional().default('Direct'),
  description: z.string().optional().nullable(),
  skills: z.array(z.string()).optional().default([]),
  budget: z.number().optional().nullable(),
  currency: z.string().optional().default('USD'),
  url: z.string().optional().nullable(),
  status: z.string().optional().default('NEW_LEAD'),
  proposal: z.string().optional().nullable(),
  deadline: z.string().optional().nullable(),
  follow_up_date: z.string().optional().nullable(),
  follow_up_note: z.string().optional().nullable(),
  next_action: z.string().optional().nullable(),
  notes: z.string().optional().nullable(),
  lead_date: z.string().optional().nullable(),
  match_score: z.number().optional().nullable(),
  match_reason: z.string().optional().nullable(),
  metadata: z.record(z.any()).optional().default({}),
});

export const updateLeadSchema = createLeadSchema.partial();

export const queryLeadsSchema = z.object({
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(25),
  search: z.string().optional(),
  platform: z.string().optional(),
  status: z.string().optional(),
  client_id: z.string().uuid().optional(),
  sort: z.enum(['newest', 'oldest', 'budget', 'title']).optional().default('newest'),
});

export type CreateLeadInput = z.infer<typeof createLeadSchema>;
export type UpdateLeadInput = z.infer<typeof updateLeadSchema>;
export type QueryLeadsInput = z.infer<typeof queryLeadsSchema>;
