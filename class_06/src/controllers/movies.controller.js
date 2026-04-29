import * as moviesService from '../services/movies.service.js';

export async function list(req, res, next) {
	console.log('Query to list movies:', req.query);
	const movies = await moviesService.list(req.query);
	res.json(movies);
}
