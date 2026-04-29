import * as moviesRepository from '../repositories/movies.repository.js';

export function list(query) {
	return moviesRepository.findAll({
		search: query.search,
		genre: query.genre,
		nowShowing: query.nowShowing === 'true', // convert string to boolean
		limit: query.limit,
		offset: query.offset,
	});
}

export function getById(id) {
	return moviesRepository.findById(id);
}
