import { Router } from 'express';
import * as moviesController from '../controllers/movies.controller.js';

const router = new Router();

// GET /localhost:3000/api/movies
router.get('/', moviesController.list);

export default router;
