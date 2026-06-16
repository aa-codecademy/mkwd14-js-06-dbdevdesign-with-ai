---
applyTo: "src/routes/**/*.js"
---

<!--
  Applied only to route files. Routes are the entry point for every HTTP
  request — these rules define exactly what belongs here and what doesn't.
-->

# Routes instructions

## Router setup

Each domain gets its own file with a dedicated `Router` instance, then mounted in `src/routes/index.js`.

```js
// src/routes/movies.routes.js
import { Router } from 'express';
import * as moviesController from '../controllers/movies.controller.js';
import { validate } from '../middleware/validate.js';
import { idParamSchema, listQuerySchema } from '../schemas/movie.schema.js';

const router = Router();

router.get('/', validate({ query: listQuerySchema }), moviesController.list);
router.get('/:id', validate({ params: idParamSchema }), moviesController.getById);

export default router;
```

## Mounting in index.js

```js
// src/routes/index.js
router.use('/movies', moviesRoutes);
router.use('/bookings', bookingsRoutes);
```

## Middleware order

Middleware runs left to right. Always put `validate` before the controller:

```js
router.post('/', validate({ body: createBookingSchema }), controller.create);
```

## What routes must not contain

- SQL queries
- Business logic or conditionals
- Direct `res.json()` calls (except the `/health` endpoint in `index.js`)
- `try/catch` blocks

## HTTP method and status code conventions

| Operation | Method | Success status |
|---|---|---|
| List resources | GET | 200 |
| Get one resource | GET | 200 |
| Create resource | POST | 201 |
| Full replace | PUT | 200 |
| Partial update | PATCH | 200 |
| Delete | DELETE | 204 (no body) |

Controllers set non-200 success codes explicitly: `res.status(201).json(result)`.
