import { Router } from 'express';
import * as bookingsController from '../controllers/bookings.controller.js';
import { validate } from '../middleware/validate.js';
import { createBookingSchema } from '../schemas/booking.schema.js';

const router = Router();

router.post(
	'/',
	validate({ body: createBookingSchema }),
	bookingsController.bookTicket,
);

export default router;
