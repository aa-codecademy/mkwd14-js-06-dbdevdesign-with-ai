import { Router } from 'express';
import * as moviesController from '../controllers/movies.controller.js';
import * as screeningsController from '../controllers/screenings.controller.js';

const router = new Router();

// GET /api/movies -> list movies (supports filters in query string).
router.get('/', moviesController.list);

// GET /api/movies/:id -> details for one movie.
router.get('/:id', moviesController.getById);

// GET /api/movies/:id/screenings -> screening details for one movie.
router.get('/:id/screenings', screeningsController.listScreeningsByMovieId);

export default router;
