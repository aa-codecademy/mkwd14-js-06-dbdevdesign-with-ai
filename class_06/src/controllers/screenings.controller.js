import * as screeningsService from '../services/screenings.service.js';

export async function listScreeningsByMovieId(req, res, next) {
	try {
		const { id } = req.params;

		const screenings = await screeningsService.listScreeningsByMovieId(id);

		res.json(screenings);
	} catch (error) {
		console.error('Error listing screenings by movie ID:', error);
	}
}
