import { pool } from '../config/db.js';

export async function findByMovieId(movieId) {
	const result = await pool.query(
		`
			SELECT
				screening_id,
				movie_id,
				starts_at,
				screening_status,
				hall_name,
				total_seats,
				available_seats
			FROM screening
			WHERE movie_id = $1
			ORDER BY starts_at ASC
		`,
		[movieId],
	);

	return result.rows;
}
