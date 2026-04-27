-- ============================================================================
-- FUNCTIONS  (user-defined, scalar and table-returning)
-- ============================================================================
--
-- A FUNCTION wraps a SELECT (or some logic) behind a name, accepts parameters,
-- and RETURNS a value. Functions are *callable from SELECT*:
--
--     SELECT fn_screening_percentage_sold(1);
--     SELECT * FROM fn_top_movies_by_genre('Comedy');
--
-- Why use them?
--   * Centralize logic that is otherwise copy-pasted across the codebase.
--   * Hide complex queries behind a meaningful name.
--   * Make queries parameterizable in a way that views cannot be.
--
-- Volatility classification (the optimizer uses these):
--   IMMUTABLE — same inputs ALWAYS produce the same output, no DB reads.
--   STABLE    — within ONE query, same inputs produce same output (DB reads OK).
--   VOLATILE  — output may change at any time / function has side effects (default).
-- Both functions below are STABLE — they read the DB but don't modify it.
--
-- LANGUAGE sql vs LANGUAGE plpgsql:
--   `sql` is great when the body is a single SELECT (PostgreSQL can inline it).
--   `plpgsql` adds variables, IF/LOOP, exceptions — needed for procedural logic.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1) Scalar function: returns ONE numeric value
-- ----------------------------------------------------------------------------
-- Computes "% of seats sold" for a given screening.
--   p_<name>  — convention for IN parameters; avoids clashes with column names.
--   100.0     — forces NUMERIC arithmetic; integer / integer would truncate.
CREATE OR REPLACE FUNCTION fn_screening_percentage_sold(p_screening_id INTEGER)
RETURNS NUMERIC
LANGUAGE sql
STABLE
AS $$
	SELECT ROUND(100.0 * (total_seats - available_seats) / total_seats, 1)
	FROM screening
	WHERE screening_id = p_screening_id
$$;

-- Call the scalar function — once per screening.
SELECT fn_screening_percentage_sold(1) AS percentage_sold
SELECT fn_screening_percentage_sold(2) AS percentage_sold
SELECT fn_screening_percentage_sold(3) AS percentage_sold
SELECT fn_screening_percentage_sold(4) AS percentage_sold


-- ----------------------------------------------------------------------------
-- 2) Table-returning function (TVF): returns a SET of rows
-- ----------------------------------------------------------------------------
-- "Top N movies of a given genre, ranked by total seats sold."
--
--   RETURNS TABLE(...)        — declares the output schema; callers can do
--                                SELECT col FROM fn_top_movies_by_genre(...).
--   p_limit ... DEFAULT 5     — optional parameter; fn_top_movies_by_genre('X')
--                                works without specifying a limit.
--   LEFT JOIN screening / ticket_booking — keeps movies that have NO screenings
--                                           or NO bookings yet (their seats_sold = 0).
--   COALESCE(SUM(...), 0)     — turns NULL (no bookings at all) into 0 so the
--                                output column never returns NULL.
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

-- Call a table function with `SELECT * FROM ...` — it behaves like a virtual table.
SELECT * FROM fn_top_movies_by_genre('Comedy')           -- uses the default limit (5)
SELECT * FROM fn_top_movies_by_genre('Horror', 7)        -- overrides the limit
SELECT * FROM fn_top_movies_by_genre('Drama', 50)
SELECT * FROM fn_top_movies_by_genre('Thriller', 50)
