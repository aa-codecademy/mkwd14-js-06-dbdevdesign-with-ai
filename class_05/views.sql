-- ============================================================================
-- VIEWS  (regular view + materialized view)
-- ============================================================================
--
-- A VIEW is a *named SELECT* that lives in the database. You query it like a
-- table, but every time you do, PostgreSQL re-runs the underlying query.
--   + always fresh
--   + zero extra storage
--   - cost of the query is paid on every read
--
-- A MATERIALIZED VIEW is a view whose result is *stored on disk* like a table.
--   + reads are as fast as a plain table read
--   + can be indexed
--   - data is a snapshot — stale until you `REFRESH` it
--
-- Rule of thumb: start with a regular view; promote to materialized only when
-- the query is expensive AND mild staleness is acceptable (dashboards, reports).
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1) Regular VIEW: a "movie overview" that hides a 4-table join behind one name
-- ----------------------------------------------------------------------------
-- The query below is non-trivial: it joins movie, director, movie_genre, genre
-- and movie_detail, and aggregates genres into a single comma-separated string
-- with STRING_AGG. By wrapping it in a view, callers only need to write
--     SELECT * FROM v_movie_overview
-- instead of repeating this 7-line join everywhere.
CREATE VIEW v_movie_overview AS
SELECT m.movie_id, m.title, m.release_year, m.age_rating, m.duration_minutes,
		d.full_name as director_name, md.tagline,
		STRING_AGG(g.name, ', ' ORDER BY g.name) as genres
FROM movie m
JOIN director d ON m.director_id = d.director_id          -- every movie has a director
LEFT JOIN movie_genre mg ON mg.movie_id = m.movie_id      -- LEFT JOIN: keep movies even if they have no genre
LEFT JOIN genre g ON g.genre_id = mg.genre_id
LEFT JOIN movie_detail md ON md.movie_id = m.movie_id     -- LEFT JOIN: keep movies that lack a detail row
GROUP BY m.movie_id, m.title, m.release_year, m.age_rating, m.duration_minutes, d.full_name, md.tagline

-- A view is queryable like a table — you can filter, sort, join it further.
-- Behind the scenes PostgreSQL inlines the view's SELECT into your query.
SELECT * FROM v_movie_overview
WHERE release_year >= 2024


-- ----------------------------------------------------------------------------
-- 2) MATERIALIZED VIEW: same query, but the result is cached on disk
-- ----------------------------------------------------------------------------
-- Use this when the underlying query is expensive and you would rather read a
-- snapshot than rerun the join every time.
CREATE MATERIALIZED VIEW mv_movie_overview AS
SELECT m.movie_id, m.title, m.release_year, m.age_rating, m.duration_minutes,
		d.full_name as director_name, md.tagline,
		STRING_AGG(g.name, ', ' ORDER BY g.name) as genres
FROM movie m
JOIN director d ON m.director_id = d.director_id
LEFT JOIN movie_genre mg ON mg.movie_id = m.movie_id
LEFT JOIN genre g ON g.genre_id = mg.genre_id
LEFT JOIN movie_detail md ON md.movie_id = m.movie_id
GROUP BY m.movie_id, m.title, m.release_year, m.age_rating, m.duration_minutes, d.full_name, md.tagline

-- Demonstration that a materialized view does NOT auto-update:
--   1. Insert a new movie into the base table.
--   2. Query mv_movie_overview — the new movie is missing.
--   3. REFRESH the materialized view — now it appears.
INSERT INTO movie (director_id, title, release_year, duration_minutes, age_rating) VALUES
				(1, 'Balcancan', 2005, 90, 'PG-13')

-- Reading from the cached snapshot (still does NOT contain 'Balcancan' yet):
SELECT * FROM mv_movie_overview
WHERE release_year >= 2024

-- Rebuilds the snapshot from the base tables. Only after this command will
-- newly inserted/updated/deleted rows appear in the materialized view.
-- For zero-downtime refreshes on big views, see: REFRESH MATERIALIZED VIEW CONCURRENTLY
-- (requires a UNIQUE index on the materialized view).
REFRESH MATERIALIZED VIEW mv_movie_overview
