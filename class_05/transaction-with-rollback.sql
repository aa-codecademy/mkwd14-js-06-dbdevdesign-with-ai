BEGIN;

UPDATE screening
SET available_seats = available_seats - 5
WHERE screening_id = 1;

INSERT INTO ticket_booking (screening_id, customer_name, customer_email, seat_count)
VALUES (1, 'Payment Failed', 'fail@example.com', 5);

-- Inside this transaction the changes are visible:
SELECT screening_id, available_seats FROM screening WHERE screening_id = 1;
SELECT * FROM ticket_booking WHERE customer_email = 'fail@example.com';

-- Payment provider returned an error → undo everything:
ROLLBACK;

-- After ROLLBACK both writes are gone, as if nothing ever happened:
SELECT screening_id, available_seats FROM screening WHERE screening_id = 1;
SELECT * FROM ticket_booking WHERE customer_email = 'fail@example.com';   -- 0 rows