import { pool } from '../config/db.js';

export async function findAll({ search, genre, limit = 25, offset = 0 } = {}) {
	const params = [];
	const where = [];

	if (search) {
		params.push(`%${search}%`);
		where.push(`m.title ILIKE $${params.length}`);
	}

	if (genre) {
		params.push(genre);
		where.push(`
				EXISTS (
					SELECT 1 FROM movie_genre mg2
					JOIN genre g2 ON g2.genre_id = mg2.genre_id
					WHERE mg2.movie_id = m.movie_id
					AND g2.name = $${params.length}
				)
			`);
	}

	const whereClause = where.length > 0 ? `WHERE ${where.join(' AND ')}` : '';

	params.push(limit, offset);
	const limitIdx = params.length - 1;
	const offsetIdx = params.length;

	const result = await pool.query(
		`
			SELECT
				m.movie_id,
				m.title,
				m.release_year,
				m.age_rating,
				m.duration_minutes,
				d.full_name AS director_name,
				md.tagline,
				COALESCE(
					(
						SELECT json_agg(
							json_build_object('genre_id', g.genre_id, 'name', g.name)
							ORDER BY g.name
						)
						FROM movie_genre mg
						JOIN genre g ON g.genre_id = mg.genre_id
						WHERE mg.movie_id = m.movie_id
					),
					'[]'::json
				) as genres
			FROM movie m
			JOIN director d ON m.director_id = d.director_id
			LEFT JOIN movie_detail md ON m.movie_id = md.movie_id
			${whereClause}
			ORDER BY m.release_year DESC, m.title
			LIMIT $${limitIdx} OFFSET $${offsetIdx}
		`,
		params,
	);

	// console.log(result.rows);

	return result.rows;
}

// Simplest way to fetch all movies:
// export async function findAll() {
// 	const result = await pool.query(`SELECT * FROM movie`);

// 	console.log(result.rows);

// 	return result.rows;
// }
