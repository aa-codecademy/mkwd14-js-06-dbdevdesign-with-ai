-- ============================================================================
-- STORED PROCEDURES  (PL/pgSQL)
-- ============================================================================
--
-- A PROCEDURE is similar to a function but designed for *doing things*
-- (INSERTs, UPDATEs, multi-step business logic) rather than *returning values*.
--
-- Function vs Procedure (PostgreSQL):
--   FUNCTION                          | PROCEDURE
--   --------------------------------- | ----------------------------------------
--   Called from SELECT                 | Called with CALL
--   Must RETURN something              | Can return values via OUT parameters
--   Cannot manage transactions         | Can call COMMIT / ROLLBACK inside
--   Designed to compute & return data  | Designed to execute side effects
--
-- Parameter modes:
--   IN   — input only (the default)
--   OUT  — output only; the caller passes a placeholder (NULL) and reads it back
--   INOUT — both
--
-- LANGUAGE plpgsql gives us:
--   * DECLARE block for local variables
--   * IF / CASE / LOOP control flow
--   * RAISE EXCEPTION (aborts the call) and RAISE NOTICE (prints info)
--   * SELECT ... INTO var to load a single row into variables
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1) sp_book_seats — atomically reserve seats and create a booking
-- ----------------------------------------------------------------------------
-- This is the textbook "money/seats transfer" example. It must:
--   * find the screening and lock the row so no one else can grab the same seats
--   * validate three different business rules
--   * decrement seat counts, flip status to 'sold_out' if needed
--   * insert the booking row and return its id via the OUT parameter
-- All of this happens inside the implicit transaction the CALL runs in, so any
-- RAISE EXCEPTION rolls back every change made by this procedure.
CREATE OR REPLACE PROCEDURE sp_book_seats(
	IN p_screening_id INTEGER,
	IN p_customer_name VARCHAR,
	IN p_customer_email VARCHAR,
	IN p_seat_count INTEGER,
	OUT o_booking_id INTEGER       -- the new ticket_booking_id will be returned here
)
LANGUAGE plpgsql
AS $$
DECLARE
	v_available INTEGER;            -- local var: current available_seats on the screening
	v_status VARCHAR;               -- local var: current screening_status
BEGIN
	-- Read the screening row AND lock it for the rest of the transaction.
	-- FOR UPDATE prevents two concurrent bookings from selling the same seat
	-- twice (a classic race condition).
	SELECT available_seats, screening_status
		INTO v_available, v_status
	FROM screening
	WHERE screening_id = p_screening_id
	FOR UPDATE;

	-- 1) Did the screening exist at all?
	-- "FOUND" is a special PL/pgSQL boolean set by the previous SELECT/UPDATE.
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Screening % not found', p_screening_id;
	END IF;

	-- 2) Is the screening currently selling tickets?
	IF v_status <> 'selling' THEN
		RAISE EXCEPTION 'Screening % is not selling (status=%)', p_screening_id, v_status;
	END IF;

	-- 3) Are there enough seats left?
	IF v_available < p_seat_count THEN
		RAISE EXCEPTION 'Not enough seats: requested: %, available %', p_seat_count, v_available;
	END IF;

	-- All checks passed — decrement seats and (if it just hit zero) mark sold out.
	-- The CASE expression flips the status atomically as part of the same UPDATE.
	UPDATE screening
	SET available_seats = available_seats - p_seat_count,
		screening_status = CASE
			WHEN available_seats - p_seat_count = 0 THEN 'sold_out'
			ELSE screening_status
		END
	WHERE screening_id = p_screening_id;

	-- Insert the booking row and capture the auto-generated id into the OUT param.
	-- RETURNING ... INTO is how PL/pgSQL reads a value from a write statement.
	INSERT INTO ticket_booking (screening_id, customer_name, customer_email, seat_count, booking_status)
	VALUES (p_screening_id, p_customer_name, p_customer_email, p_seat_count, 'confirmed')
	RETURNING ticket_booking_id into o_booking_id;
END;
$$;

-- Calling a procedure uses CALL (not SELECT). The trailing NULL is a placeholder
-- for the OUT parameter — your client tool will fill it in with the new id.
CALL sp_book_seats(1, 'Ivo', 'ivo@example.com', 3, NULL)

SELECT * FROM ticket_booking WHERE ticket_booking_id = 535


-- The four calls below intentionally trip each validation branch:
CALL sp_book_seats(10001, 'Ivo', 'ivo@example.com', 3, NULL)     -- screening not found
CALL sp_book_seats(3, 'Ivo', 'ivo@example.com', 3, NULL)         -- maybe wrong status
CALL sp_book_seats(1, 'Ivo', 'ivo@example.com', 3000, NULL)      -- not enough seats
CALL sp_book_seats(1, 'Ivo', 'ivo@example.com', 93, NULL)        -- not enough seats

-- Inspect the side effects:
SELECT * FROM screening WHERE screening_status != 'selling'
SELECT * FROM screening WHERE screening_id = 1


-- ----------------------------------------------------------------------------
-- 2) sp_cancel_booking — undo a booking and free the seats back up
-- ----------------------------------------------------------------------------
-- Demonstrates the inverse operation, plus an idempotency check: cancelling an
-- already-cancelled booking is a no-op (and emits a NOTICE rather than an
-- exception, because it isn't actually an error).
CREATE OR REPLACE PROCEDURE sp_cancel_booking(IN p_booking_id INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    v_screening_id INTEGER;
    v_seat_count   INTEGER;
    v_status       VARCHAR;
BEGIN
    -- Lock the booking row so a concurrent cancellation can't double-refund seats.
    SELECT screening_id, seat_count, booking_status
      INTO v_screening_id, v_seat_count, v_status
    FROM ticket_booking
    WHERE ticket_booking_id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking % not found', p_booking_id;
    END IF;

    -- Idempotency: if the booking is already cancelled, exit cleanly.
    -- RAISE NOTICE prints to the client log without aborting the procedure.
    IF v_status = 'cancelled' THEN
        RAISE NOTICE 'Booking % already cancelled — nothing to do', p_booking_id;
        RETURN;
    END IF;

    -- Mark the booking cancelled.
    UPDATE ticket_booking
    SET booking_status = 'cancelled'
    WHERE ticket_booking_id = p_booking_id;

    -- Release the seats back into the pool. If the screening had been flipped
    -- to 'sold_out' because of THIS booking, flip it back to 'selling'.
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
