# Class 04 — Selecting Data (PostgreSQL)

This folder focuses on **reading data** from the cinema schema introduced in `class_03` (`director`, `movie`, `movie_detail`, `screening`, `ticket_booking`, `genre`, `actor`, `movie_genre`, `movie_actor`).

The goal of this class is not to learn more schema, but to learn how to **ask questions** of a schema that already exists:

- shaping results with `SELECT`, `WHERE`, `ORDER BY`, `LIMIT`
- combining rows from multiple tables with joins
- collapsing groups of rows with `GROUP BY` + aggregates (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `STRING_AGG`)
- filtering **groups** (not rows) with `HAVING`
- combining result sets with `UNION` / `UNION ALL`
- using sub-queries (`EXISTS`, correlated sub-queries)
- using window functions (`SUM(...) OVER (...)`) for "share of total" style calculations

All queries live in `selecting-data.sql`. This README walks through them in order and explains **what each query returns, why it is written the way it is, and what concept it is demonstrating**.

---

## 1. The mental model for a `SELECT`

SQL is not executed in the order it is written. The logical order is:

```
FROM + JOIN      → build the combined row set
WHERE            → drop rows that don't match
GROUP BY         → collapse rows into groups
HAVING           → drop whole groups that don't match
SELECT           → choose / compute the output columns
ORDER BY         → sort the final result
LIMIT / OFFSET   → keep only the top N
```

Two consequences that trip people up:

- **`WHERE` filters rows, `HAVING` filters groups.** You cannot use an aggregate (`COUNT(*)`, `SUM(...)`) in `WHERE`, because groups don't exist yet at that stage.
- **Column aliases from `SELECT` are only guaranteed in `ORDER BY`**, not in `WHERE` / `GROUP BY` / `HAVING`. When in doubt, repeat the expression.

Keep this "ladder" in mind when reading the queries below.

---

## 2. Query walk-through

### 2.1 List all movies directed by Christopher Nolan

```sql
SELECT m.title, d.full_name, m.release_year
FROM movie m
JOIN director d ON m.director_id = d.director_id
WHERE d.full_name = 'Christopher Nolan'
ORDER BY m.release_year;
```

- A classic **1:N join**: `movie` (many) → `director` (one).
- `WHERE` filters on a column from the joined table — fine, because after `JOIN` both tables' columns are available.
- `ORDER BY m.release_year` sorts chronologically. Default direction is `ASC`.
- Table **aliases** (`m`, `d`) are optional here but make joins readable; they become essential once the query has three or more tables.

### 2.2 Each movie together with all its genres

```sql
SELECT m.title AS "Movie Title",
       STRING_AGG(g.name, ', ' ORDER BY g.name) AS genres
FROM movie m
JOIN movie_genre mg ON mg.movie_id = m.movie_id
JOIN genre g       ON g.genre_id = mg.genre_id
GROUP BY m.title
ORDER BY m.title;
```

- Two joins to walk an **M:N** relation: `movie → movie_genre → genre`.
- Without aggregation, a movie with 3 genres would appear 3 times. `GROUP BY m.title` collapses it to one row.
- `STRING_AGG(g.name, ', ' ORDER BY g.name)` concatenates all group values into a single comma-separated string, sorted alphabetically.
- The double-quoted alias `"Movie Title"` preserves spaces and case in the column header.

### 2.3 Top 5 movies with the most actors in the cast

```sql
SELECT m.title, COUNT(ma.actor_id) AS amount_of_actors
FROM movie m
JOIN movie_actor ma ON m.movie_id = ma.movie_id
GROUP BY m.movie_id
ORDER BY amount_of_actors DESC
LIMIT 5;
```

- Walks the other M:N relation (`movie ↔ actor`) but stops at the junction table — we only need to **count** links, not see the actors themselves.
- `GROUP BY m.movie_id` (the primary key) is safer than grouping by `m.title` in case two different movies share the same title.
- `ORDER BY ... DESC LIMIT 5` is the standard "top N" idiom in PostgreSQL.

### 2.4 Top 3 actors with the most Comedy roles

```sql
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
```

- Four joins to get from `actor` to `genre`, going through two junction tables. This is the typical shape of a query over two M:N relations that share a middle table (here, `movie`).
- `WHERE g.name = 'Comedy'` filters **before** grouping — we throw away non-Comedy rows first, then count what remains per actor.
- An actor appearing in a movie with two Comedy-tagged genres would be counted twice; if you want "number of Comedy movies" instead, use `COUNT(DISTINCT m.movie_id)`.

### 2.5 Top 5 directors with the most movies

```sql
SELECT d.full_name, COUNT(m.movie_id) AS movie_count
FROM director d
JOIN movie m ON m.director_id = d.director_id
GROUP BY d.director_id
ORDER BY movie_count DESC
LIMIT 5;
```

- The inverse of query 2.1: instead of listing a director's movies, we count them.
- Directors with **zero** movies are excluded because of `INNER JOIN`. Use `LEFT JOIN` from `director` if you want to keep them (with `COUNT(m.movie_id) = 0`, since `COUNT` ignores NULLs).

### 2.6 Actors that have played in BOTH Horror AND Comedy

```sql
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
```

- The clever bit is `HAVING COUNT(DISTINCT g.name) = 2`: the `WHERE` clause already narrowed genres to just those two, so an actor can only reach `2` if they appear in **both**.
- This is the standard pattern for **"must satisfy multiple values at the same time"** via a single table. Writing `WHERE g.name = 'Horror' AND g.name = 'Comedy'` would return nothing, because `g.name` is one value per row.

### 2.7 Actors with the fewest movies (bottom 10)

```sql
SELECT a.full_name, COUNT(ma.movie_id) AS movies_played
FROM actor a
LEFT JOIN movie_actor ma ON a.actor_id = ma.actor_id
GROUP BY a.actor_id
ORDER BY movies_played ASC
LIMIT 10;
```

- `LEFT JOIN` is essential here: it keeps actors who **have no movies at all**. With an inner join they would silently disappear.
- `COUNT(ma.movie_id)` counts non-NULL rows, so unmatched actors score `0` (not `1`). Using `COUNT(*)` would incorrectly score them as `1`, because one "all-NULL" row is still a row.

### 2.8 Actor name and role for every movie they played in

```sql
SELECT m.title, a.full_name, ma.role_name
FROM movie m
JOIN movie_actor ma ON ma.movie_id = m.movie_id
JOIN actor a        ON a.actor_id = ma.actor_id;
```

- A plain detail listing with **no aggregation** — one row per `(movie, actor)` pair.
- Demonstrates that junction tables like `movie_actor` can carry **relationship attributes** (`role_name`) that belong to neither side on its own.

### 2.9 Actors that have only ever played lead roles

```sql
SELECT a.full_name
FROM actor a
JOIN movie_actor ma ON ma.actor_id = a.actor_id
WHERE ma.is_lead_role = TRUE;
```

> ⚠️ This query matches the stated intent only if, in the data set, every actor who appears here has **no** `is_lead_role = FALSE` rows. The safer "only lead roles, never supporting" form is:
>
> ```sql
> SELECT a.full_name
> FROM actor a
> WHERE NOT EXISTS (
>     SELECT 1 FROM movie_actor ma
>     WHERE ma.actor_id = a.actor_id AND ma.is_lead_role = FALSE
> )
> AND EXISTS (
>     SELECT 1 FROM movie_actor ma
>     WHERE ma.actor_id = a.actor_id AND ma.is_lead_role = TRUE
> );
> ```
>
> This pattern ("exists a row that satisfies X **and** there is no row that violates it") is the general way to express "all of this actor's rows are Y".

### 2.10 Actors whose role name starts with "L"

```sql
SELECT a.full_name, ma.role_name
FROM actor a
JOIN movie_actor ma ON ma.actor_id = a.actor_id
WHERE ma.role_name ILIKE 'L%';
```

- `LIKE` is case-sensitive; `ILIKE` (PostgreSQL extension) is case-insensitive.
- Wildcards: `%` = any sequence of characters, `_` = exactly one character.

### 2.11 Actors who worked with more than one director

```sql
SELECT a.full_name,
       COUNT(DISTINCT m.director_id) AS directors_worked_with
FROM actor a
JOIN movie_actor ma ON a.actor_id = ma.actor_id
JOIN movie m        ON m.movie_id = ma.movie_id
JOIN director d     ON m.director_id = d.director_id
GROUP BY a.actor_id
HAVING COUNT(DISTINCT m.director_id) > 1
ORDER BY directors_worked_with DESC, a.full_name;
```

- `COUNT(DISTINCT m.director_id)` dedupes across multiple movies by the same director.
- The `HAVING` clause filters **aggregate groups**; it cannot be moved into `WHERE`.
- `ORDER BY ... DESC, a.full_name` adds a **secondary sort**: actors tied on count are sorted alphabetically.

### 2.12 Youngest and oldest actors on record

```sql
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
```

- `UNION ALL` stacks two result sets vertically. They must have the **same number of columns** with **compatible types**.
- Parentheses around each `SELECT` are needed so that `ORDER BY ... LIMIT 1` applies to each branch, not to the whole combined result.
- `UNION` vs `UNION ALL`: `UNION` removes duplicates (implicit sort + dedupe, more expensive); `UNION ALL` keeps them (cheaper, use it unless you actually need dedup).
- A literal column (`'youngest'`) lets us tell the two rows apart in the output.

### 2.13 Genre count per actor

```sql
SELECT a.full_name, COUNT(DISTINCT g.name) AS genre_count
FROM actor a
JOIN movie_actor ma ON ma.actor_id = a.actor_id
JOIN movie m        ON m.movie_id = ma.movie_id
JOIN movie_genre mg ON mg.movie_id = m.movie_id
JOIN genre g        ON g.genre_id = mg.genre_id
GROUP BY a.actor_id;
```

- Another "go from one entity across two M:N relations" query.
- `COUNT(DISTINCT g.name)` is the important part — without `DISTINCT`, a genre tagged on three different movies the actor played in would be counted three times.

### 2.14 Directors with the most screenings

```sql
SELECT d.full_name, COUNT(s.screening_id) AS screenings_count
FROM director d
JOIN movie m     ON m.director_id = d.director_id
JOIN screening s ON s.movie_id = m.movie_id
GROUP BY d.director_id
ORDER BY screenings_count DESC, d.full_name;
```

- A director → movie (1:N) → screening (1:N) chain.
- No `LIMIT`, so all directors are returned; the interesting ones are at the top.

### 2.15 First and latest movie per director

```sql
SELECT d.full_name,
       MIN(m.release_year) AS first_movie,
       MAX(m.release_year) AS latest_movie
FROM director d
JOIN movie m ON d.director_id = m.director_id
GROUP BY d.director_id;
```

- `MIN` / `MAX` are aggregates — one row per director, two numbers per row.
- Note that we get the **years**, not the movie titles. To return the actual movie titles you would need a correlated sub-query or `DISTINCT ON (director_id)` with an `ORDER BY`.

### 2.16 Actors whose movies sold the most tickets

```sql
SELECT a.full_name, SUM(tb.seat_count) AS total_seats_sold
FROM actor a
JOIN movie_actor ma  ON a.actor_id = ma.actor_id
JOIN movie m         ON m.movie_id = ma.movie_id
JOIN screening s     ON s.movie_id = m.movie_id
JOIN ticket_booking tb ON tb.screening_id = s.screening_id
GROUP BY a.actor_id
ORDER BY total_seats_sold DESC, a.full_name;
```

- Longest chain so far: actor → movie_actor → movie → screening → ticket_booking.
- `SUM` of `seat_count` gives total seats booked across every screening of every movie the actor appeared in.
- Be aware: a booking for a movie with N actors contributes to **all N** of their totals — this is "total seats across movies the actor is in", not "seats the actor sold".

### 2.17 Percentage of seats sold per screening

```sql
SELECT m.title, s.hall_name, s.total_seats,
       (s.total_seats - s.available_seats) AS seats_sold,
       ROUND(100.0 * (s.total_seats - s.available_seats) / s.total_seats, 1)
         AS percentage_sold
FROM screening s
JOIN movie m ON m.movie_id = s.movie_id
ORDER BY percentage_sold DESC;
```

- Pure arithmetic — no aggregation, no grouping.
- `100.0 * ...` forces the division to be floating-point. In PostgreSQL, `integer / integer` truncates, so `95 / 100` is `0`, while `95 * 100.0 / 100` is `95.0`.
- `ROUND(..., 1)` keeps one decimal place for readability.

### 2.18 Average seats per confirmed booking

```sql
SELECT ROUND(AVG(seat_count)::numeric, 2)
FROM ticket_booking
WHERE booking_status = 'confirmed';
```

- `AVG` over an integer column returns `numeric` in PostgreSQL, but the `::numeric` cast is defensive and also lets `ROUND(v, n)` be used (the two-arg form only exists for `numeric`).
- `WHERE` narrows the rows that go into the aggregate; canceled or pending bookings are excluded.

### 2.19 Movies whose synopsis mentions "location"

```sql
SELECT m.title, md.synopsis
FROM movie m
JOIN movie_detail md ON m.movie_id = md.movie_id
WHERE md.synopsis ILIKE '%location%';
```

- `INNER JOIN` drops movies that have no `movie_detail` — acceptable here because a missing synopsis can't match anyway.
- `%location%` finds the substring anywhere in the text. For real free-text search on large catalogues, reach for PostgreSQL full-text search (`to_tsvector` / `to_tsquery`).

### 2.20 Share of each age rating in the catalogue

```sql
SELECT age_rating,
       COUNT(*) AS movies,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)
         AS percentage_of_all_movies
FROM movie
GROUP BY age_rating;
```

- The key trick is `SUM(COUNT(*)) OVER ()` — a **window function** on top of an aggregate.
  - Inner `COUNT(*)` is computed per group (per `age_rating`).
  - `SUM(...) OVER ()` with an empty `OVER ()` then sums those group counts across **all** groups, giving the grand total on every row.
  - Each group's `COUNT(*) / grand_total` is therefore the group's share.
- Without the window function you would need a sub-query or a CTE to get the grand total. `OVER ()` is the clean, one-pass alternative.

### 2.21 Directors who have never had a sold-out screening

```sql
SELECT d.full_name
FROM director d
WHERE NOT EXISTS (
    SELECT 1
    FROM movie m
    JOIN screening s ON m.movie_id = s.movie_id
    WHERE m.director_id = d.director_id
      AND (s.screening_status = 'sold_out' OR s.available_seats = 0)
);
```

- `NOT EXISTS (...)` is the textbook way to express **"there is no row such that..."**.
- The inner `WHERE m.director_id = d.director_id` makes it a **correlated sub-query**: the sub-query is re-evaluated for each candidate director.
- `SELECT 1` is a convention — `EXISTS` only cares whether any row comes back, not what it contains.
- Equivalent options: `LEFT JOIN ... WHERE right_side_pk IS NULL` (anti-join), or `director.id NOT IN (SELECT ...)` (watch out — `NOT IN` returns no rows at all if the sub-query contains a `NULL`).

### 2.22 Movies with no screenings scheduled

```sql
SELECT *
FROM movie m
LEFT JOIN screening s ON s.movie_id = m.movie_id
WHERE s.screening_id IS NULL
ORDER BY m.title;
```

- The classic **anti-join** pattern:
  1. `LEFT JOIN` brings every movie, with NULLs for screening columns when there are none.
  2. `WHERE s.screening_id IS NULL` keeps only the "no match" rows.
- Equivalent to `WHERE NOT EXISTS (SELECT 1 FROM screening s WHERE s.movie_id = m.movie_id)`; choose whichever reads better.

### 2.23 Movies that have a detail row but no tagline

```sql
SELECT *
FROM movie m
JOIN movie_detail md ON m.movie_id = md.movie_id
WHERE md.tagline IS NULL;
```

- `IS NULL` / `IS NOT NULL` — never `= NULL`. In SQL, `NULL` is unknown, and any comparison to it yields unknown, which is treated as false by `WHERE`.

### 2.24 Screenings with zero bookings

```sql
SELECT m.title, s.hall_name, s.starts_at,
       COUNT(tb.screening_id) AS tickets_booked
FROM screening s
JOIN movie m ON m.movie_id = s.movie_id
LEFT JOIN ticket_booking tb ON tb.screening_id = s.screening_id
WHERE tb.booking_status = 'canceled' OR tb.booking_status IS NULL
GROUP BY m.title, s.hall_name, s.starts_at
HAVING COUNT(tb.screening_id) = 0;
```

- `LEFT JOIN` from screening to bookings so that screenings with no bookings at all are preserved.
- The `WHERE tb.booking_status = 'canceled' OR tb.booking_status IS NULL` clause treats canceled bookings as "not really booked", matching the intent.
- `HAVING COUNT(tb.screening_id) = 0` drops screenings that still have at least one non-canceled booking.

### 2.25 Shortest and longest movie

```sql
(SELECT title, duration_minutes, 'shortest' AS label
 FROM movie
 ORDER BY duration_minutes ASC
 LIMIT 1)
UNION ALL
(SELECT title, duration_minutes, 'longest' AS label
 FROM movie
 ORDER BY duration_minutes DESC
 LIMIT 1);
```

- Same `UNION ALL` + `ORDER BY ... LIMIT 1` pattern as 2.12.
- Ties are resolved arbitrarily — if two movies share the minimum duration, only one is returned. To show all tied movies, use a window function (`RANK()`/`DENSE_RANK() OVER (ORDER BY duration_minutes)`).

### 2.26 Actor–director pairs who collaborated on more than one movie

```sql
SELECT a.full_name, d.full_name,
       COUNT(m.movie_id) AS movies_together
FROM actor a
JOIN movie_actor ma ON a.actor_id = ma.actor_id
JOIN movie m        ON m.movie_id = ma.movie_id
JOIN director d     ON m.director_id = d.director_id
GROUP BY a.actor_id, d.full_name
HAVING COUNT(DISTINCT m.movie_id) > 1
ORDER BY movies_together DESC, a.full_name;
```

- Grouping by **two** keys creates one group per `(actor, director)` combination.
- `HAVING COUNT(DISTINCT m.movie_id) > 1` requires at least two **distinct** shared movies. If an actor has multiple roles in the same movie, `COUNT(m.movie_id)` alone could inflate the number; `DISTINCT` guards against that.

### 2.27 Actor's approximate age at each movie's release

```sql
SELECT a.full_name, m.title,
       (m.release_year - a.birth_year) AS age_at_release
FROM actor a
JOIN movie_actor ma ON a.actor_id = ma.actor_id
JOIN movie m        ON m.movie_id = ma.movie_id
WHERE a.birth_year IS NOT NULL
  AND m.release_year IS NOT NULL;
```

- Plain column arithmetic, no aggregation.
- The `IS NOT NULL` guards are necessary because subtraction with `NULL` yields `NULL`, which would then silently populate `age_at_release`.
- "Approximate" because we only have the year on each side, not full dates.

---

## 3. Patterns to remember

| Pattern                                           | Technique                                                |
| ------------------------------------------------- | -------------------------------------------------------- |
| "How many X per Y"                                | `JOIN ... GROUP BY y ... COUNT(x)`                       |
| "Top / bottom N"                                  | `ORDER BY ... LIMIT N`                                   |
| "Groups that satisfy an aggregate condition"      | `HAVING`                                                 |
| "Must appear in BOTH A and B (same column)"       | `WHERE col IN (A,B)` + `HAVING COUNT(DISTINCT col) = 2`  |
| "Keep rows that have no match on the other side"  | `LEFT JOIN ... WHERE right.pk IS NULL` or `NOT EXISTS`   |
| "Share of total"                                  | `value / SUM(value) OVER ()` — window function           |
| "Pick one per group" (first/last, min/max record) | `DISTINCT ON` (PostgreSQL) or `ROW_NUMBER() OVER (...)`  |
| "Stack two result sets"                           | `UNION ALL` (keep duplicates) / `UNION` (dedupe)         |
| "Case-insensitive text match"                     | `ILIKE` (PostgreSQL) or `LOWER(col) LIKE LOWER(pattern)` |
| "Anything compared to NULL"                       | `IS NULL` / `IS NOT NULL`, never `= NULL`                |

---

## 4. Files in this folder

| File                 | Focus                                                      |
| -------------------- | ---------------------------------------------------------- |
| `selecting-data.sql` | All example queries over the cinema schema from `class_03` |
| `README.md`          | This walk-through                                          |

---

## 5. Further reading (PostgreSQL)

- [`SELECT` reference](https://www.postgresql.org/docs/current/sql-select.html)
- [Aggregate functions](https://www.postgresql.org/docs/current/functions-aggregate.html)
- [Window functions](https://www.postgresql.org/docs/current/tutorial-window.html)
- [Pattern matching (`LIKE` / `ILIKE` / regex)](https://www.postgresql.org/docs/current/functions-matching.html)
- [Subquery expressions (`EXISTS`, `IN`, `ANY`, `ALL`)](https://www.postgresql.org/docs/current/functions-subquery.html)
