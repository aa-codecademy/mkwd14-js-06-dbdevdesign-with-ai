import * as screeningsRepository from '../repositories/screenings.repository.js';

export async function listScreeningsByMovieId(movieId) {
	const screenings = await screeningsRepository.findByMovieId(movieId);

	return screenings;
}
