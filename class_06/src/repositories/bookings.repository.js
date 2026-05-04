import { pool } from '../config/db.js';

export async function create({
	customerName,
	customerEmail,
	screeningId,
	seatCount,
}) {
	const result = pool.query(
		`
			INSERT INTO ticket_booking (screening_id, customer_name, customer_email, seat_count, booking_status)
			VALUES ($1, $2, $3, $4, 'confirmed')
			RETURNING ticket_booking_id, screening_id, customer_name, customer_email, seat_count, booking_status, booked_at
		`,
		[screeningId, customerName, customerEmail, seatCount],
	);

	return result;
}
