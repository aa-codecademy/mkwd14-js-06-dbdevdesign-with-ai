import * as moviesRepository from '../repositories/movies.repository.js';

// Service layer:
// - Converts raw HTTP input into domain-friendly values
// - Keeps business logic out of controllers and SQL code
export function list(query) {
	return moviesRepository.findAll({
		search: query.search,
		genre: query.genre,
		nowShowing: query.nowShowing === 'true',
		limit: query.limit,
		offset: query.offset,
	});
}

export function getById(id) {
	return moviesRepository.findById(id);
}
