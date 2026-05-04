import { z } from 'zod';

export const idParamsSchema = z.object({
	id: z.coerce.number().int().positive(),
});

export const querySchema = z.object({
	search: z.string().min(1).optional(),
	genre: z.string().min(1).optional(),
	nowShowing: z
		.string()
		.optional()
		.transform(v => v === 'true'),
	limit: z.coerce.number().int().positive().optional(),
	offset: z.coerce.number().int().positive().optional(),
});
