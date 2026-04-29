import * as moviesRepository from '../repositories/movies.repository.js';

export function list(query) {
	return moviesRepository.findAll({
		search: query.search,
		genre: query.genre,
		limit: query.limit,
		offset: query.offset,
	});
}
