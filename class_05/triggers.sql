SELECT * FROM movie

ALTER TABLE movie
	ADD COLUMN updated_at TIMESTAMP NULL;

CREATE OR REPLACE FUNCTION fn_trg_movie_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
	NEW.updated_at := CURRENT_TIMESTAMP;
	RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_movie_set_udpdated_at ON movie;
CREATE TRIGGER trg_movie_set_udpdated_at
BEFORE UPDATE ON movie
FOR EACH ROW
EXECUTE FUNCTION fn_trg_movie_set_updated_at();

UPDATE movie
SET title = 'Test'
WHERE movie_id = 1;