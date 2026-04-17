-- =============================================================================
-- TABLES, COLUMNS, AND BASIC DATA MANIPULATION (DDL + DML)
-- =============================================================================
-- **DDL** (Data Definition Language): CREATE, ALTER, DROP — changes structure.
-- **DML** (Data Manipulation Language): SELECT, INSERT, UPDATE, DELETE — changes data.
--
-- Flow of this lesson file:
-- 1. CREATE a `movies` table with constraints (NOT NULL, DEFAULT).
-- 2. ALTER the table: add/rename/drop columns — schema evolves over time.
-- 3. INSERT rows — watch how DEFAULT and nullable columns behave.
-- 4. SELECT with filters — restrict which rows/columns you see.
-- 5. UPDATE and DELETE — change or remove specific rows.
-- 6. DROP TABLE — remove the whole table (destructive).
-- =============================================================================

-- CREATE TABLE: defines name, columns, and rules for each column.
-- IF NOT EXISTS: avoids an error if you re-run the script during practice.
-- SERIAL: auto primary key. NOT NULL: column must have a value on INSERT.
-- DEFAULT FALSE: if INSERT omits `is_showing`, the row gets FALSE automatically.
CREATE TABLE IF NOT EXISTS movies (
	id SERIAL PRIMARY KEY,
	title VARCHAR(120) NOT NULL,
	ticket_price NUMERIC(8, 2) NOT NULL,
	release_date DATE,
	is_showing BOOL NOT NULL DEFAULT FALSE
);

-- SELECT *: all columns, all rows. On a new table this shows column names with
-- zero data rows — useful to confirm the structure.
SELECT * FROM movies;

-- =============================================================================
-- ALTER TABLE — CHANGE SCHEMA WITHOUT DROPPING THE TABLE
-- =============================================================================

-- ADD COLUMN: new nullable column `hall_name` (no NOT NULL yet, so existing and
-- future rows may have NULL until you backfill data).
ALTER TABLE movies
ADD COLUMN hall_name VARCHAR(40);

-- RENAME COLUMN: keeps data; only the name changes (apps/queries must use new name).
ALTER TABLE movies
RENAME COLUMN is_showing TO is_showing_now;

-- Add optional notes, then remove them — demonstrates DROP COLUMN.
ALTER TABLE movies
ADD COLUMN notes TEXT;

ALTER TABLE movies
DROP COLUMN notes;

-- =============================================================================
-- INSERT — ADD ROWS
-- =============================================================================
-- Explicit column list: VALUES must match column order and count.
-- Booleans: TRUE/FALSE. Dates: 'YYYY-MM-DD' string literals (PostgreSQL casts them).
INSERT INTO movies (title, ticket_price, release_date, is_showing_now, hall_name)
VALUES
	('Interstellar', 7.50, '2014-11-07', TRUE, 'Hall A'),
    ('The Matrix', 8.00, '1999-03-31', TRUE, 'Hall B'),
    ('Old Test Screening', 5.00, '2001-01-01', FALSE, 'Hall C');

-- Partial INSERT: omitted columns use DEFAULT or NULL.
-- Here `is_showing_now` is omitted → DEFAULT FALSE from table definition.
-- `hall_name` omitted → NULL (column allows NULL).
INSERT INTO movies (title, ticket_price, release_date)
VALUES
	('Harry Potter', 10, '2017-01-01');

-- Even fewer columns: only title and ticket_price; release_date NULL, default for is_showing_now.
INSERT INTO movies (title, ticket_price)
VALUES
	('Terminator', 18);

-- =============================================================================
-- SELECT — READ DATA WITH PROJECTION AND FILTERS
-- =============================================================================

-- **Projection**: list only the columns you need (smaller result, clearer intent).
SELECT title, release_date FROM movies;

-- **Filtering**: WHERE keeps rows that match the condition.
-- AND combines conditions (both must be true).
-- Double-quoted aliases preserve spaces/case in the result header (PostgreSQL).
SELECT title, ticket_price AS "Ticket Price", hall_name AS "Hall Name" FROM movies
WHERE hall_name IS NOT NULL AND is_showing_now = TRUE;

-- Comparison operator <= : numeric comparison on ticket_price.
SELECT title, ticket_price AS "Ticket Price", hall_name AS "Hall Name" FROM movies
WHERE ticket_price <= 7.75;

-- SELECT * again: now you should see every column for every row that survived so far.
SELECT * FROM movies;

-- =============================================================================
-- UPDATE — CHANGE EXISTING ROWS
-- =============================================================================
-- UPDATE … SET … WHERE: without WHERE, you would update **all** rows — always
-- double-check the WHERE clause in production.
UPDATE movies
SET is_showing_now = TRUE
WHERE title = 'Harry Potter';

-- =============================================================================
-- DELETE — REMOVE ROWS (NOT THE TABLE)
-- =============================================================================
-- Deletes the row whose primary key is 3 (id values depend on insert order).
DELETE FROM movies
WHERE id = 3;

-- =============================================================================
-- DROP TABLE — REMOVE THE TABLE OBJECT ENTIRELY
-- =============================================================================
-- DROP TABLE: irreversible data loss for that table. CASCADE is not used here.
DROP TABLE movies;

-- DROP IF EXISTS: safe re-runs when the table might already be gone.
DROP TABLE IF EXISTS movies;
