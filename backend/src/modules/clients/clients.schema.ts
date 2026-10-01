import { z } from 'zod';

export const createClientSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  contact_name: z.string().optional().nullable(),
  email: z.string().email().optional().nullable().or(z.literal('')),
  phone: z.string().optional().nullable(),
  platform: z.string().optional().nullable(),
  location: z.string().optional().nullable(),
  status: z.string().optional().default('PROSPECT'),
  notes: z.string().optional().nullable(),
  metadata: z.record(z.any()).optional().default({}),
});

export const updateClientSchema = createClientSchema.partial();

export const queryClientsSchema = z.object({
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(50),
  search: z.string().optional(),
  status: z.string().optional(),
  sort: z.enum(['newest', 'oldest', 'name']).optional().default('name'),
});

export type CreateClientInput = z.infer<typeof createClientSchema>;
export type UpdateClientInput = z.infer<typeof updateClientSchema>;
export type QueryClientsInput = z.infer<typeof queryClientsSchema>;
