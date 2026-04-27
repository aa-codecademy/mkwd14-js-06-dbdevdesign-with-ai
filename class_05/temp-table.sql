-- ============================================================================
-- TEMPORARY TABLES
-- ============================================================================
--
-- A TEMPORARY (or TEMP) TABLE is a real table that lives only for the duration
-- of your database session. It is private to the session that created it and
-- is dropped automatically when the session ends.
--
-- Use cases:
--   * Stage intermediate results so you can query them several times without
--     re-running an expensive base query.
--   * Break a complex transformation into readable steps.
--   * Hold scratch data while running a multi-step migration or report.
--
-- Differences vs CTE (WITH ...):
--   * A CTE only exists for ONE query.
--   * A TEMP TABLE exists for the WHOLE session and can be queried many times.
--   * A TEMP TABLE can be indexed; a CTE cannot.
-- ============================================================================


-- Step 1 — materialize the result of a query into a temp table.
-- `CREATE ... AS SELECT` copies both the structure and the data.
-- After this command, `tmp_recent_movies` is a normal table you can SELECT from,
-- JOIN against, or even modify — but only inside this session.
CREATE TEMPORARY TABLE tmp_recent_movies AS
SELECT movie_id, title, release_year, age_rating, director_id
FROM movie
WHERE release_year >= 2020


-- Step 2 — query the temp table just like a regular one.
-- This is fast because the heavy filter (`release_year >= 2020`) ran once,
-- and we are now reading a smaller pre-filtered set.
SELECT COUNT(*) AS recent_movies_count FROM tmp_recent_movies


-- Step 3 — join the temp table back to a regular table.
-- Using the temp table makes the intent clearer than repeating the big WHERE
-- filter inline, and avoids re-scanning `movie` for every downstream query.
SELECT *
FROM director d
JOIN tmp_recent_movies tmp_m ON d.director_id = tmp_m.director_id

-- The temp table disappears automatically when the session closes.
-- You can also drop it explicitly:    DROP TABLE tmp_recent_movies;
