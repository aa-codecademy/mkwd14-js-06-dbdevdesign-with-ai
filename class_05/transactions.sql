-- ============================================================================
-- TRANSACTIONS  —  "all-or-nothing" units of work
-- ============================================================================
--
-- A transaction groups several statements so that either ALL of them are
-- applied to the database, or NONE of them are. This is the foundation of data
-- integrity in any serious application.
--
-- ACID properties (what a transaction guarantees):
--   * Atomicity   — all statements succeed, or none of them do.
--   * Consistency — the database moves from one valid state to another.
--   * Isolation   — concurrent transactions don't see each other's half-done work.
--   * Durability  — once COMMIT returns, the change survives crashes/power loss.
--
-- Lifecycle:
--   BEGIN;          -- open the transaction
--   ... statements ...
--   COMMIT;         -- make all changes permanent
--   -- or --
--   ROLLBACK;       -- discard everything done since BEGIN
--
-- Without an explicit BEGIN, every single statement is its own transaction
-- (auto-commit). Wrapping multiple statements in BEGIN/COMMIT lets you keep
-- related changes consistent.
-- ============================================================================


-- (Reference query — the row we are about to modify.)
SELECT * FROM screening WHERE screening_id = 1


-- Open a new transaction. From here until COMMIT or ROLLBACK, every change is
-- "tentative" — visible to this session, invisible to everyone else.
BEGIN;

-- Reserve 4 seats on screening #1.
UPDATE screening
SET available_seats = available_seats - 4
WHERE screening_id = 1;

-- Record the booking that consumes those seats.
-- Both writes belong together: it would be a bug to have one without the other.
INSERT INTO ticket_booking(screening_id, customer_name, customer_email, seat_count)
VALUES (1, 'Hana Customer', 'hana@example.com', 3);

-- Make both changes permanent and visible to all other sessions.
-- If anything between BEGIN and COMMIT had failed, we would issue ROLLBACK
-- instead and the database would be untouched.
COMMIT;
