import { Router } from 'express';
import * as moviesController from '../controllers/movies.controller.js';
import * as screeningsController from '../controllers/screenings.controller.js';
import { validate } from '../middleware/validate.js';
import { idParamsSchema, querySchema } from '../schemas/shared.schema.js';

const router = new Router();

// GET /api/movies -> list movies (supports filters in query string).
router.get('/', validate({ query: querySchema }), moviesController.list);

// GET /api/movies/:id -> details for one movie.
router.get(
	'/:id',
	validate({ params: idParamsSchema }),
	moviesController.getById,
);

// GET /api/movies/:id/screenings -> screening details for one movie.
router.get(
	'/:id/screenings',
	validate({ params: idParamsSchema }),
	screeningsController.listScreeningsByMovieId,
);

export default router;
