# Class 06 — First SQL API with Express + PostgreSQL

In previous classes we focused on SQL itself.
This class connects that SQL knowledge to a real Node.js application:

- Express receives HTTP requests
- a service/repository structure organizes backend code
- the `pg` client runs SQL queries
- PostgreSQL returns rows that become JSON API responses

This is the first complete "database-backed API" example in the course.

---

## 1. Main architecture in this class

The backend follows a layered flow:

`Route -> Controller -> Service -> Repository -> PostgreSQL`

Each layer has one responsibility:

- **Routes** (`src/routes/*.js`) map URL paths and HTTP methods.
- **Controller** (`src/controllers/movies.controller.js`) reads request input and returns responses.
- **Service** (`src/services/movies.service.js`) transforms input into domain-friendly values.
- **Repository** (`src/repositories/movies.repository.js`) contains SQL and database access.
- **DB config** (`src/config/db.js`) creates a reusable PostgreSQL connection pool.

Why this split matters:

- SQL is isolated in one place.
- HTTP code stays separate from query logic.
- Each layer is easier to test and refactor.

---

## 2. Request flow example

When the client calls:

`GET /api/movies?search=dark&genre=Drama&nowShowing=true&limit=10&offset=0`

the app does this:

1. `movies.routes.js` maps the request to `moviesController.list`.
2. Controller forwards `req.query` to the service.
3. Service converts values (for example `"true"` -> `true`).
4. Repository builds a dynamic SQL query with optional filters.
5. Repository executes query via `pool.query(sql, params)`.
6. Rows are returned as JSON to the frontend.

This is the standard pattern for most CRUD APIs.

---

## 3. SQL concepts used in this example

`movies.repository.js` demonstrates several practical SQL patterns:

- **Parameterized queries** with placeholders (`$1`, `$2`, ...), which protect against SQL injection.
- **Dynamic filtering** by building `WHERE` clauses only when filters exist.
- **`ILIKE` search** for case-insensitive title matching.
- **`EXISTS` subqueries** for relationship filters (genre and now-showing checks).
- **Pagination** with `LIMIT` and `OFFSET`.
- **Nested JSON in SQL** using `json_agg` + `json_build_object`.
- **Stable API shape** using `COALESCE(..., '[]'::json)` to return empty arrays instead of `null`.

Why this is useful:

- frontend receives data close to final UI shape
- less manual grouping in JavaScript
- fewer API calls for related data

---

## 4. Important files

- `index.js` — app entry point, middleware setup, API mount, static file serving.
- `src/config/db.js` — PostgreSQL pool configuration from environment variables.
- `src/routes/index.js` — root API router (`/health`, `/movies`).
- `src/routes/movies.routes.js` — movie endpoints.
- `src/controllers/movies.controller.js` — request/response handlers.
- `src/services/movies.service.js` — query-value normalization.
- `src/repositories/movies.repository.js` — SQL for listing movies and fetching movie details.

---

## 5. Endpoints in this class

- `GET /api/health` — checks API + DB connectivity.
- `GET /api/movies` — returns movies list.
  - optional query params: `search`, `genre`, `nowShowing`, `limit`, `offset`
- `GET /api/movies/:id` — returns one movie with nested `cast` and `genres`.

---

## 6. Running the example

1. Copy `.env.example` to `.env`
2. Set DB values (`DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`)
3. Install dependencies:

```bash
npm install
```

4. Start in dev mode:

```bash
npm run dev
```

Server defaults to:

`http://localhost:3000`

---

## 7. Theory takeaways

- Keep HTTP concerns, business concerns, and SQL concerns in separate layers.
- Always use parameterized SQL for user-provided input.
- Use SQL features (`EXISTS`, aggregates, JSON functions) to shape data efficiently.
- Return consistent JSON contracts (`[]` instead of `null` where arrays are expected).
- Prefer a connection pool over opening/closing a DB connection per request.

This class is the bridge from "writing standalone SQL queries" to "building real API endpoints powered by SQL".
