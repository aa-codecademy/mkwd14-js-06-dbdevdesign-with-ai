# Class 03 — Relations and Joins (PostgreSQL)

This folder moves from single-table SQL into **multi-table design**. The domain is a small **cinema / streaming catalogue**: directors, movies, extra movie details, screenings, ticket bookings, genres, and actors. The schema is defined in `create_movie_db_script.sql` and visualised in `diagram.png` / `diagram`.

The focus of this class is **relations** (how tables reference each other) and **joins** (how those related tables are combined in queries).

---

## 1. Relations — the theory

A **relation** between tables expresses "rows in table A are connected to rows in table B." The database enforces this connection with a **foreign key (FK)**: a column (or group of columns) whose values must match the **primary key (PK)** of the referenced table.

Relations are not a physical thing — they are a logical rule enforced by the foreign key. The **cardinality** of that rule (how many rows on each side can be connected) is what distinguishes 1:1, 1:N, and M:N.

### 1.1 One-to-Many (1:N) — the most common

"**One** parent row, **many** child rows. Each child belongs to exactly one parent."

- Implemented by putting the FK **on the child** (the "many" side).
- The FK column is typically `NOT NULL` when the relationship is mandatory, `NULL` when it is optional.
- `ON DELETE` behaviour defines what happens to children when the parent is removed:
  - `RESTRICT` / `NO ACTION` — refuse to delete the parent if children exist (safe default).
  - `CASCADE` — delete children automatically.
  - `SET NULL` — keep the child but clear its FK.

**In this schema**

- `director` **1 — N** `movie`: one director can direct many movies; each movie has exactly one director.
  - `movie.director_id INTEGER NOT NULL REFERENCES director(director_id) ON DELETE RESTRICT`
  - `RESTRICT`: a director cannot be deleted while their movies are still in the catalogue.
- `movie` **1 — N** `screening`: one movie can be screened many times.
  - `screening.movie_id ... REFERENCES movie(movie_id) ON DELETE CASCADE`
  - `CASCADE`: removing a movie removes all its scheduled screenings.
- `screening` **1 — N** `ticket_booking`: one screening can have many bookings.

### 1.2 One-to-One (1:1)

"**One** row on each side." Used to split a table — often to keep a narrow "hot" table and put optional / large fields in a second table, or to model subtype-like relationships.

- Implemented by making the FK on the child **also** its primary key (or by adding a `UNIQUE` constraint on the FK).
- The `PRIMARY KEY` on a FK column guarantees that **at most one** detail row can exist per parent.

**In this schema**

- `movie` **1 — 1** `movie_detail`: every movie may have at most one extra-details row (synopsis + tagline).
  - `movie_detail.movie_id INTEGER PRIMARY KEY REFERENCES movie(movie_id) ON DELETE CASCADE`
  - Because `movie_id` is both the PK **and** the FK, you cannot insert two detail rows for the same movie.
  - A movie row can exist **without** a `movie_detail` row — the relation is optional on one side. This is exactly the case where `LEFT JOIN` vs `INNER JOIN` matters (see §2).

### 1.3 Many-to-Many (M:N)

"**Many** rows on each side." A movie can belong to many genres, and a genre can contain many movies. The same for movies and actors.

- SQL cannot store M:N directly. We introduce a **junction table** (a.k.a. bridge / link / associative table) that holds two FKs, one to each side.
- The **primary key** of the junction table is usually the **composite** `(fk_a, fk_b)` — this prevents the same pair from being inserted twice.
- The junction table can also carry **extra attributes** that describe the relationship itself (not either side).

**In this schema**

- `movie` **M — N** `genre` via `movie_genre`:
  ```
  movie_genre(movie_id FK → movie, genre_id FK → genre,
              PRIMARY KEY (movie_id, genre_id))
  ```
  Pure junction table, no extra columns.
- `movie` **M — N** `actor` via `movie_actor`:
  ```
  movie_actor(movie_id FK, actor_id FK,
              role_name VARCHAR(100),
              is_lead_role BOOLEAN NOT NULL DEFAULT false,
              PRIMARY KEY (movie_id, actor_id))
  ```
  Carries **relationship attributes** (`role_name`, `is_lead_role`) because they describe _this specific actor in this specific movie_, not the actor and not the movie on their own.

### 1.4 Self-reference (a relation of a table to itself)

A FK can point to the **same** table (for example `employee.manager_id → employee.employee_id`). We do not use this in the schema, but the `SELF JOIN` in `joins.sql` demonstrates the same concept at the query level: we join two copies of `movie_actor` to pair actors who share a movie.

### 1.5 Quick "how do I recognise it in the DDL" cheat sheet


| Cardinality | Where does the FK live?                | Extra constraint                            |
| ----------- | -------------------------------------- | ------------------------------------------- |
| 1 : N       | On the "many" side                     | FK column, usually `NOT NULL`               |
| 1 : 1       | On either side                         | FK column must be `PRIMARY KEY` or `UNIQUE` |
| M : N       | In a separate junction table (two FKs) | Composite `PRIMARY KEY (fk_a, fk_b)`        |


---

## 2. Joins — the theory

A **join** combines rows from two (or more) tables based on a **join condition** (usually `FK = PK`). Think of every join as:

1. Take the **Cartesian product** of both sides (every row of A paired with every row of B).
2. Keep only the pairs that satisfy the **ON** condition.
3. Depending on the join **type**, also keep unmatched rows from the left, the right, or both sides — filling the missing columns with `NULL`.

This is why joins and relations are studied together: the FK/PK is the condition; the join type is how strictly we require the match.

### 2.1 `INNER JOIN` — intersection

Returns only rows where the condition is **true on both sides**. Unmatched rows are dropped.

> *"Films with a known director"* — every movie in our schema has a director (`NOT NULL` FK), so `INNER JOIN director` loses nothing here. But a movie **without** a `movie_detail` row would be dropped by an INNER JOIN on `movie_detail`.

### 2.2 `LEFT (OUTER) JOIN` — keep everything on the left

Keeps every row from the **left** table; fills right-side columns with `NULL` when there is no match.

> *"Every film with its tagline, even movies that have no detail row yet"* — `movie LEFT JOIN movie_detail` returns one row per movie; `tagline` is `NULL` for movies with no detail.

### 2.3 `RIGHT (OUTER) JOIN` — keep everything on the right

Mirror image of `LEFT JOIN`. Any `RIGHT JOIN` can be rewritten as a `LEFT JOIN` by swapping the table order, which is why most teams standardise on `LEFT JOIN`.

> *"For every genre — even ones not yet used — how many movies are tagged with it"* — `movie_genre RIGHT JOIN genre` keeps unused genres (their count is 0).

### 2.4 `FULL (OUTER) JOIN` — keep everything on both sides

Returns every row from the left **and** every row from the right, matching where possible and filling the other side with `NULL` where not.

> Useful for reconciliation: "show me all movies and all details, so I can spot orphans on either side."

### 2.5 `CROSS JOIN` — Cartesian product

Pairs **every** row of A with **every** row of B. No `ON` clause. Result size is `|A| × |B|`. Use cases: generating combinations, building calendars, seeding test matrices.

> *"Every pair of genres"* — handy for a "related genre" matrix.

### 2.6 `SELF JOIN` — join a table to itself

Not a keyword; just a pattern. Give the table two **aliases** so you can join it to itself.

> *"For each movie, list every pair of co-stars"* — join `movie_actor` to a second copy of itself on `movie_id`, with `actor_id_2 > actor_id_1` to avoid both duplicate pairs and pairing an actor with themselves.

### 2.7 `NATURAL JOIN` — avoid

Auto-joins on **all** columns that share a name in both tables. Fragile: if someone adds an unrelated column with a matching name (`created_at`, `name`, `status`…), the query silently changes meaning. Prefer explicit `ON`.

### 2.8 Old-style comma join — avoid in new code

```sql
FROM movie m, director d
WHERE m.director_id = d.director_id
```

Equivalent to an `INNER JOIN` but mixes the **join condition** with the **row filter** in the same `WHERE` — easy to forget a condition and produce a Cartesian product by accident. Explicit `INNER JOIN … ON …` is clearer and safer.

### 2.9 Visual summary


| Join type | Left unmatched rows | Right unmatched rows | Typical use                                   |
| --------- | ------------------- | -------------------- | --------------------------------------------- |
| `INNER`   | dropped             | dropped              | "Only related data on both sides"             |
| `LEFT`    | kept (right = NULL) | dropped              | "Everything on the left, match when possible" |
| `RIGHT`   | dropped             | kept (left = NULL)   | Mirror of LEFT                                |
| `FULL`    | kept                | kept                 | Reconciliation, gap analysis                  |
| `CROSS`   | — (no condition)    | — (no condition)     | Combinations / cartesian products             |
| `SELF`    | —                   | —                    | Hierarchies, pairs within the same table      |


---

## 3. The schema in this class

```
director ───< movie ───< screening ───< ticket_booking
                │  ╲
                │   ─── movie_detail            (1 : 1, optional)
                │
                ├──< movie_genre >── genre       (M : N)
                │
                └──< movie_actor >── actor       (M : N, with role_name + is_lead_role)
```

- `>──` and `──<` denote the "many" end.
- `movie_detail` sits on the `movie` side because it depends on a movie existing.
- `movie_genre` and `movie_actor` are the **junction tables** for the two M:N relations.

The ER diagram is in `diagram.png`.

---

## 4. Files in this folder


| File                         | Focus                                                                        |
| ---------------------------- | ---------------------------------------------------------------------------- |
| `create_movie_db_script.sql` | Schema (all relations) + seed data                                           |
| `joins.sql`                  | INNER / LEFT / RIGHT / FULL / CROSS / SELF / NATURAL joins + example queries |
| `diagram.png`, `diagram`     | ER diagram of the cinema schema                                              |


---

## 5. Further reading (PostgreSQL)

- [Foreign keys](https://www.postgresql.org/docs/current/ddl-constraints.html#DDL-CONSTRAINTS-FK)
- [Joined tables (`SELECT … FROM …`)](https://www.postgresql.org/docs/current/queries-table-expressions.html#QUERIES-JOIN)
- `[SELECT` reference](https://www.postgresql.org/docs/current/sql-select.html)

