CREATE OR REPLACE PROCEDURE sp_book_seats(
	IN p_screening_id INTEGER,
	IN p_customer_name VARCHAR,
	IN p_customer_email VARCHAR,
	IN p_seat_count INTEGER,
	OUT o_booking_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
	v_available INTEGER;
	v_status VARCHAR;
BEGIN
	SELECT available_seats, screening_status
		INTO v_available, v_status
	FROM screening
	WHERE screening_id = p_screening_id
	FOR UPDATE;

	IF NOT FOUND THEN
		RAISE EXCEPTION 'Screening % not found', p_screening_id;
	END IF;

	IF v_status <> 'selling' THEN
		RAISE EXCEPTION 'Screening % is not selling (status=%)', p_screening_id, v_status;
	END IF;

	IF v_available < p_seat_count THEN
		RAISE EXCEPTION 'Not enough seats: requested: %, available %', p_seat_count, v_available;
	END IF;

	UPDATE screening
	SET available_seats = available_seats - p_seat_count,
		screening_status = CASE
			WHEN available_seats - p_seat_count = 0 THEN 'sold_out'
			ELSE screening_status
		END
	WHERE screening_id = p_screening_id;

	INSERT INTO ticket_booking (screening_id, customer_name, customer_email, seat_count, booking_status)
	VALUES (p_screening_id, p_customer_name, p_customer_email, p_seat_count, 'confirmed')
	RETURNING ticket_booking_id into o_booking_id;
END;
$$;

CALL sp_book_seats(1, 'Ivo', 'ivo@example.com', 3, NULL)

SELECT * FROM ticket_booking WHERE ticket_booking_id = 535

CALL sp_book_seats(10001, 'Ivo', 'ivo@example.com', 3, NULL)
CALL sp_book_seats(3, 'Ivo', 'ivo@example.com', 3, NULL)
CALL sp_book_seats(1, 'Ivo', 'ivo@example.com', 3000, NULL)
CALL sp_book_seats(1, 'Ivo', 'ivo@example.com', 93, NULL)

SELECT * FROM screening WHERE screening_status != 'selling'
SELECT * FROM screening WHERE screening_id = 1


CREATE OR REPLACE PROCEDURE sp_cancel_booking(IN p_booking_id INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_screening_id INTEGER;
    v_seat_count   INTEGER;
    v_status       VARCHAR;
BEGIN
    SELECT screening_id, seat_count, booking_status
      INTO v_screening_id, v_seat_count, v_status
    FROM ticket_booking
    WHERE ticket_booking_id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking % not found', p_booking_id;
    END IF;
    IF v_status = 'cancelled' THEN
        RAISE NOTICE 'Booking % already cancelled — nothing to do', p_booking_id;
        RETURN;
    END IF;

    UPDATE ticket_booking
    SET booking_status = 'cancelled'
    WHERE ticket_booking_id = p_booking_id;

    UPDATE screening
    SET available_seats = available_seats + v_seat_count,
        screening_status = CASE
            WHEN screening_status = 'sold_out' THEN 'selling'
            ELSE screening_status
        END
    WHERE screening_id = v_screening_id;
END;
$$;

CALL sp_cancel_booking(535)