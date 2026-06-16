---
applyTo: "src/**/*.js"
---

<!--
  Applied to all source files. Centralised error handling is a core pattern
  in this project — these rules prevent duplicated status code logic
  scattered across controllers.
-->

# Error handling instructions

## Custom error classes

Import from `src/types/error.js`. Choose the class that matches the situation:

```js
import { NotFoundError, BadRequestError, HttpError } from '../types/error.js';
```

| Class | HTTP status | When to use |
|---|---|---|
| `BadRequestError` | 400 | Invalid input that passed schema validation |
| `NotFoundError` | 404 | Requested resource does not exist |
| `HttpError` | any | Custom status not covered above (`new HttpError(409, 'Conflict')`) |

## Throwing errors

Throw from services or repositories. Express 5 automatically catches errors thrown inside `async` route handlers.

```js
// service
export async function getById(id) {
  const movie = await moviesRepository.findById(id);
  if (!movie) throw new NotFoundError(`Movie ${id} not found`);
  return movie;
}
```

Never catch and re-throw just to change the message — throw the correct class directly.

## Controllers

Controllers do not need `try/catch`. Express 5 forwards thrown errors to `errorHandler` automatically.

```js
// correct — no try/catch needed
export async function getById(req, res, next) {
  const movie = await moviesService.getById(req.params.id);
  res.json(movie);
}
```

Use `next(error)` only when calling a callback-style API that does not return a promise.

## Error handler middleware

The global `errorHandler` in `src/middleware/error-handler.js` handles all errors. Do not add a second error handler. Do not call `res.status(500)` directly anywhere else in the codebase.

## Validation errors

The `validate` middleware converts Zod parse errors into `BadRequestError` automatically. Services and controllers do not need to handle `ZodError`.

## What not to do

```js
// wrong — duplicates error handling logic outside errorHandler
export async function getById(req, res, next) {
  try {
    const movie = await moviesService.getById(req.params.id);
    res.json(movie);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

// wrong — generic Error loses the HTTP status code
throw new Error('Movie not found');
```
