CREATE INDEX idx_movie_title_lower
	ON movie(LOWER(title))


SELECT * FROM movie
WHERE title ILIKE '%co%'