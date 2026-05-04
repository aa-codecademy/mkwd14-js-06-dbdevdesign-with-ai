import { Router } from 'express';
import { pool } from '../config/db.js';
import moviesRoutes from './movies.routes.js';
import bookingsRoutes from './bookings.routes.js';

const router = Router();

// Simple health-check route to verify API + database connectivity.
router.get('/health', async (req, res) => {
	try {
		const result = await pool.query('SELECT NOW() AS now');
		res.status(200).json({ status: 'OK', time: result.rows[0].now });
	} catch (error) {
		console.error(error);
		res.status(500).json({ status: 'Error', message: error.message });
	}
});

// Group movie-related endpoints under /api/movies.
router.use('/movies', moviesRoutes);

// Group booking-related endpoints under /api/bookings.
router.use('/bookings', bookingsRoutes);

export default router;
