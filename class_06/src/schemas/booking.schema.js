import { z } from 'zod';

export const createBookingSchema = z.object({
	customerEmail: z.email().trim().optional(),
	customerName: z.string().trim().min(1).max(100),
	screeningId: z.number().int().positive(),
	seatCount: z.number().int().positive(),
});
