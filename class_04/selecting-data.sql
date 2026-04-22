-- List all movies directed by Christopher Nolan.

SELECT m.title, d.full_name, m.release_year
FROM movie m
JOIN director d ON m.director_id = d.director_id
WHERE d.full_name = 'Christopher Nolan'
ORDER BY m.release_year;

-- Show each movie together with all its genres (one row per genre).
SELECT m.title AS "Movie Title", STRING_AGG(g.name, ', ' ORDER BY g.name) AS genres
FROM movie m
JOIN movie_genre mg ON mg.movie_id = m.movie_id
JOIN genre g ON g.genre_id = mg.genre_id
GROUP BY m.title
ORDER BY m.title

-- Top 5 movies with the most actors in the cast
SELECT m.title, COUNT(ma.actor_id) AS amount_of_actors
FROM movie m
JOIN movie_actor ma ON m.movie_id = ma.movie_id
GROUP BY m.movie_id
ORDER BY amount_of_actors DESC
LIMIT 5

-- Top 3 actors that have played mostly in Comedy movies (most Comedy roles).
SELECT a.full_name, COUNT(*) AS comedy_roles
FROM actor a
JOIN movie_actor ma ON a.actor_id = ma.actor_id
JOIN movie m ON m.movie_id = ma.movie_id
JOIN movie_genre mg ON mg.movie_id = m.movie_id
JOIN genre g ON g.genre_id = mg.genre_id
WHERE g.name = 'Comedy'
GROUP BY a.actor_id
ORDER BY comedy_roles DESC
LIMIT 3;

-- Top 5 directors with the most movies.
SELECT d.full_name, COUNT(m.movie_id) AS movie_count
FROM director d
JOIN movie m ON m.director_id = d.director_id
GROUP BY d.director_id
ORDER BY movie_count DESC
LIMIT 5

-- Actors that have played in BOTH Horror and Comedy movies.
SELECT a.full_name
FROM actor a
JOIN movie_actor ma ON a.actor_id = ma.actor_id
JOIN movie m ON m.movie_id = ma.movie_id
JOIN movie_genre mg ON mg.movie_id = m.movie_id
JOIN genre g ON g.genre_id = mg.genre_id
WHERE g.name IN ('Horror', 'Comedy')
GROUP BY a.actor_id
HAVING COUNT(DISTINCT g.name) = 2
ORDER BY a.full_name

-- Actors with the least movies played (show the bottom 10).

SELECT a.full_name, COUNT(ma.movie_id) AS movies_played
FROM actor a
LEFT JOIN movie_actor ma ON a.actor_id = ma.actor_id
GROUP BY a.actor_id
ORDER BY movies_played ASC
LIMIT 10

-- Actor name and role name for every movie they played in.

SELECT m.title, a.full_name, ma.role_name
FROM movie m
JOIN movie_actor ma ON ma.movie_id = m.movie_id
JOIN actor a ON a.actor_id = ma.actor_id

-- Actors that have only ever played lead roles (never a supporting role).

SELECT a.full_name
FROM actor a
JOIN movie_actor ma ON ma.actor_id = a.actor_id
WHERE ma.is_lead_role = TRUE

-- Actors whose role name starts with the letter "L".

SELECT a.full_name, ma.role_name
FROM actor a
JOIN movie_actor ma ON ma.actor_id = a.actor_id
WHERE ma.role_name ILIKE 'L%'

-- Actors who played in movies from more than one director.

SELECT a.full_name, COUNT(DISTINCT m.director_id) AS directors_worked_with
FROM actor a
JOIN movie_actor ma ON a.actor_id = ma.actor_id
JOIN movie m on m.movie_id = ma.movie_id
JOIN director d ON m.director_id = d.director_id
GROUP BY a.actor_id
HAVING COUNT(DISTINCT m.director_id) > 1
ORDER BY directors_worked_with DESC, a.full_name

-- Youngest and oldest actors we have on record.

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
LIMIT 1)

-- For every actor, show the number of genres they have been cast in.

SELECT a.full_name, COUNT(DISTINCT g.name) AS genre_count
FROM actor a
JOIN movie_actor ma ON ma.actor_id = a.actor_id
JOIN movie m ON m.movie_id = ma.movie_id
JOIN movie_genre mg ON mg.movie_id = m.movie_id
JOIN genre g ON g.genre_id = mg.genre_id
GROUP BY a.actor_id

-- Directors with the most screenings scheduled for their movies.

SELECT d.full_name, COUNT(s.screening_id) AS screenings_count
FROM director d
JOIN movie m ON m.director_id = d.director_id
JOIN screening s ON s.movie_id = m.movie_id
GROUP BY d.director_id
ORDER BY screenings_count DESC, d.full_name

-- First and latest movie (by release year) for each director.

SELECT d.full_name, MIN(m.release_year) AS first_movie, MAX(m.release_year) AS latest_movie
FROM director d
JOIN movie m ON d.director_id = m.director_id
GROUP BY d.director_id

-- Actors that have sold the most tickets (by total seats booked) for their movies.

SELECT a.full_name, SUM(tb.seat_count) AS total_seats_sold
FROM actor a
JOIN movie_actor ma ON a.actor_id = ma.actor_id
JOIN movie m ON m.movie_id = ma.movie_id
JOIN screening s ON s.movie_id = m.movie_id
JOIN ticket_booking tb ON tb.screening_id = s.screening_id
GROUP BY a.actor_id
ORDER BY total_seats_sold DESC, a.full_name

-- Percentage of seats sold for each screening.

SELECT m.title, s.hall_name, s.total_seats, (s.total_seats - s.available_seats) AS seats_sold,
			 ROUND(100.0 * (s.total_seats - s.available_seats) / s.total_seats, 1) AS percentage_sold
FROM screening s
JOIN movie m ON m.movie_id = s.movie_id
ORDER BY percentage_sold DESC

-- Average number of seats per booking.

SELECT ROUND(AVG(seat_count)::numeric, 2)
FROM ticket_booking
WHERE booking_status = 'confirmed'

-- Movies whose synopsis mentions "location".

SELECT m.title, md.synopsis
FROM movie m
JOIN movie_detail md ON m.movie_id = md.movie_id
WHERE md.synopsis ILIKE '%location%'

-- Share of each age rating in the catalog (percentage of total movies).

SELECT age_rating, COUNT(*) as movies, ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) as percentage_of_all_movies
FROM movie
GROUP BY age_rating

-- Directors who have never had a sold-out screening

SELECT d.full_name
FROM director d
WHERE NOT EXISTS (
			SELECT 1
			FROM movie m
			JOIN screening s ON m.movie_id = s.movie_id
			WHERE m.director_id = d.director_id
				AND (s.screening_status = 'sold_out' OR s.available_seats = 0)
		)

-- Movies that have NO screenings scheduled.

SELECT *
FROM movie m
LEFT JOIN screening s ON s.movie_id = m.movie_id
WHERE s.screening_id IS NULL
ORDER BY m.title

-- Movies that have a movie_detail row but no tagline.

SELECT *
FROM movie m
JOIN movie_detail md ON m.movie_id = md.movie_id
WHERE md.tagline IS NULL

-- Screenings with zero bookings.

SELECT m.title, s.hall_name, s.starts_at, COUNT(tb.screening_id) AS tickets_booked
FROM screening s
JOIN movie m ON m.movie_id = s.movie_id
LEFT JOIN ticket_booking tb ON tb.screening_id = s.screening_id
WHERE tb.booking_status = 'canceled' OR tb.booking_status IS NULL
GROUP BY m.title, s.hall_name, s.starts_at
HAVING COUNT(tb.screening_id) = 0

-- Shortest and longest movie in the catalog.

(SELECT title, duration_minutes, 'shortest' AS label
FROM movie
ORDER BY duration_minutes ASC
LIMIT 1)
UNION ALL
(SELECT title, duration_minutes, 'longest' AS label
FROM movie
ORDER BY duration_minutes DESC
LIMIT 1)

-- Actor-director pairs that have collaborated on more than one movie.

SELECT a.full_name, d.full_name, COUNT(m.movie_id) as movies_together
FROM actor a
JOIN movie_actor ma ON a.actor_id = ma.actor_id
JOIN movie m ON m.movie_id = ma.movie_id
JOIN director d ON m.director_id = d.director_id
GROUP BY a.actor_id, d.full_name
HAVING COUNT(DISTINCT m.movie_id) > 1
ORDER BY movies_together DESC, a.full_name

-- Approximate age of each actor at the time their movie was released

SELECT a.full_name, m.title, (m.release_year - a.birth_year) AS age_at_release
FROM actor a
JOIN movie_actor ma ON a.actor_id = ma.actor_id
JOIN movie m ON m.movie_id = ma.movie_id
WHERE a.birth_year IS NOT NULL AND m.release_year IS NOT NULL
