# Class 05 — Database Programmability (PostgreSQL)

`class_03` taught us how to **shape** data (schema). `class_04` taught us how to **read** it (`SELECT`). This class is about everything that lives **inside the database server** between those two: the building blocks that turn a SQL database from "a place to store rows" into a small, reliable application platform.

Topics covered in this folder:

- **Views** — saved queries you can read like tables
- **Materialized views** — cached snapshots of an expensive query
- **Indexes** — making lookups fast
- **Temporary tables** — session-scoped scratch space
- **Transactions** — `BEGIN` / `COMMIT` / `ROLLBACK` and the ACID guarantees
- **Triggers** — automatic reactions to `INSERT` / `UPDATE` / `DELETE`
- **Functions** — parameterized, callable queries (scalar and table-returning)
- **Stored procedures** — multi-step business logic with control flow

Every concept has its own SQL file. The walk-through below explains **what each feature is, why you would use it, and what to watch out for**.

---

## 1. Why programmability lives inside the database

You _could_ implement everything we cover here in your application code: cache query results in Redis, wrap multi-statement updates in your ORM's transaction helper, validate writes in a service layer, schedule a job to keep a derived table in sync. So why push any of it into the database?

Two reasons:

1. **Correctness.** The database is the only place where _every_ writer eventually shows up. A rule enforced by a trigger or a `CHECK` constraint is enforced for the web app, the migration script, and the panicked manual `UPDATE` at 3 a.m. A rule enforced only in the application layer is a rule that some future code path will skip.
2. **Locality.** Some logic is much cheaper to run next to the data — a join over millions of rows, an "all or nothing" multi-row update, a hot lookup that you'd rather not pay a network round-trip for.

The trade-off is that database code is harder to version-control, test, and refactor than application code. The healthy approach is: put rules and atomicity guarantees in the DB, keep complex business workflows in the app.

---

## 2. Views — naming a query

```sql
CREATE VIEW v_movie_overview AS
SELECT m.movie_id, m.title, ..., STRING_AGG(g.name, ', ') AS genres
FROM movie m
JOIN director d ...
LEFT JOIN movie_genre mg ...
GROUP BY ...;

SELECT * FROM v_movie_overview
WHERE release_year >= 2024;
```

A **view** is a `SELECT` that has been given a name. To the caller it looks like a table, but the database does not store its rows: every time you query the view, PostgreSQL re-runs the underlying `SELECT`.

Use views for:

- **Hiding complexity.** Callers say `SELECT * FROM v_movie_overview` instead of repeating a five-table join.
- **Stable contracts.** You can refactor the underlying tables (rename columns, split tables) and keep the view's output the same.
- **Permissions.** Grant `SELECT` on a view that exposes only the safe columns of a sensitive table.

What views are **not**:

- They are not faster than the underlying query — querying a view costs as much as running its body.
- A view can't have its own indexes (an index on the view's columns is really an index on the base tables).

> Naming convention used in this folder: `v_` prefix for views, `mv_` prefix for materialized views. Pick a convention and stick with it; it makes views obvious at a glance.

---

## 3. Materialized views — a cached snapshot

```sql
CREATE MATERIALIZED VIEW mv_movie_overview AS
SELECT ...;        -- same query as the regular view

REFRESH MATERIALIZED VIEW mv_movie_overview;
```

A **materialized view** is a view whose result is _physically stored_ on disk, like a regular table. Reading from it is as fast as reading any table — but the data is a snapshot. New `INSERT` / `UPDATE` / `DELETE` statements on the base tables do **not** flow through automatically. You have to call `REFRESH MATERIALIZED VIEW` to rebuild the snapshot.

| Aspect    | View                   | Materialized view                |
| --------- | ---------------------- | -------------------------------- |
| Storage   | none                   | rows persisted on disk           |
| Read cost | cost of the SELECT     | cost of a plain table read       |
| Freshness | always live            | as of the last `REFRESH`         |
| Indexable | no                     | yes, like a normal table         |
| Best for  | reusable joins/filters | expensive aggregates, dashboards |

Two important details:

- `REFRESH MATERIALIZED VIEW` takes a write lock — readers are blocked while it runs.
- `REFRESH MATERIALIZED VIEW CONCURRENTLY` avoids that lock but **requires a `UNIQUE` index on the materialized view**. For dashboards that must stay readable, this is usually what you want.

> Mental model: a regular view is a saved formula; a materialized view is a saved _result_.

---

## 4. Indexes — making lookups fast

```sql
CREATE INDEX idx_movie_title_lower
    ON movie(LOWER(title));

SELECT * FROM movie WHERE title ILIKE '%co%';
```

An **index** is a side data structure (typically a B-tree) that maps column values to row locations, so the database doesn't have to scan every row to find a match.

- Without an index → **Sequential Scan**: read every row in the table, O(N).
- With an index → **Index Scan / Index Only Scan**: jump straight to matching rows, O(log N).

Trade-offs:

- ✅ Reads on the indexed expression become dramatically faster.
- ❌ Each index takes disk space.
- ❌ Every `INSERT` / `UPDATE` / `DELETE` has to update every relevant index.

Rules of thumb:

1. Index columns you actually filter, join on, or sort by. **Don't** "index everything just in case" — you'll slow writes down for no benefit.
2. **Functional/expression indexes** are essential when you query a transformed value. A plain index on `title` would not help `WHERE LOWER(title) = 'inception'`, but `CREATE INDEX ... ON movie(LOWER(title))` does.
3. `LIKE 'foo%'` (prefix) can use a B-tree; `LIKE '%foo%'` (substring) cannot — for that, look at the [`pg_trgm`](https://www.postgresql.org/docs/current/pgtrgm.html) extension and a GIN index.
4. Use `EXPLAIN` (or `EXPLAIN ANALYZE`) to verify the planner is actually using your index:

   ```sql
   EXPLAIN ANALYZE
   SELECT * FROM movie WHERE LOWER(title) LIKE 'co%';
   ```

   Look for `Index Scan using idx_movie_title_lower` in the output.

The image `searching-indexed-table-column.png` next to this README shows what the planner output looks like before vs. after adding the index — keep it open while playing with `EXPLAIN`.

---

## 5. Temporary tables — scratch space for a session

```sql
CREATE TEMPORARY TABLE tmp_recent_movies AS
SELECT movie_id, title, release_year, age_rating, director_id
FROM movie
WHERE release_year >= 2020;

SELECT COUNT(*) FROM tmp_recent_movies;

SELECT *
FROM director d
JOIN tmp_recent_movies tmp_m ON d.director_id = tmp_m.director_id;
```

A **temporary table** is a real table that exists only inside the session that created it and is dropped automatically when the session ends. Other sessions can't see it (so two users can have a `tmp_recent_movies` of their own without clashing).

When to reach for one:

- You need to run several queries against the same intermediate result and don't want to recompute it each time.
- You're stepping through a big transformation and want each step to be inspectable.
- You want an indexable scratch table without polluting the schema.

Temp tables vs. CTEs:

| Need                                                                            | Use          |
| ------------------------------------------------------------------------------- | ------------ |
| Reuse an intermediate result in **one** query                                   | `WITH` (CTE) |
| Reuse an intermediate result across **many** queries / inspect it interactively | TEMP TABLE   |
| Add an index on the intermediate data                                           | TEMP TABLE   |

> Common gotcha: `CREATE TEMPORARY TABLE foo AS SELECT ...` only copies columns, **not** indexes, constraints, or defaults. Re-create whichever ones you need.

---

## 6. Transactions — atomic units of work

```sql
BEGIN;

UPDATE screening
SET available_seats = available_seats - 4
WHERE screening_id = 1;

INSERT INTO ticket_booking(screening_id, customer_name, customer_email, seat_count)
VALUES (1, 'Hana Customer', 'hana@example.com', 3);

COMMIT;     -- or ROLLBACK
```

A **transaction** groups multiple statements so they are applied **all-or-nothing**. Either every statement succeeds and the changes become visible together (`COMMIT`), or any failure rolls everything back (`ROLLBACK`) and the database is untouched.

The four guarantees, by name (**ACID**):

| Letter | Property    | What it means in practice                                                    |
| ------ | ----------- | ---------------------------------------------------------------------------- |
| **A**  | Atomicity   | The transaction is one indivisible unit — partial application is impossible. |
| **C**  | Consistency | Constraints / triggers / FK rules hold before and after the transaction.     |
| **I**  | Isolation   | Concurrent transactions don't see each other's half-finished writes.         |
| **D**  | Durability  | Once `COMMIT` returns, the change survives crashes, restarts, power loss.    |

Lifecycle:

```
BEGIN;          -- open the transaction (auto-commit is now off for this session)
... statements ...
COMMIT;         -- make changes permanent
-- or --
ROLLBACK;       -- discard everything since BEGIN
```

The classic "why this matters" example is in `transaction-with-rollback.sql`:

1. We pre-reduce `available_seats`.
2. We insert a `ticket_booking` row.
3. The (imaginary) payment provider returns an error.
4. We `ROLLBACK`. Both writes vanish — no orphaned booking, no missing seats.

Compare that to the auto-commit version: each statement would be its own transaction, and a failure between them would leave the database in an inconsistent state forever.

> Anything that mutates more than one row, or more than one table, in a way that must stay consistent **belongs in a transaction**. Single-statement updates are already atomic by themselves.

### Isolation — what other sessions see

Inside a transaction, your changes are visible to **you** but invisible to other sessions until you `COMMIT`. PostgreSQL's default isolation level (`READ COMMITTED`) means other sessions only ever see committed data. For stronger guarantees (e.g. preventing two concurrent bookings from both seeing the same seat as available), you either raise the isolation level (`SERIALIZABLE`) or take an explicit row lock with `SELECT ... FOR UPDATE` (the procedure example in §10 does exactly this).

---

## 7. Triggers — code that runs automatically on data changes

```sql
CREATE OR REPLACE FUNCTION fn_trg_movie_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_movie_set_udpdated_at
BEFORE UPDATE ON movie
FOR EACH ROW
EXECUTE FUNCTION fn_trg_movie_set_updated_at();
```

A **trigger** is code the database runs automatically when an event happens on a table. The event is one of `INSERT`, `UPDATE`, `DELETE`, or `TRUNCATE`.

A trigger has two parts:

1. A **trigger function** (`RETURNS TRIGGER`) — the body of code to execute.
2. A `CREATE TRIGGER` statement — binds the function to a table + event + timing.

Inside a trigger function, two special record variables are available:

- `NEW` — the row as it _will_ look after the operation (for `INSERT` and `UPDATE`).
- `OLD` — the row as it _looked_ before the operation (for `UPDATE` and `DELETE`).

### Timing matters

| Timing | When it runs                           | Typical use                                               |
| ------ | -------------------------------------- | --------------------------------------------------------- |
| BEFORE | before the row is written              | mutate `NEW.*` (auto-stamp, normalize), reject the change |
| AFTER  | after the row is written and committed | audit logs, cascade derived tables, send notifications    |

In the `movie.updated_at` example we use `BEFORE UPDATE` because we want to set `NEW.updated_at` _before_ the row hits disk. By the time an `AFTER UPDATE` trigger ran, modifying `NEW` would have no effect.

### When to use triggers

- ✅ Cross-cutting rules that must hold no matter who writes (audit columns, soft-delete bookkeeping, denormalized counters).
- ✅ Things that genuinely belong to the data, not the use case (last-modified timestamps, normalizing email addresses, history tables).
- ⚠️ Don't use triggers for arbitrary application logic. Triggers run hidden from the calling code, and a chatty trigger can turn one `UPDATE` into a cascade of writes that is hard to debug.

### Why we set `updated_at` in a trigger and not in the app

Because **anyone** who writes to the table — your app, a Rails console, a migration, a one-off `UPDATE` from psql — gets the column stamped automatically. The rule lives where the data lives.

---

## 8. Functions — parameterized queries with a name

```sql
CREATE OR REPLACE FUNCTION fn_screening_percentage_sold(p_screening_id INTEGER)
RETURNS NUMERIC LANGUAGE sql STABLE AS $$
    SELECT ROUND(100.0 * (total_seats - available_seats) / total_seats, 1)
    FROM screening
    WHERE screening_id = p_screening_id
$$;

SELECT fn_screening_percentage_sold(1);
```

A **function** wraps a query (or some logic) behind a name and parameters, and returns a value. Where a view is parameter-free, a function lets the caller pass arguments and get a tailored answer back. Functions are callable from `SELECT`:

```sql
SELECT fn_screening_percentage_sold(1) AS percentage_sold;
SELECT * FROM fn_top_movies_by_genre('Comedy');
```

### Two output shapes

- **Scalar function** — returns a single value:

  ```sql
  RETURNS NUMERIC
  ```

- **Table-returning function (TVF)** — returns a set of rows you can `SELECT * FROM`:

  ```sql
  RETURNS TABLE (
      movie_id INTEGER,
      title VARCHAR,
      release_year INTEGER,
      seats_sold BIGINT
  )
  ```

### Languages

| Language           | Best for                                                                 |
| ------------------ | ------------------------------------------------------------------------ |
| `LANGUAGE sql`     | Single SELECT/INSERT/UPDATE bodies. Often inlined by the planner.        |
| `LANGUAGE plpgsql` | Procedural logic — variables, `IF`, `LOOP`, `EXCEPTION`, multiple steps. |

Both functions in `functions.sql` use `LANGUAGE sql` because their bodies are a single `SELECT`.

### Volatility — why we marked them `STABLE`

PostgreSQL classifies every function by how its output changes:

| Volatility  | Meaning                                                                                  |
| ----------- | ---------------------------------------------------------------------------------------- |
| `IMMUTABLE` | Same inputs always give the same output, no DB reads (e.g. pure math).                   |
| `STABLE`    | Same inputs give the same output **within one query**; reads from the DB are OK.         |
| `VOLATILE`  | Output may change at any time, function may have side effects (e.g. `random()`, writes). |

Volatility hints the planner: a `STABLE` function can be evaluated once per query, while a `VOLATILE` one may be re-run per row. Defaults to `VOLATILE`, so always declare what you actually have.

### Defaults and overloading

```sql
CREATE FUNCTION fn_top_movies_by_genre(p_genre_name VARCHAR, p_limit INTEGER DEFAULT 5)
```

- `DEFAULT 5` makes `p_limit` optional. `fn_top_movies_by_genre('Comedy')` and `fn_top_movies_by_genre('Comedy', 10)` are both valid.
- PostgreSQL also supports overloading by argument type — different signatures, same name.

### Naming convention

`fn_<verb>_<thing>` is used throughout this folder (`fn_screening_percentage_sold`, `fn_top_movies_by_genre`). Triggers' helper functions get the `fn_trg_` prefix.

---

## 9. Functions vs. Procedures — when to pick which

PostgreSQL distinguishes between functions and procedures explicitly. The dividing line is simple:

| Aspect                   | FUNCTION                                       | PROCEDURE                                          |
| ------------------------ | ---------------------------------------------- | -------------------------------------------------- |
| How you call it          | `SELECT fn_x(...)` / `SELECT * FROM fn_x(...)` | `CALL sp_x(...)`                                   |
| Return value             | Required — scalar, record, or `RETURNS TABLE`  | Optional — uses `OUT` parameters if needed         |
| Can manage transactions? | No (it runs inside the caller's transaction)   | Yes — can `COMMIT` / `ROLLBACK` in the middle      |
| Designed for             | Computing & returning data                     | Performing side effects, multi-step business logic |

> If your code reads data and produces a result → **function**.
> If your code _changes_ data, especially in multiple steps that must stay coordinated → **procedure**.

---

## 10. Stored procedures — multi-step business logic with control flow

```sql
CREATE OR REPLACE PROCEDURE sp_book_seats(
    IN  p_screening_id   INTEGER,
    IN  p_customer_name  VARCHAR,
    IN  p_customer_email VARCHAR,
    IN  p_seat_count     INTEGER,
    OUT o_booking_id     INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_available INTEGER;
    v_status    VARCHAR;
BEGIN
    SELECT available_seats, screening_status
      INTO v_available, v_status
    FROM screening
    WHERE screening_id = p_screening_id
    FOR UPDATE;                    -- (1) lock the row

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Screening % not found', p_screening_id;
    END IF;

    IF v_status <> 'selling' THEN
        RAISE EXCEPTION 'Screening % is not selling', p_screening_id;
    END IF;

    IF v_available < p_seat_count THEN
        RAISE EXCEPTION 'Not enough seats';
    END IF;

    UPDATE screening
    SET available_seats = available_seats - p_seat_count,
        screening_status = CASE
            WHEN available_seats - p_seat_count = 0 THEN 'sold_out'
            ELSE screening_status
        END
    WHERE screening_id = p_screening_id;

    INSERT INTO ticket_booking (screening_id, customer_name, customer_email, seat_count, booking_status)
    VALUES (p_screening_id, p_customer_name, p_customer_email, p_seat_count, 'confirmed')
    RETURNING ticket_booking_id INTO o_booking_id;
END;
$$;

CALL sp_book_seats(1, 'Ivo', 'ivo@example.com', 3, NULL);
```

This procedure encodes a real business rule: "reserve seats and create a booking, but only if the screening exists, is currently selling, and has enough seats". Several PL/pgSQL features come together here:

### Parameter modes

| Mode    | Meaning                                                                      |
| ------- | ---------------------------------------------------------------------------- |
| `IN`    | Input only (the default).                                                    |
| `OUT`   | Output only — the caller passes a placeholder, the procedure writes into it. |
| `INOUT` | Both — read and overwritten.                                                 |

`o_booking_id` is `OUT`, so the caller passes `NULL` and reads the new id back after `CALL`.

### Local variables

```sql
DECLARE
    v_available INTEGER;
    v_status    VARCHAR;
```

Naming convention: `p_*` for parameters, `v_*` for local variables, `o_*` for `OUT` parameters. Prevents clashes with column names of the same spelling.

### Loading a row into variables

```sql
SELECT available_seats, screening_status
  INTO v_available, v_status
FROM screening
WHERE screening_id = p_screening_id
FOR UPDATE;
```

`SELECT ... INTO` reads the columns of (at most) one row into the variables. Combined with `FOR UPDATE`, it also takes a row-level lock — no other session can change the same screening row until our transaction ends. This is what prevents two concurrent bookings from both seeing the seat as available and overselling it.

### Validation with exceptions

```sql
IF NOT FOUND THEN
    RAISE EXCEPTION 'Screening % not found', p_screening_id;
END IF;
```

- `FOUND` is a special PL/pgSQL boolean set by the previous `SELECT` / `UPDATE` / `INSERT` / `DELETE`.
- `RAISE EXCEPTION` aborts the procedure **and** rolls back every change made by the surrounding transaction. Validation errors leave the database untouched.
- `RAISE NOTICE` (used in `sp_cancel_booking`) just prints a message and continues — useful for "this is fine, nothing to do" cases.

### Conditional updates with `CASE`

```sql
SET screening_status = CASE
    WHEN available_seats - p_seat_count = 0 THEN 'sold_out'
    ELSE screening_status
END
```

Inline `CASE` lets you flip a column's value based on a condition as part of the same `UPDATE`. No separate query, no extra round-trip, no race window.

### Reading values out of writes

```sql
INSERT INTO ticket_booking (...) VALUES (...)
RETURNING ticket_booking_id INTO o_booking_id;
```

`RETURNING ... INTO` is the PL/pgSQL idiom for capturing values produced by a write (auto-generated ids, timestamps from defaults, etc.) into local or `OUT` variables.

The companion procedure `sp_cancel_booking` does the inverse and adds **idempotency**: cancelling an already-cancelled booking is a no-op and just emits a `NOTICE`. Idempotency is a virtue — it makes retrying safe.

---

## 11. How the pieces fit together

These features compose. A real cinema-booking backend might use all of them at once:

- A **stored procedure** (`sp_book_seats`) is the only path through which seats are reserved. It runs inside an implicit **transaction**, locks the screening row, validates business rules, and either commits the booking or `RAISE`s and rolls everything back.
- A **trigger** on `movie` keeps `updated_at` accurate no matter who edits a movie.
- A **function** (`fn_screening_percentage_sold`) backs a reusable "sold %" widget on the dashboard.
- A **materialized view** (`mv_movie_overview`) feeds a heavy reporting page; a nightly job runs `REFRESH MATERIALIZED VIEW CONCURRENTLY`.
- An **index** on `LOWER(title)` keeps the search bar instant even with 100k movies.
- A **temporary table** is used by an ad-hoc analytics script to stage filtered movies and join them around several times without re-running the filter.

Each tool has a precise job. Mix and match deliberately.

---

## 12. Patterns to remember

| Goal                                                         | Use                                                  |
| ------------------------------------------------------------ | ---------------------------------------------------- |
| Reuse a complex SELECT under a clean name                    | **VIEW**                                             |
| Cache an expensive aggregate; tolerate slight staleness      | **MATERIALIZED VIEW** + `REFRESH`                    |
| Make a frequent lookup fast                                  | **INDEX** (functional index for transformed columns) |
| Stage intermediate results in one session                    | **TEMPORARY TABLE**                                  |
| Make multiple writes succeed-or-fail together                | **TRANSACTION** (`BEGIN` / `COMMIT` / `ROLLBACK`)    |
| Enforce a rule on every write, no matter the source          | **TRIGGER**                                          |
| Auto-stamp `updated_at` / `created_at`                       | `BEFORE UPDATE` trigger that mutates `NEW`           |
| Parameterize and reuse a query                               | **FUNCTION** (`fn_*`)                                |
| Encode a multi-step business operation as a single safe call | **STORED PROCEDURE** (`sp_*`)                        |
| Prevent concurrent bookings from overselling                 | `SELECT ... FOR UPDATE` inside a procedure           |
| Reject invalid writes inside a procedure                     | `RAISE EXCEPTION '...'`                              |
| Warn without aborting                                        | `RAISE NOTICE '...'`                                 |
| Read a generated id back from an `INSERT`                    | `INSERT ... RETURNING col INTO var`                  |

---

## 13. Files in this folder

| File                                 | Concept                                                               |
| ------------------------------------ | --------------------------------------------------------------------- |
| `views.sql`                          | Regular view & materialized view, with `REFRESH`                      |
| `index.sql`                          | Functional B-tree index on `LOWER(title)`                             |
| `temp-table.sql`                     | Session-scoped temporary table                                        |
| `transactions.sql`                   | `BEGIN` / `COMMIT` happy-path transaction                             |
| `transaction-with-rollback.sql`      | `ROLLBACK` undoing every change since `BEGIN`                         |
| `triggers.sql`                       | `BEFORE UPDATE` trigger auto-stamping `updated_at`                    |
| `functions.sql`                      | Scalar function and `RETURNS TABLE` function                          |
| `procedures.sql`                     | Two PL/pgSQL stored procedures (`sp_book_seats`, `sp_cancel_booking`) |
| `searching-indexed-table-column.png` | Screenshot of `EXPLAIN` output for the indexed query                  |
| `README.md`                          | This walk-through                                                     |

---

## 14. Further reading (PostgreSQL)

- [Views (`CREATE VIEW`)](https://www.postgresql.org/docs/current/sql-createview.html)
- [Materialized views](https://www.postgresql.org/docs/current/rules-materializedviews.html)
- [Indexes — overview](https://www.postgresql.org/docs/current/indexes.html)
- [Indexes on expressions](https://www.postgresql.org/docs/current/indexes-expressional.html)
- [`CREATE TABLE ... TEMPORARY`](https://www.postgresql.org/docs/current/sql-createtable.html)
- [Transactions & isolation](https://www.postgresql.org/docs/current/tutorial-transactions.html)
- [`SELECT ... FOR UPDATE`](https://www.postgresql.org/docs/current/sql-select.html#SQL-FOR-UPDATE-SHARE)
- [Triggers](https://www.postgresql.org/docs/current/triggers.html)
- [User-defined functions](https://www.postgresql.org/docs/current/xfunc.html)
- [PL/pgSQL — procedural language](https://www.postgresql.org/docs/current/plpgsql.html)
- [`CREATE PROCEDURE`](https://www.postgresql.org/docs/current/sql-createprocedure.html)
