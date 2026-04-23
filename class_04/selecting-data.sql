-- =============================================================================
-- Class 04 — Selecting Data (PostgreSQL)
-- Queries over the cinema schema from class_03:
--   director, movie, movie_detail, screening, ticket_booking,
--   genre, actor, movie_genre (M:N), movie_actor (M:N)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. List all movies directed by Christopher Nolan.
-- -----------------------------------------------------------------------------
-- Concept: INNER JOIN across a 1:N relation (many movies, one director).
--   - `m` and `d` are table ALIASES — they let us reference columns without
--     typing the full table name and make the join condition readable.
--   - The ON clause (`m.director_id = d.director_id`) is the FK = PK link.
--   - WHERE filters ROWS (runs before grouping — there's no grouping here).
--   - ORDER BY sorts the final result; default direction is ASC.
SELECT m.title, d.full_name, m.release_year
FROM movie m
JOIN director d ON m.director_id = d.director_id
WHERE d.full_name = 'Christopher Nolan'
ORDER BY m.release_year;


-- -----------------------------------------------------------------------------
-- 2. Show each movie together with all its genres (collapsed into one row).
-- -----------------------------------------------------------------------------
-- Concept: walking a Many-to-Many relation (movie ↔ genre) via the junction
-- table movie_genre, then collapsing the duplicate movie rows with GROUP BY.
--   - Without GROUP BY, a movie with 3 genres would appear on 3 rows.
--   - STRING_AGG concatenates all values in the group into one string,
--     separated by ', ', and sorted alphabetically via `ORDER BY g.name`.
--   - The alias "Movie Title" is double-quoted so it can contain a space
--     and preserve its case in the column header.
SELECT m.title AS "Movie Title",
       STRING_AGG(g.name, ', ' ORDER BY g.name) AS genres
FROM movie m
JOIN movie_genre mg ON mg.movie_id = m.movie_id
JOIN genre g        ON g.genre_id = mg.genre_id
GROUP BY m.title
ORDER BY m.title;


-- -----------------------------------------------------------------------------
-- 3. Top 5 movies with the most actors in the cast.
-- -----------------------------------------------------------------------------
-- Concept: counting rows on the "many" side of a junction table.
--   - We only need the junction table movie_actor — we never look at the
--     actor's name, so joining the `actor` table would be wasted work.
--   - GROUP BY m.movie_id (the primary key) is safer than GROUP BY m.title
--     in case two different movies share the same title.
--   - "Top N" idiom in PostgreSQL: ORDER BY <metric> DESC + LIMIT N.
SELECT m.title, COUNT(ma.actor_id) AS amount_of_actors
FROM movie m
JOIN movie_actor ma ON m.movie_id = ma.movie_id
GROUP BY m.movie_id
ORDER BY amount_of_actors DESC
LIMIT 5;


-- -----------------------------------------------------------------------------
-- 4. Top 3 actors with the most Comedy roles.
-- -----------------------------------------------------------------------------
-- Concept: chaining two Many-to-Many relations (actor ↔ movie ↔ genre).
-- Four joins because we cross two junction tables that share `movie` as their
-- middle table.
--   - WHERE g.name = 'Comedy' filters ROWS *before* grouping, so only
--     Comedy-tagged rows survive to be counted.
--   - If you want "number of distinct Comedy movies" instead of role rows
--     (relevant if a movie can be tagged 'Comedy' and 'Romantic Comedy'),
--     switch to COUNT(DISTINCT m.movie_id).
SELECT a.full_name, COUNT(*) AS comedy_roles
FROM actor a
JOIN movie_actor ma ON a.actor_id = ma.actor_id
JOIN movie m        ON m.movie_id = ma.movie_id
JOIN movie_genre mg ON mg.movie_id = m.movie_id
JOIN genre g        ON g.genre_id = mg.genre_id
WHERE g.name = 'Comedy'
GROUP BY a.actor_id
ORDER BY comedy_roles DESC
LIMIT 3;


-- -----------------------------------------------------------------------------
-- 5. Top 5 directors with the most movies.
-- -----------------------------------------------------------------------------
-- Concept: inverse of query 1 — counting children per parent in a 1:N relation.
--   - INNER JOIN silently drops directors who have 0 movies. Use
--     LEFT JOIN from director if you want to keep them with a count of 0.
--   - COUNT(m.movie_id) counts non-NULL values, which is what you want with
--     a LEFT JOIN. COUNT(*) would incorrectly count unmatched rows as 1.
SELECT d.full_name, COUNT(m.movie_id) AS movie_count
FROM director d
JOIN movie m ON m.director_id = d.director_id
GROUP BY d.director_id
ORDER BY movie_count DESC
LIMIT 5;


-- -----------------------------------------------------------------------------
-- 6. Actors that have played in BOTH Horror AND Comedy movies.
-- -----------------------------------------------------------------------------
-- Concept: classic "must satisfy all of these values" pattern.
--   - WHERE narrows genres to just {Horror, Comedy}.
--   - After GROUP BY a.actor_id, an actor can reach
--     COUNT(DISTINCT g.name) = 2 only if BOTH genres are present in their
--     filtered rows.
--   - You CAN'T write `WHERE g.name = 'Horror' AND g.name = 'Comedy'` —
--     a single row has only one genre, so that condition is always false.
--   - DISTINCT matters: without it, an actor appearing in 5 Horror movies
--     would inflate the count.
SELECT a.full_name
FROM actor a
JOIN movie_actor ma ON a.actor_id = ma.actor_id
JOIN movie m        ON m.movie_id = ma.movie_id
JOIN movie_genre mg ON mg.movie_id = m.movie_id
JOIN genre g        ON g.genre_id = mg.genre_id
WHERE g.name IN ('Horror', 'Comedy')
GROUP BY a.actor_id
HAVING COUNT(DISTINCT g.name) = 2
ORDER BY a.full_name;


-- -----------------------------------------------------------------------------
-- 7. Actors with the fewest movies played (bottom 10).
-- -----------------------------------------------------------------------------
-- Concept: LEFT JOIN to preserve unmatched rows.
--   - LEFT JOIN keeps every actor, even those who never appeared in a movie.
--     With INNER JOIN, actors with 0 movies would silently disappear —
--     which is the exact opposite of what this query is asking for.
--   - COUNT(ma.movie_id) counts non-NULL values, so unmatched actors score 0.
--     COUNT(*) would count the "all-NULL padding row" as 1 and break the
--     result.
SELECT a.full_name, COUNT(ma.movie_id) AS movies_played
FROM actor a
LEFT JOIN movie_actor ma ON a.actor_id = ma.actor_id
GROUP BY a.actor_id
ORDER BY movies_played ASC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- 8. Actor name and role name for every movie they played in.
-- -----------------------------------------------------------------------------
-- Concept: plain detail listing with no aggregation — one row per
-- (movie, actor) pair. Demonstrates that junction tables like movie_actor
-- can carry RELATIONSHIP ATTRIBUTES (role_name) that belong to neither
-- side on its own.
SELECT m.title, a.full_name, ma.role_name
FROM movie m
JOIN movie_actor ma ON ma.movie_id = m.movie_id
JOIN actor a        ON a.actor_id = ma.actor_id;


-- -----------------------------------------------------------------------------
-- 9. Actors that have ONLY EVER played lead roles (never a supporting role).
-- -----------------------------------------------------------------------------
-- Concept: expressing "all rows for X are Y" in SQL.
--   - The simple WHERE below returns any actor who has AT LEAST ONE lead role.
--     That is NOT the same as "never a supporting role" — an actor with 2
--     lead roles and 5 supporting roles would still show up.
--   - The correct pattern is "there exists a lead role AND there does NOT
--     exist a supporting role" — see the NOT EXISTS version below, which
--     is what you should use in production.
SELECT a.full_name
FROM actor a
JOIN movie_actor ma ON ma.actor_id = a.actor_id
WHERE ma.is_lead_role = TRUE;

-- Correct version (actors whose EVERY role is a lead role):
-- SELECT a.full_name
-- FROM actor a
-- WHERE EXISTS (
--     SELECT 1 FROM movie_actor ma
--     WHERE ma.actor_id = a.actor_id AND ma.is_lead_role = TRUE
-- )
-- AND NOT EXISTS (
--     SELECT 1 FROM movie_actor ma
--     WHERE ma.actor_id = a.actor_id AND ma.is_lead_role = FALSE
-- );


-- -----------------------------------------------------------------------------
-- 10. Actors whose role name starts with the letter "L".
-- -----------------------------------------------------------------------------
-- Concept: pattern matching.
--   - LIKE  is case-sensitive.
--   - ILIKE is case-insensitive (PostgreSQL extension) — matches 'L...' and
--     'l...' both.
--   - Wildcards: `%` = zero or more characters, `_` = exactly one character.
SELECT a.full_name, ma.role_name
FROM actor a
JOIN movie_actor ma ON ma.actor_id = a.actor_id
WHERE ma.role_name ILIKE 'L%';


-- -----------------------------------------------------------------------------
-- 11. Actors who played in movies from more than one director.
-- -----------------------------------------------------------------------------
-- Concept: HAVING vs WHERE + COUNT(DISTINCT ...) + multi-column ORDER BY.
--   - COUNT(DISTINCT m.director_id) dedupes across multiple movies by the
--     same director (2 movies by Nolan still count as 1 director).
--   - HAVING filters GROUPS; it cannot be replaced by WHERE because
--     aggregates don't exist before GROUP BY runs.
--   - ORDER BY <col1> DESC, <col2>: primary sort by count desc, ties
--     broken alphabetically by name.
SELECT a.full_name,
       COUNT(DISTINCT m.director_id) AS directors_worked_with
FROM actor a
JOIN movie_actor ma ON a.actor_id = ma.actor_id
JOIN movie m        ON m.movie_id = ma.movie_id
JOIN director d     ON m.director_id = d.director_id
GROUP BY a.actor_id
HAVING COUNT(DISTINCT m.director_id) > 1
ORDER BY directors_worked_with DESC, a.full_name;


-- -----------------------------------------------------------------------------
-- 12. Youngest and oldest actors we have on record.
-- -----------------------------------------------------------------------------
-- Concept: combining two top-1 queries with UNION ALL.
--   - Each branch is wrapped in parentheses so that ORDER BY + LIMIT 1 apply
--     to that branch only, not to the combined result.
--   - The literal column `'youngest' AS label` tells the two rows apart
--     in the output — both branches must have the same column list.
--   - UNION removes duplicates; UNION ALL keeps them (cheaper; use it
--     unless you actually need dedup).
--   - The WHERE ... IS NOT NULL guards are important — sorting with NULLs
--     in PostgreSQL puts them LAST by default for ASC, which could make
--     LIMIT 1 return the wrong row.
(SELECT full_name, birth_year, 'youngest' AS label
 FROM actor
 WHERE birth_year IS NOT NULL
 ORDER BY birth_year DESC
 LIMIT 1)
UNION ALL
(SELECT full_name, birth_year, 'oldest' AS label
 FROM actor
 WHERE birth_year IS NOT NULL
 ORDER BY birth_year ASC
 LIMIT 1);


-- -----------------------------------------------------------------------------
-- 13. For every actor, show the number of genres they have been cast in.
-- -----------------------------------------------------------------------------
-- Concept: crossing two Many-to-Many relations and using COUNT(DISTINCT ...).
--   - Without DISTINCT, a genre tagged on 3 different movies the actor
--     played in would be counted 3 times.
--   - INNER JOIN means actors with zero movies are excluded. Switch to
--     LEFT JOIN if you want to include them (with genre_count = 0).
SELECT a.full_name, COUNT(DISTINCT g.name) AS genre_count
FROM actor a
JOIN movie_actor ma ON ma.actor_id = a.actor_id
JOIN movie m        ON m.movie_id = ma.movie_id
JOIN movie_genre mg ON mg.movie_id = m.movie_id
JOIN genre g        ON g.genre_id = mg.genre_id
GROUP BY a.actor_id;


-- -----------------------------------------------------------------------------
-- 14. Directors with the most screenings scheduled for their movies.
-- -----------------------------------------------------------------------------
-- Concept: chain of 1:N relations (director → movie → screening).
--   - A director with 2 movies, each screened 10 times, scores 20.
--   - No LIMIT, so all directors with at least one screening are listed.
--   - ORDER BY has a secondary key (d.full_name) for stable sorting on ties.
SELECT d.full_name, COUNT(s.screening_id) AS screenings_count
FROM director d
JOIN movie m     ON m.director_id = d.director_id
JOIN screening s ON s.movie_id = m.movie_id
GROUP BY d.director_id
ORDER BY screenings_count DESC, d.full_name;


-- -----------------------------------------------------------------------------
-- 15. First and latest movie (by release year) for each director.
-- -----------------------------------------------------------------------------
-- Concept: MIN/MAX aggregates to find range endpoints inside each group.
--   - One row per director; two values per row.
--   - Note: this returns the YEARS, not the movie titles. To also return
--     the titles (e.g. "what was Nolan's first movie"), you'd need either
--     DISTINCT ON (director_id) with ORDER BY, or a window function like
--     ROW_NUMBER() OVER (PARTITION BY director_id ORDER BY release_year).
SELECT d.full_name,
       MIN(m.release_year) AS first_movie,
       MAX(m.release_year) AS latest_movie
FROM director d
JOIN movie m ON d.director_id = m.director_id
GROUP BY d.director_id;


-- -----------------------------------------------------------------------------
-- 16. Actors whose movies sold the most tickets (total seats booked).
-- -----------------------------------------------------------------------------
-- Concept: long join chain + SUM aggregate.
-- actor → movie_actor → movie → screening → ticket_booking.
--   - SUM(tb.seat_count) adds up seats booked across every screening of
--     every movie the actor appeared in.
--   - Caveat: a booking for a movie with N actors contributes to ALL N of
--     their totals. This is "total seats for movies the actor is in",
--     NOT "seats the actor personally sold".
SELECT a.full_name, SUM(tb.seat_count) AS total_seats_sold
FROM actor a
JOIN movie_actor ma    ON a.actor_id = ma.actor_id
JOIN movie m           ON m.movie_id = ma.movie_id
JOIN screening s       ON s.movie_id = m.movie_id
JOIN ticket_booking tb ON tb.screening_id = s.screening_id
GROUP BY a.actor_id
ORDER BY total_seats_sold DESC, a.full_name;


-- -----------------------------------------------------------------------------
-- 17. Percentage of seats sold for each screening.
-- -----------------------------------------------------------------------------
-- Concept: plain arithmetic, no aggregation.
--   - `100.0 * ...` forces the division into floating-point. In PostgreSQL,
--     integer / integer truncates — so `95 / 100` is `0`. Multiplying by
--     100.0 (a numeric literal) promotes the whole expression to numeric.
--   - ROUND(v, 1) works on numeric — keeps one decimal place.
SELECT m.title,
       s.hall_name,
       s.total_seats,
       (s.total_seats - s.available_seats) AS seats_sold,
       ROUND(100.0 * (s.total_seats - s.available_seats) / s.total_seats, 1)
         AS percentage_sold
FROM screening s
JOIN movie m ON m.movie_id = s.movie_id
ORDER BY percentage_sold DESC;


-- -----------------------------------------------------------------------------
-- 18. Average number of seats per confirmed booking.
-- -----------------------------------------------------------------------------
-- Concept: single aggregate + WHERE filter.
--   - WHERE narrows which rows feed into the aggregate — canceled or
--     pending bookings are excluded from the average.
--   - ::numeric cast makes the value explicitly numeric so ROUND(v, n)
--     can be used (the two-argument ROUND only exists for numeric).
SELECT ROUND(AVG(seat_count)::numeric, 2)
FROM ticket_booking
WHERE booking_status = 'confirmed';


-- -----------------------------------------------------------------------------
-- 19. Movies whose synopsis mentions "location".
-- -----------------------------------------------------------------------------
-- Concept: text search with ILIKE + wildcards.
--   - INNER JOIN drops movies without a movie_detail row — acceptable,
--     because a missing synopsis can't match the pattern anyway.
--   - `%location%` matches the substring anywhere in the text.
--   - For serious free-text search, use PostgreSQL full-text search
--     (to_tsvector / to_tsquery) — ILIKE '%...%' is O(n) and can't use
--     regular B-tree indexes.
SELECT m.title, md.synopsis
FROM movie m
JOIN movie_detail md ON m.movie_id = md.movie_id
WHERE md.synopsis ILIKE '%location%';


-- -----------------------------------------------------------------------------
-- 20. Share of each age rating in the catalog (percentage of total movies).
-- -----------------------------------------------------------------------------
-- Concept: window function on top of an aggregate — "share of total".
--   - Inner COUNT(*) is computed per group (per age_rating).
--   - SUM(COUNT(*)) OVER () has an EMPTY window — it sums those group
--     counts across ALL groups, giving the grand total. OVER () attached
--     to every output row lets us divide each group's count by that total.
--   - Without window functions, you'd need a sub-query or CTE to compute
--     the grand total separately.
SELECT age_rating,
       COUNT(*) AS movies,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)
         AS percentage_of_all_movies
FROM movie
GROUP BY age_rating;


-- -----------------------------------------------------------------------------
-- 21. Directors who have never had a sold-out screening.
-- -----------------------------------------------------------------------------
-- Concept: NOT EXISTS with a CORRELATED sub-query — "there is no row
-- satisfying X for this director".
--   - The inner `WHERE m.director_id = d.director_id` is what makes the
--     sub-query correlated: it's re-evaluated for each candidate director.
--   - `SELECT 1` is a convention — EXISTS only cares whether ANY row
--     comes back, never what's in the columns.
--   - Equivalent alternatives:
--       * LEFT JOIN to sold-out screenings + WHERE right.pk IS NULL (anti-join)
--       * NOT IN (SELECT ...) — dangerous because a single NULL in the
--         sub-query makes the whole NOT IN return zero rows.
SELECT d.full_name
FROM director d
WHERE NOT EXISTS (
    SELECT 1
    FROM movie m
    JOIN screening s ON m.movie_id = s.movie_id
    WHERE m.director_id = d.director_id
      AND (s.screening_status = 'sold_out' OR s.available_seats = 0)
);


-- -----------------------------------------------------------------------------
-- 22. Movies that have NO screenings scheduled.
-- -----------------------------------------------------------------------------
-- Concept: classic ANTI-JOIN pattern with LEFT JOIN + IS NULL.
--   1. LEFT JOIN brings every movie, with NULLs on the screening side
--      when there are no matching screenings.
--   2. WHERE s.screening_id IS NULL keeps only those "no match" rows.
--   - Equivalent to WHERE NOT EXISTS (SELECT 1 FROM screening WHERE ...).
--   - IMPORTANT: `WHERE s.anything IS NULL` works only if that column is
--     NOT NULL in the real row (so NULL can only come from the padding).
--     Here screening_id is the PK, so it's perfectly safe.
SELECT *
FROM movie m
LEFT JOIN screening s ON s.movie_id = m.movie_id
WHERE s.screening_id IS NULL
ORDER BY m.title;


-- -----------------------------------------------------------------------------
-- 23. Movies that have a movie_detail row but no tagline.
-- -----------------------------------------------------------------------------
-- Concept: NULL semantics.
--   - Always use `IS NULL` / `IS NOT NULL`, NEVER `= NULL` or `!= NULL`.
--     In SQL, NULL means "unknown", and any comparison with NULL yields
--     UNKNOWN, which WHERE treats as false.
--   - INNER JOIN ensures we only look at movies that actually have a
--     detail row — otherwise "no tagline" and "no detail row at all"
--     would collapse into the same result.
SELECT *
FROM movie m
JOIN movie_detail md ON m.movie_id = md.movie_id
WHERE md.tagline IS NULL;


-- -----------------------------------------------------------------------------
-- 24. Screenings with zero (non-canceled) bookings.
-- -----------------------------------------------------------------------------
-- Concept: LEFT JOIN + GROUP BY + HAVING, treating "canceled" bookings as
-- "not really booked".
--   - LEFT JOIN from screening keeps screenings with NO bookings at all.
--   - The WHERE clause keeps only canceled or NULL (= no booking) rows —
--     real confirmed bookings are excluded, which means a screening with
--     ANY confirmed booking will be eliminated here.
--   - HAVING COUNT(tb.screening_id) = 0 drops screenings that still have
--     at least one non-canceled booking (defensive — useful if WHERE
--     filter is relaxed).
SELECT m.title, s.hall_name, s.starts_at,
       COUNT(tb.screening_id) AS tickets_booked
FROM screening s
JOIN movie m ON m.movie_id = s.movie_id
LEFT JOIN ticket_booking tb ON tb.screening_id = s.screening_id
WHERE tb.booking_status = 'canceled' OR tb.booking_status IS NULL
GROUP BY m.title, s.hall_name, s.starts_at
HAVING COUNT(tb.screening_id) = 0;


-- -----------------------------------------------------------------------------
-- 25. Shortest and longest movie in the catalog.
-- -----------------------------------------------------------------------------
-- Concept: same UNION ALL + per-branch LIMIT 1 pattern as query 12.
--   - Ties are resolved arbitrarily — if two movies share the minimum
--     duration, only one is returned.
--   - To return ALL tied movies, use a window function such as
--     RANK() OVER (ORDER BY duration_minutes) and filter rank = 1.
(SELECT title, duration_minutes, 'shortest' AS label
 FROM movie
 ORDER BY duration_minutes ASC
 LIMIT 1)
UNION ALL
(SELECT title, duration_minutes, 'longest' AS label
 FROM movie
 ORDER BY duration_minutes DESC
 LIMIT 1);


-- -----------------------------------------------------------------------------
-- 26. Actor-director pairs that have collaborated on more than one movie.
-- -----------------------------------------------------------------------------
-- Concept: grouping by a COMPOSITE key to form pairs.
--   - GROUP BY a.actor_id, d.full_name creates one group per
--     (actor, director) combination — that's the "pair" we want.
--   - COUNT(DISTINCT m.movie_id) is important: if an actor has multiple
--     rows per movie (e.g. playing two roles), a plain COUNT(m.movie_id)
--     would over-count and wrongly qualify them.
SELECT a.full_name, d.full_name,
       COUNT(m.movie_id) AS movies_together
FROM actor a
JOIN movie_actor ma ON a.actor_id = ma.actor_id
JOIN movie m        ON m.movie_id = ma.movie_id
JOIN director d     ON m.director_id = d.director_id
GROUP BY a.actor_id, d.full_name
HAVING COUNT(DISTINCT m.movie_id) > 1
ORDER BY movies_together DESC, a.full_name;


-- -----------------------------------------------------------------------------
-- 27. Approximate age of each actor at the time their movie was released.
-- -----------------------------------------------------------------------------
-- Concept: plain column arithmetic + NULL guards.
--   - Subtraction with NULL yields NULL — the IS NOT NULL checks filter
--     out actors with unknown birth year and movies with unknown release
--     year so the result column isn't polluted with NULLs.
--   - "Approximate" because we only store years on both sides, not full
--     dates. Someone born in December who appeared in a movie released
--     in January would show as 1 year older than they actually were.
SELECT a.full_name, m.title,
       (m.release_year - a.birth_year) AS age_at_release
FROM actor a
JOIN movie_actor ma ON a.actor_id = ma.actor_id
JOIN movie m        ON m.movie_id = ma.movie_id
WHERE a.birth_year IS NOT NULL
  AND m.release_year IS NOT NULL;
