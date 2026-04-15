CREATE TABLE IF NOT EXISTS movies (
	id SERIAL PRIMARY KEY,
	title VARCHAR(120) NOT NULL, 
	ticket_price NUMERIC(8, 2) NOT NULL,
	release_date DATE,
	is_showing BOOL NOT NULL DEFAULT FALSE
);

SELECT * FROM movies;

ALTER TABLE movies
ADD COLUMN hall_name VARCHAR(40);

ALTER TABLE movies
RENAME COLUMN is_showing TO is_showing_now;

ALTER TABLE movies
ADD COLUMN notes TEXT;

ALTER TABLE movies
DROP COLUMN notes;

INSERT INTO movies (title, ticket_price, release_date, is_showing_now, hall_name)
VALUES 
	('Interstellar', 7.50, '2014-11-07', TRUE, 'Hall A'),
    ('The Matrix', 8.00, '1999-03-31', TRUE, 'Hall B'),
    ('Old Test Screening', 5.00, '2001-01-01', FALSE, 'Hall C');

INSERT INTO movies (title, ticket_price, release_date)
VALUES
	('Harry Potter', 10, '2017-01-01')

INSERT INTO movies (title, ticket_price)
VALUES
	('Terminator', 18)

SELECT title, release_date FROM movies;

SELECT title, ticket_price AS "Ticket Price", hall_name AS "Hall Name" FROM movies
WHERE hall_name IS NOT NULL AND is_showing_now = TRUE;

SELECT title, ticket_price AS "Ticket Price", hall_name AS "Hall Name" FROM movies
WHERE ticket_price <= 7.75;

SELECT * FROM movies;

UPDATE movies
SET is_showing_now = TRUE
WHERE title = 'Harry Potter';

DELETE FROM movies
WHERE id = 3;

DROP TABLE movies;

DROP TABLE IF EXISTS movies;

