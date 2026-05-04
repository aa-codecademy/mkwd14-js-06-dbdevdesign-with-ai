import * as bookingsRepository from '../repositories/bookings.repository.js';

export async function bookTicket(data) {
	const result = await bookingsRepository.create(data);

	return result;
}
