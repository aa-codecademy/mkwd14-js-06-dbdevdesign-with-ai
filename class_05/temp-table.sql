-- TEMPORARY TABLE

CREATE TEMPORARY TABLE tmp_recent_movies AS
SELECT movie_id, title, release_year, age_rating, director_id
FROM movie
WHERE release_year >= 2020

SELECT COUNT(*) AS recent_movies_count FROM tmp_recent_movies

SELECT *
FROM director d
JOIN tmp_recent_movies tmp_m ON d.director_id = tmp_m.director_id