import { pool } from '../config/db.js';

export async function findAll({
	search,
	genre,
	nowShowing = false,
	limit = 25,
	offset = 0,
} = {}) {
	const params = []; // used to store query parameters for parameterized queries
	const where = []; // used to build dynamic WHERE clauses based on provided filters

	// if we are searching by title, we add a parameter for the search term and a corresponding WHERE clause
	if (search) {
		params.push(`%${search}%`);
		where.push(`m.title ILIKE $${params.length}`);
	}

	// if we are filtering by genre, we add a parameter for the genre name and a corresponding WHERE clause that checks for the existence of a matching genre for each movie
	if (genre) {
		params.push(genre);
		// Using EXISTS we can check if there is at least one genre associated with the movie that matches the provided genre name without needing to join the genre table directly in the main query, which can improve performance when filtering by genre
		where.push(`
				EXISTS (
					SELECT 1 FROM movie_genre mg2
					JOIN genre g2 ON g2.genre_id = mg2.genre_id
					WHERE mg2.movie_id = m.movie_id
					AND g2.name = $${params.length}
				)
			`);
	}

	if (nowShowing) {
		where.push(`
				EXISTS (
					SELECT 1 FROM screening s
					WHERE s.movie_id = m.movie_id
					AND s.starts_at > NOW()
					AND s.screening_status = 'selling'
					AND s.available_seats > 0
				)
			`);
	}

	// if we have any WHERE conditions, we join them with AND and prepend the WHERE keyword; otherwise, we leave it empty
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

	// json_agg - aggregates multiple rows into a JSON array
	// json_build_object - builds a JSON object from key-value pairs
	// '[]'::json - if there are no genres for a movie, we return an empty JSON array instead of null

	return result.rows;
}

// Simplest way to fetch all movies:
// export async function findAll() {
// 	const result = await pool.query(`SELECT * FROM movie`);

// 	console.log(result.rows);

// 	return result.rows;
// }

export async function findById(id) {
	const result = await pool.query(
		`
			SELECT
				m.movie_id,
				m.title,
				m.release_year,
				m.age_rating,
				m.duration_minutes,
				m.created_at,
				d.director_id,
				d.full_name as director_name,
				d.country as director_country,
				md.tagline,
				md.synopsis,
			COALESCE(
				(
					SELECT json_agg(
						json_build_object(
							'actor_id', a.actor_id,
							'full_name', a.full_name,
							'birth_year', a.birth_year,
							'role_name', ma.role_name,
							'is_lead_role', ma.is_lead_role
						)
						ORDER BY ma.is_lead_role DESC, a.full_name
					)
					FROM movie_actor ma
					JOIN actor a ON a.actor_id = ma.actor_id
					WHERE ma.movie_id = m.movie_id
				),
				'[]'::json
			) AS "cast",
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
			) AS genres
			FROM movie m
			JOIN director d ON m.director_id = d.director_id
			LEFT JOIN movie_detail md ON md.movie_id = m.movie_id
			WHERE m.movie_id = $1
		`,
		[id],
	);

	return result.rows[0] ?? null;
}
