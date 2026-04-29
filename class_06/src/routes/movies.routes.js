import { Router } from 'express';
import * as moviesController from '../controllers/movies.controller.js';

const router = new Router();

// GET /api/movies -> list movies (supports filters in query string).
router.get('/', moviesController.list);

// GET /api/movies/:id -> details for one movie.
router.get('/:id', moviesController.getById);

export default router;
