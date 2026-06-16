---
applyTo: "src/repositories/**/*.js"
---

<!--
  Applied only to repository files. These instructions keep all database
  access consistent and safe — the right place to enforce SQL conventions.
-->

# Database instructions

## Connection

Always import the shared pool. Never create a new `Pool` or `Client` per request.

```js
import { pool } from '../config/db.js';
```

## Parameterized queries — mandatory

User-supplied values must always go through placeholders (`$1`, `$2`, …). Never concatenate values into SQL strings.

```js
// correct
const result = await pool.query(
  `SELECT * FROM movie WHERE movie_id = $1`,
  [id],
);

// wrong — SQL injection risk
const result = await pool.query(`SELECT * FROM movie WHERE movie_id = ${id}`);
```

## Building dynamic WHERE clauses

Accumulate conditions in a `where` array and values in a `params` array. Push each value first, then reference `params.length` as the placeholder index.

```js
const params = [];
const where = [];

if (search) {
  params.push(`%${search}%`);
  where.push(`title ILIKE $${params.length}`);
}

if (genre) {
  params.push(genre);
  where.push(`genre_id = $${params.length}`);
}

const whereClause = where.length > 0 ? `WHERE ${where.join(' AND ')}` : '';
```

## Aggregating related rows in SQL

Use `json_agg` + `json_build_object` in a correlated subquery to embed 1:N related data as a JSON array in the same row. Wrap with `COALESCE(..., '[]'::json)` to return an empty array instead of `null` when no related rows exist.

```js
`COALESCE(
  (
    SELECT json_agg(
      json_build_object('genre_id', g.genre_id, 'name', g.name)
      ORDER BY g.name
    )
    FROM movie_genre mg
    JOIN genre g ON g.genre_id = mg.genre_id
    WHERE mg.movie_id = m.movie_id
  ),
  '[]'::json
) AS genres`
```

## Return values

- Single row: `result.rows[0] ?? null`
- Multiple rows: `result.rows`
- Inserted/updated row: use `RETURNING *` and return `result.rows[0]`

## Transactions

Use a client checked out from the pool when multiple statements must be atomic:

```js
const client = await pool.connect();
try {
  await client.query('BEGIN');
  await client.query(sql1, params1);
  await client.query(sql2, params2);
  await client.query('COMMIT');
} catch (err) {
  await client.query('ROLLBACK');
  throw err;
} finally {
  client.release();
}
```

## Pagination

Add `LIMIT` and `OFFSET` placeholders at the end of the params array. Never use `LIMIT` without `OFFSET`.

```js
params.push(limit, offset);
const limitIdx = params.length - 1;
const offsetIdx = params.length;

// in SQL:
`LIMIT $${limitIdx} OFFSET $${offsetIdx}`
```
