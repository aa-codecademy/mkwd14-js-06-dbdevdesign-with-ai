import * as moviesService from '../services/movies.service.js';

export async function list(req, res, next) {
	console.log('Query to list movies:', req.query);
	const movies = await moviesService.list(req.query);
	res.json(movies);
}

export async function getById(req, res, next) {
	const { id } = req.params;
	const movie = await moviesService.getById(id);
	res.json(movie);
}
