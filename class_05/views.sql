-- VIEW

CREATE VIEW v_movie_overview AS
SELECT m.movie_id, m.title, m.release_year, m.age_rating, m.duration_minutes, d.full_name as director_name, md.tagline, 
		STRING_AGG(g.name, ', ' ORDER BY g.name) as genres
FROM movie m
JOIN director d ON m.director_id = d.director_id
LEFT JOIN movie_genre mg ON mg.movie_id = m.movie_id
LEFT JOIN genre g ON g.genre_id = mg.genre_id
LEFT JOIN movie_detail md ON md.movie_id = m.movie_id
GROUP BY m.movie_id, m.title, m.release_year, m.age_rating, m.duration_minutes, d.full_name, md.tagline

SELECT * FROM v_movie_overview
WHERE release_year >= 2024

-- MATERIALIZED VIEW

CREATE MATERIALIZED VIEW mv_movie_overview AS
SELECT m.movie_id, m.title, m.release_year, m.age_rating, m.duration_minutes, d.full_name as director_name, md.tagline, 
		STRING_AGG(g.name, ', ' ORDER BY g.name) as genres
FROM movie m
JOIN director d ON m.director_id = d.director_id
LEFT JOIN movie_genre mg ON mg.movie_id = m.movie_id
LEFT JOIN genre g ON g.genre_id = mg.genre_id
LEFT JOIN movie_detail md ON md.movie_id = m.movie_id
GROUP BY m.movie_id, m.title, m.release_year, m.age_rating, m.duration_minutes, d.full_name, md.tagline

INSERT INTO movie (director_id, title, release_year, duration_minutes, age_rating) VALUES
				(1, 'Balcancan', 2005, 90, 'PG-13')

SELECT * FROM mv_movie_overview
WHERE release_year >= 2024

REFRESH MATERIALIZED VIEW mv_movie_overview