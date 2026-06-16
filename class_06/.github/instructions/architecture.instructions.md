---
applyTo: "src/**/*.js"
---

<!--
  Applied to every file under src/. Reminds Copilot of the layer contract
  so suggestions don't leak SQL into controllers or HTTP logic into services.
-->

# Layered architecture rules

## Controllers (`src/controllers/`)

A controller function does exactly three things:

1. Extract values from `req` (params, query, body).
2. Call one service function and `await` the result.
3. Call `res.json(result)` or `res.status(201).json(result)`.

```js
export async function getById(req, res, next) {
  const { id } = req.params;
  const movie = await moviesService.getById(id);
  res.json(movie);
}
```

Controllers do **not** contain SQL, business rules, or conditional HTTP status logic beyond success/error split.

## Services (`src/services/`)

Service functions receive plain values (not `req`/`res`), apply business logic, and delegate persistence to a repository.

```js
export function list(query) {
  return moviesRepository.findAll({
    search: query.search,
    genre: query.genre,
    nowShowing: query.nowShowing === 'true',
    limit: query.limit,
    offset: query.offset,
  });
}
```

A service may call multiple repositories or throw domain errors (`NotFoundError`, `BadRequestError`). It never imports from `express`.

## Repositories (`src/repositories/`)

Repository functions accept plain JS values and return plain JS objects or arrays. Every function executes one or more SQL queries via `pool.query(sql, params)`.

```js
export async function findById(id) {
  const result = await pool.query(
    `SELECT m.movie_id, m.title FROM movie m WHERE m.movie_id = $1`,
    [id],
  );
  return result.rows[0] ?? null;
}
```

Repositories never throw domain errors — they propagate raw database errors upward. No `req`/`res`, no Express imports.

## Routes (`src/routes/`)

Routes wire middleware and controllers. No logic belongs here.

```js
router.get('/:id', validate({ params: idParamSchema }), moviesController.getById);
router.post('/', validate({ body: createBookingSchema }), bookingsController.bookTicket);
```

Every route that receives user input must have a `validate()` call before the controller.
