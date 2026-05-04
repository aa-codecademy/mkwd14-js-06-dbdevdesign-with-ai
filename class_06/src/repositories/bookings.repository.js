import { pool } from '../config/db.js';

export async function create({
	customerName,
	customerEmail,
	screeningId,
	seatCount,
}) {
	const client = await pool.connect();

	try {
		await client.query('BEGIN');

		const screeningResult = await client.query(
			`
				SELECT
					screening_id,
					available_seats,
					screening_status,
					starts_at
				FROM screening
				WHERE screening_id = $1
				FOR UPDATE
			`,
			[screeningId],
		);

		const screening = screeningResult.rows[0];

		if (!screening) {
			throw new Error('SCREENING_NOT_FOUND');
		}

		if (screening.starts_at <= new Date()) {
			throw new Error('SCREENING_ENDED');
		}

		if (screening.screening_status !== 'selling') {
			throw new Error('SCREENING_NOT_SELLING');
		}

		if (screening.available_seats < seatCount) {
			throw new Error('NOT_ENOUGH_SEATS');
		}

		const ticketBookingResult = await client.query(
			`
				INSERT INTO ticket_booking (screening_id, customer_name, customer_email, seat_count, booking_status)
				VALUES ($1, $2, $3, $4, 'confirmed')
				RETURNING ticket_booking_id, screening_id, customer_name, customer_email, seat_count, booking_status, booked_at
			`,
			[screeningId, customerName, customerEmail, seatCount],
		);

		await client.query(
			`
				UPDATE screening
				SET available_seats = available_seats - $1,
					screening_status = CASE
						WHEN available_seats - $1 = 0 THEN 'sold_out'
						ELSE screening_status
					END
				WHERE screening_id = $2
			`,
			[seatCount, screeningId],
		);

		await client.query('COMMIT');

		const result = ticketBookingResult.rows[0];
		return result;
	} catch (error) {
		await client.query('ROLLBACK');
		throw error;
	} finally {
		client.release();
	}
}
