# GitHub Copilot Instructions

<!--
  This file teaches Copilot the rules of this project so its suggestions
  match the patterns already in the codebase. Without it, Copilot falls
  back to generic Node.js defaults that may not fit this architecture.
-->

## Project overview

Cinema booking REST API built with **Node.js + Express 5**, **PostgreSQL** (via `pg` Pool), and **Zod v4** for validation. All source files use **ES Modules** (`"type": "module"` in package.json).

## Architecture — strict 4-layer separation

Every feature follows this call chain and must not skip layers:

```
routes → controller → service → repository
```

- **Routes** (`src/routes/`) — mount middleware (validate), call controller functions, nothing else.
- **Controllers** (`src/controllers/`) — read `req`, call one service function, call `res.json()`. No SQL, no business logic.
- **Services** (`src/services/`) — map raw HTTP input to domain values, orchestrate repository calls. No `req`/`res`.
- **Repositories** (`src/repositories/`) — all SQL lives here and only here. Accept plain JS values, return plain JS objects.

## Module system

Use ES Module syntax exclusively:

```js
import { Router } from 'express';
import * as moviesService from '../services/movies.service.js';
```

Always include the `.js` extension in relative imports. Never use `require()`.

## File naming

```
src/routes/movies.routes.js
src/controllers/movies.controller.js
src/services/movies.service.js
src/repositories/movies.repository.js
src/schemas/movie.schema.js
```

Each domain has one file per layer. New domains follow the same pattern.

## Error handling

Throw errors from any layer — Express 5 catches async errors automatically. Pass unexpected errors to `next(error)` in controllers only when needed.

Use the custom error hierarchy from `src/types/error.js`:

```js
import { NotFoundError, BadRequestError } from '../types/error.js';

throw new NotFoundError('Movie not found');
throw new BadRequestError('Invalid input');
```

Never call `res.status(500)` directly. Let `errorHandler` middleware handle all error responses.

## Validation

Validate all untrusted input (request body, params, query) with Zod schemas placed in `src/schemas/`. Apply them via the `validate` middleware — never inline in controllers:

```js
router.post('/', validate({ body: createBookingSchema }), controller.create);
```

## Database

Use the shared `pool` from `src/config/db.js`. Always use parameterized queries (`$1`, `$2`, …). Never interpolate user values directly into SQL strings.

Aggregate related rows in SQL using `json_agg` + `json_build_object`. Wrap aggregations with `COALESCE(..., '[]'::json)` so the API returns an empty array instead of `null`.

## Do not

- Do not use an ORM (Sequelize, Prisma, etc.).
- Do not add TypeScript, Jest, or other dependencies not in `package.json`.
- Do not use `var`. Prefer `const`; use `let` only when reassignment is needed.
- Do not add `try/catch` in repositories — let errors propagate.
- Do not use `commonjs` (`require`/`module.exports`).
