-- ============================================================================
-- TRIGGERS
-- ============================================================================
--
-- A TRIGGER is a piece of code that the database runs AUTOMATICALLY in
-- response to an event on a table (INSERT / UPDATE / DELETE / TRUNCATE).
-- Triggers are perfect for cross-cutting rules that must hold no matter how
-- the data is changed (from an app, from a migration, from a manual UPDATE):
--
--   * audit logging                        (who changed what, when)
--   * automatic timestamps                 (`updated_at`, `created_at`)
--   * derived/denormalized columns         (cached counts, totals)
--   * validation that can't be expressed as a CHECK constraint
--
-- Anatomy:
--   1. A trigger function (`RETURNS TRIGGER`) that contains the logic.
--      Inside it, two special records are available:
--          NEW  — the row as it WILL look after the operation (INSERT/UPDATE)
--          OLD  — the row as it looked BEFORE the operation (UPDATE/DELETE)
--   2. A CREATE TRIGGER statement that ties the function to a table and event.
--
-- Timing matters:
--   BEFORE  — runs before the row is written; can modify NEW.* in place.
--   AFTER   — runs after the row is written; usually used for logging / cascades.
-- ============================================================================


-- (Sanity check — verify the table exists before we ALTER it.)
SELECT * FROM movie


-- 1) Add the column the trigger will populate.
-- We allow NULL so existing rows don't need a value retroactively.
ALTER TABLE movie
	ADD COLUMN updated_at TIMESTAMP NULL;


-- 2) Define the trigger function.
-- It returns the (possibly modified) NEW row that will be written to disk.
-- Setting `NEW.updated_at` here is why we need a BEFORE trigger — by the time
-- an AFTER trigger runs, the row is already written and changing NEW has no effect.
CREATE OR REPLACE FUNCTION fn_trg_movie_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
	NEW.updated_at := CURRENT_TIMESTAMP;   -- stamp the row with "now"
	RETURN NEW;                            -- proceed with the (modified) write
END;
$$;


-- 3) Attach the function to the `movie` table.
-- DROP IF EXISTS first makes the script safe to re-run.
DROP TRIGGER IF EXISTS trg_movie_set_udpdated_at ON movie;

-- BEFORE UPDATE — fires for every row about to be UPDATEd, before the change
-- is persisted, so we can set `updated_at` for free without the application
-- having to remember to do it.
CREATE TRIGGER trg_movie_set_udpdated_at
BEFORE UPDATE ON movie
FOR EACH ROW
EXECUTE FUNCTION fn_trg_movie_set_updated_at();


-- 4) Demo: any UPDATE — from anywhere — now stamps `updated_at` automatically.
-- Run this and then SELECT the row: `updated_at` will hold the current time,
-- even though our UPDATE statement never mentioned that column.
UPDATE movie
SET title = 'Test'
WHERE movie_id = 1;
