import { HttpError } from '../types/error.js';

export async function errorHandler(err, req, res, next) {
	console.error(err);

	const status = err instanceof HttpError ? err.statusCode : 500;

	res.status(status).json({ message: err.message });
}
