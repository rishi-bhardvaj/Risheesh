import { z } from 'zod';

export const createProjectSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  description: z.string().optional().nullable(),
  status: z.string().optional().default('in_progress'),
  progress: z.number().min(0).max(1).optional().default(0.0),
  tech_stack: z.string().optional().nullable(),
  github_url: z.string().optional().nullable(),
  live_url: z.string().optional().nullable(),
  deadline: z.string().optional().nullable(),
  notes: z.string().optional().nullable(),
  client_id: z.string().uuid().optional().nullable(),
  lead_id: z.string().uuid().optional().nullable(),
  is_freelance: z.boolean().optional().default(false),
  metadata: z.record(z.any()).optional().default({}),
});

export const updateProjectSchema = createProjectSchema.partial();

export const queryProjectsSchema = z.object({
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(50),
  search: z.string().optional(),
  status: z.string().optional(),
  client_id: z.string().uuid().optional(),
  is_freelance: z.enum(['true', 'false']).optional(),
  sort: z.enum(['newest', 'oldest', 'name', 'progress']).optional().default('newest'),
});

export type CreateProjectInput = z.infer<typeof createProjectSchema>;
export type UpdateProjectInput = z.infer<typeof updateProjectSchema>;
export type QueryProjectsInput = z.infer<typeof queryProjectsSchema>;
