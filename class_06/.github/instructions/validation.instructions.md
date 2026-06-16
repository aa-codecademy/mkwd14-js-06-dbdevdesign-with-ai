---
applyTo: "src/schemas/**/*.js"
---

<!--
  Applied to schema files. Keeps all Zod usage consistent across the project
  and prevents Copilot from suggesting outdated Zod v3 patterns.
-->

# Validation instructions

## Library

Use **Zod v4** (`import { z } from 'zod'`). The API changed in v4 — use the patterns below, not v3 examples from the internet.

## Schema file location

One schema file per domain in `src/schemas/`. Export named schema constants:

```js
// src/schemas/booking.schema.js
import { z } from 'zod';

export const createBookingSchema = z.object({
  customerName: z.string().trim().min(1).max(100),
  customerEmail: z.email().trim().optional(),
  screeningId: z.number().int().positive(),
  seatCount: z.number().int().positive(),
});
```

## Common Zod v4 validators

```js
z.string().trim().min(1)          // non-empty string, whitespace stripped
z.string().trim().min(1).max(100) // bounded string
z.email()                         // email — top-level in Zod v4, not z.string().email()
z.number().int().positive()       // positive integer
z.coerce.number().int().positive() // coerce string → number (use for URL params/query strings)
z.boolean()                       // boolean
z.enum(['a', 'b', 'c'])           // string enum
z.array(z.string())               // array of strings
z.optional()                      // makes any schema optional
z.nullable()                      // allows null
```

## Param and query schemas

URL params and query strings arrive as strings. Use `z.coerce.number()` to convert:

```js
export const idParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export const listQuerySchema = z.object({
  search: z.string().trim().optional(),
  limit: z.coerce.number().int().positive().max(100).optional().default(25),
  offset: z.coerce.number().int().min(0).optional().default(0),
});
```

## Applying schemas in routes

Use the `validate` middleware from `src/middleware/validate.js`. Never call `schema.parse()` inside a controller.

```js
import { validate } from '../middleware/validate.js';
import { idParamSchema, listQuerySchema } from '../schemas/movie.schema.js';

router.get('/', validate({ query: listQuerySchema }), moviesController.list);
router.get('/:id', validate({ params: idParamSchema }), moviesController.getById);
router.post('/', validate({ body: createBookingSchema }), bookingsController.bookTicket);
```

Pass an object with `params`, `query`, and/or `body` keys — include only the ones the route actually uses.
