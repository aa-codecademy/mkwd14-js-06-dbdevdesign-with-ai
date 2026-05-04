import * as bookingsService from '../services/bookings.service.js';

export async function bookTicket(req, res, next) {
	try {
		const booking = await bookingsService.bookTicket(req.body);

		res.status(201).json(booking);
	} catch (error) {
		console.error(error);
	}
}
