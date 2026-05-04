import { BadRequestError } from '../types/error.js';

export function validate(schema = {}) {
	return (req, res, next) => {
		try {
			if (schema.params) {
				req.params = schema.params.parse(req.params);
			}
			if (schema.query) {
				req.query = schema.query.parse(req.query);
			}
			if (schema.body) {
				req.body = schema.body.parse(req.body);
			}
			next();
		} catch (error) {
			if (error?.issues) {
				const message = error.issues
					.map(issue => `${issue.path.join('.') || '(root)'}: ${issue.message}`)
					.join('; ');
				return next(new BadRequestError(message));
			}
			next(error);
		}
	};
}
