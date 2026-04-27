-- ============================================================================
-- TRANSACTIONS — using ROLLBACK to undo work
-- ============================================================================
--
-- This script shows the OTHER half of the transaction story: when something
-- goes wrong (validation error, payment failure, business rule violation),
-- you can ROLLBACK and the database behaves as if nothing happened.
--
-- The classic real-world scenario:
--   1. Reserve seats and create a tentative booking.
--   2. Charge the customer's card via an external payment provider.
--   3a. Payment OK  → COMMIT     → seats are sold, booking is permanent.
--   3b. Payment FAIL → ROLLBACK  → both writes vanish, no orphaned booking.
-- ============================================================================


-- Start the transaction. Every statement below is held in a "private workspace"
-- visible only to this session until we commit or roll back.
BEGIN;

-- Tentatively reduce the available seats.
UPDATE screening
SET available_seats = available_seats - 5
WHERE screening_id = 1;

-- Tentatively create the booking row.
INSERT INTO ticket_booking (screening_id, customer_name, customer_email, seat_count)
VALUES (1, 'Payment Failed', 'fail@example.com', 5);

-- Inside this transaction the changes ARE visible to us — but only us.
-- Another session running these same SELECTs would still see the OLD values
-- (this is the "Isolation" part of ACID).
SELECT screening_id, available_seats FROM screening WHERE screening_id = 1;
SELECT * FROM ticket_booking WHERE customer_email = 'fail@example.com';

-- Imagine the payment provider returned an error here.
-- ROLLBACK throws away every write made since BEGIN.
ROLLBACK;

-- After ROLLBACK both writes are gone, as if nothing ever happened.
-- The seat count is back to its original value, and the booking row never
-- became visible to other sessions.
SELECT screening_id, available_seats FROM screening WHERE screening_id = 1;
SELECT * FROM ticket_booking WHERE customer_email = 'fail@example.com';   -- 0 rows
