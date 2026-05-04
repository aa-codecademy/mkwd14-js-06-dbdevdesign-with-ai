import { Router } from 'express';
import * as bookingsController from '../controllers/bookings.controller.js';

const router = Router();

router.post('/', bookingsController.bookTicket);

export default router;
