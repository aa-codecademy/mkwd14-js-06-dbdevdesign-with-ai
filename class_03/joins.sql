-- ============================================================================
-- ** JOINS **
--
-- Every join in this file walks across one of the relations defined in
-- create_movie_db_script.sql:
--
--   director     1 ─── N  movie            (FK: movie.director_id)
--   movie        1 ─── 1  movie_detail     (FK+PK: movie_detail.movie_id)
--   movie        1 ─── N  screening        (FK: screening.movie_id)
--   screening    1 ─── N  ticket_booking   (FK: ticket_booking.screening_id)
--   movie        M ─── N  genre            via junction movie_genre
--   movie        M ─── N  actor            via junction movie_actor
--
-- The join CONDITION is almost always "child.fk = parent.pk".
-- The join TYPE (INNER / LEFT / RIGHT / FULL / CROSS) decides what to do with
-- rows that have no match on the other side.
-- ============================================================================


-- ------------------------------------------------------------------
-- (INNER) JOIN
-- Keeps only rows that match on BOTH sides. Unmatched rows are dropped.
-- ------------------------------------------------------------------

-- List every film with the name of its director.
-- Relation used: director 1 ── N movie  (FK on the "many" side: movie.director_id)
-- movie.director_id is NOT NULL, so every movie has exactly one director and
-- INNER JOIN loses no rows here.
SELECT m.title, d.full_name
FROM movie m
INNER JOIN director d ON d.director_id = m.director_id


-- ------------------------------------------------------------------
-- OUTER JOINS
-- LEFT (OUTER) JOIN — keep every row from the LEFT table, fill missing
-- right-side columns with NULL.
-- ------------------------------------------------------------------

-- Every film with its tagline.
-- Relation used: movie 1 ── 1 movie_detail (optional on the detail side —
-- a movie MAY or MAY NOT have a detail row).
-- LEFT JOIN keeps every movie; tagline is NULL for movies with no detail row.
-- If we used INNER JOIN here, movies without a detail row would disappear.
SELECT m.title, md.tagline
FROM movie m
LEFT JOIN movie_detail md ON md.movie_id = m.movie_id

-- Same result written with RIGHT JOIN by swapping the table order.
-- Any LEFT JOIN can be rewritten as a RIGHT JOIN (and vice versa); most
-- teams standardise on LEFT JOIN for readability.
SELECT m.title, md.tagline
FROM movie_detail md
RIGHT JOIN movie m ON m.movie_id = md.movie_id


-- ------------------------------------------------------------------
-- RIGHT (OUTER) JOIN — mirror of LEFT JOIN: keep every row from the RIGHT
-- table, fill missing left-side columns with NULL.
-- ------------------------------------------------------------------

-- For every genre — INCLUDING genres that no movie uses yet — count how many
-- movies are tagged with it.
-- Relation used: movie M ── N genre via junction movie_genre.
-- movie_genre is the "left" side of the M:N; RIGHT JOIN genre keeps even
-- genres that have no row in movie_genre (their COUNT becomes 0).
SELECT g.name, COUNT(mg.movie_id) AS movies_tagged
FROM movie_genre mg
RIGHT JOIN genre g ON g.genre_id = mg.genre_id
GROUP BY g.genre_id, g.name
ORDER BY movies_tagged DESC, g.name


-- ------------------------------------------------------------------
-- FULL (OUTER) JOIN — keep everything on BOTH sides. Great for finding
-- orphans / mismatches on either end of an optional 1:1 relation.
-- ------------------------------------------------------------------

SELECT m.title, md.tagline
FROM movie m
FULL JOIN movie_detail md ON md.movie_id = m.movie_id
ORDER BY m.title


-- ------------------------------------------------------------------
-- CROSS JOIN — Cartesian product. Every row on the left is paired with
-- every row on the right. Size = |A| × |B|. No ON clause.
-- Does NOT use a relation — it ignores FKs entirely.
-- ------------------------------------------------------------------

-- Every unordered (actually: ordered) pair of genres — useful to build a
-- "related genre" matrix, for example.
SELECT g1.name AS genre_a, g2.name AS genre_b
FROM genre g1
CROSS JOIN genre g2


-- ------------------------------------------------------------------
-- SELF JOIN — "self join" is not a keyword, it is a pattern: join a table
-- to itself by giving it two different aliases.
-- Typical uses: hierarchies (employee → manager in the same table),
-- or pairing rows that share a common value (co-stars below).
-- ------------------------------------------------------------------

-- For each movie, list every pair of co-stars.
-- Relation used: movie M ── N actor via movie_actor.
-- We join movie_actor to itself on movie_id (same film), and use
-- ma2.actor_id > ma1.actor_id so that:
--   * we don't pair an actor with themselves
--   * we don't get both (A, B) and (B, A) — only one pair per couple
SELECT m.title, a1.full_name AS actor_a, a2.full_name AS actor_b
FROM movie_actor ma1
JOIN movie_actor ma2 ON ma2.movie_id = ma1.movie_id AND ma2.actor_id > ma1.actor_id
JOIN movie m ON m.movie_id = ma1.movie_id
JOIN actor a1 ON a1.actor_id = ma1.actor_id
JOIN actor a2 ON a2.actor_id = ma2.actor_id
ORDER BY m.title, actor_a, actor_b


-- ------------------------------------------------------------------
-- NATURAL JOIN - DO NOT USE PLEASE
-- Joins automatically on ALL columns that share a name in both tables.
-- Fragile: adding a harmless column like `created_at` later can silently
-- change the meaning of the query. Always prefer explicit ON.
-- ------------------------------------------------------------------


-- ------------------------------------------------------------------
-- OLD STYLE JOIN (comma join)
-- Equivalent to INNER JOIN but mixes the JOIN CONDITION and the ROW FILTER
-- in the same WHERE clause. Forget the condition and you silently get a
-- Cartesian product. Avoid in new code — use explicit JOIN ... ON instead.
-- ------------------------------------------------------------------

SELECT
    m.title,
    d.full_name AS director
FROM movie m, director d
WHERE m.director_id = d.director_id
ORDER BY m.title;


-- Films with their editorial copy — shown here only to illustrate NATURAL JOIN.
-- It "works" because `movie` and `movie_detail` share the `movie_id` column.
-- Still don't use it in real code.
SELECT title, tagline, release_year
FROM movie
NATURAL JOIN movie_detail
ORDER by title



-- ============================================================================
-- ** EXAMPLE QUERIES **
-- These put the join types into the context of real product questions.
-- ============================================================================

-- R001. For a featured actor, list every film they have appeared in and
-- whether they had the lead role.
-- Walks the M:N relation movie ── movie_actor ── actor, then reads the
-- relationship attribute `is_lead_role` that lives on the junction table.
SELECT m.title, ma.is_lead_role
FROM actor a
JOIN movie_actor ma ON ma.actor_id = a.actor_id
JOIN movie m ON m.movie_id = ma.movie_id
WHERE a.full_name = 'Ryan Gosling'


-- Directors whose country of origin is still missing, plus the films they directed.
-- Walks the 1:N relation director ── movie. Directors with no movies would
-- be dropped by this INNER JOIN — switch to LEFT JOIN if you want to keep them.
SELECT d.full_name, d.country, m.title
FROM director d
JOIN movie m ON d.director_id = m.director_id
WHERE d.country IS NULL
ORDER BY d.full_name


-- The single longest film on the platform and the director behind it.
-- 1:N director ── movie again; sort by duration, keep only the top row.
SELECT m.title, m.duration_minutes, d.full_name
FROM movie m
JOIN director d ON m.director_id = d.director_id
ORDER BY m.duration_minutes DESC
LIMIT 1


-- The five most productive directors in the catalogue.
-- Groups movies per director (1:N) and counts them. Directors with ZERO
-- movies would not appear here — INNER JOIN drops them. To include them,
-- start FROM director and LEFT JOIN movie, then COUNT(m.movie_id).
SELECT d.full_name, COUNT(m.movie_id) AS movie_count
FROM movie m
JOIN director d ON d.director_id = m.director_id
GROUP BY d.director_id, d.full_name
ORDER BY movie_count DESC, d.full_name
LIMIT 5
