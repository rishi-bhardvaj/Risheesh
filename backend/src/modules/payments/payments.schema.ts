import { z } from 'zod';

export const createPaymentSchema = z.object({
  client_id: z.string().uuid('Valid client_id UUID is required'),
  project_id: z.string().uuid().optional().nullable(),
  amount: z.number().positive('Amount must be positive'),
  currency: z.string().optional().default('USD'),
  payment_date: z.string().optional(),
  status: z.string().optional().default('EXPECTED'),
  description: z.string().optional().nullable(),
  notes: z.string().optional().nullable(),
});

export const updatePaymentSchema = createPaymentSchema.partial();

export const queryPaymentsSchema = z.object({
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(50),
  client_id: z.string().uuid().optional(),
  project_id: z.string().uuid().optional(),
  status: z.string().optional(),
  sort: z.enum(['newest', 'oldest', 'amount']).optional().default('newest'),
});

export type CreatePaymentInput = z.infer<typeof createPaymentSchema>;
export type UpdatePaymentInput = z.infer<typeof updatePaymentSchema>;
export type QueryPaymentsInput = z.infer<typeof queryPaymentsSchema>;
