import * as bookingsRepository from '../repositories/bookings.repository.js';
import { BadRequestError, NotFoundError } from '../types/error.js';

export async function bookTicket(data) {
	try {
		const result = await bookingsRepository.create(data);
		return result;
	} catch (error) {
		if (error.message === 'SCREENING_NOT_FOUND') {
			throw new NotFoundError('Screening not found');
		}
		if (error.message === 'SCREENING_ENDED') {
			throw new BadRequestError('Screening has already ended');
		}
		if (error.message === 'SCREENING_NOT_SELLING') {
			throw new BadRequestError('Screening is not selling tickets');
		}
		if (error.message === 'NOT_ENOUGH_SEATS') {
			throw new BadRequestError('Not enough seats available');
		}
		throw error;
	}
}
