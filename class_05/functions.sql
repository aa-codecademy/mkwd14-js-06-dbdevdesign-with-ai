CREATE OR REPLACE FUNCTION fn_screening_percentage_sold(p_screening_id INTEGER)
RETURNS NUMERIC
LANGUAGE sql
STABLE
AS $$
	SELECT ROUND(100.0 * (total_seats - available_seats) / total_seats, 1)
	FROM screening
	WHERE screening_id = p_screening_id
$$;

SELECT fn_screening_percentage_sold(1) AS percentage_sold
SELECT fn_screening_percentage_sold(2) AS percentage_sold
SELECT fn_screening_percentage_sold(3) AS percentage_sold
SELECT fn_screening_percentage_sold(4) AS percentage_sold

CREATE OR REPLACE FUNCTION fn_top_movies_by_genre(p_genre_name VARCHAR, p_limit INTEGER DEFAULT 5)
RETURNS TABLE (
	movie_id INTEGER,
	title VARCHAR,
	release_year INTEGER,
	seats_sold BIGINT
)
LANGUAGE sql
STABLE
AS $$
	SELECT m.movie_id, m.title, m.release_year,
			COALESCE(SUM(tb.seat_count), 0) as seats_sold
	FROM movie m
	JOIN movie_genre mg ON mg.movie_id = m.movie_id
	JOIN genre g ON g.genre_id = mg.genre_id
	LEFT JOIN screening s ON s.movie_id = m.movie_id
	LEFT JOIN ticket_booking tb on s.screening_id = tb.screening_id
	WHERE g.name = p_genre_name
	GROUP BY m.movie_id, m.title, m.release_year
	LIMIT p_limit
$$;

SELECT * FROM fn_top_movies_by_genre('Comedy')
SELECT * FROM fn_top_movies_by_genre('Horror', 7)
SELECT * FROM fn_top_movies_by_genre('Drama', 50)
SELECT * FROM fn_top_movies_by_genre('Thriller', 50)
