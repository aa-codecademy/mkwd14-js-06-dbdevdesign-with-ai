-- SELECT * FROM ticket_booking
-- 

SELECT * FROM screening WHERE screening_id = 1

BEGIN;

UPDATE screening
SET available_seats = available_seats - 4
WHERE screening_id = 1;

INSERT INTO ticket_booking(screening_id, customer_name, customer_email, seat_count)
VALUES (1, 'Hana Customer', 'hana@example.com', 3);

COMMIT;