import { Router } from 'express';
import { pool } from '../config/db.js';
import moviesRoutes from './movies.routes.js';

const router = Router();

router.get('/health', async (req, res) => {
	try {
		const result = await pool.query('SELECT NOW() AS now');
		res.status(200).json({ status: 'OK', time: result.rows[0].now });
	} catch (error) {
		console.error(error);
		res.status(500).json({ status: 'Error', message: error.message });
	}
});

router.use('/movies', moviesRoutes);

export default router;
