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

-- Actor name and role name for every movie they played in.

-- Actors that have only ever played lead roles (never a supporting role).

-- Actors whose role name starts with the letter "K".

-- Actors who played in movies from more than one director.

--  Youngest and oldest actors we have on record.

-- For every actor, show the number of genres they have been cast in.

-- Directors with the most screenings scheduled for their movies.

-- First and latest movie (by release year) for each director.

-- Actors that have sold the most tickets (by total seats booked) for their movies.

-- Total seats sold per movie (top 10).

-- Percentage of seats sold for each screening.

-- Average number of seats per booking.

-- Movies whose synopsis mentions "family".

-- Movies that have NO screenings scheduled.

-- Movies that have a movie_detail row but no tagline.

-- Screenings with zero bookings.

-- Shortest and longest movie in the catalog.

-- Actor-director pairs that have collaborated on more than one movie.

-- Approximate age of each actor at the time their movie was released

-- Directors who have never had a sold-out screening


