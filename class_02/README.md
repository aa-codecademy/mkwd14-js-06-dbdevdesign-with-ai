# Class 02 — SQL theory (PostgreSQL)

This folder builds on basic SQL types and table operations. The scripts use a small **cinema / retail** example: products, screening sessions, event logs, promo codes, warehouse bins, and tags.

Run scripts in PostgreSQL (psql, GUI client, or VS Code extension). Examples below assume you understand `SELECT`, `INSERT`, and table basics from class 01.

---

## 1. Schema and seed data (`create-and-insert-data.sql`)

### Tables and keys

- **Primary key**: Uniquely identifies a row. Here we use `SERIAL` for surrogate integer keys (`product_id`, `screening_id`, …) or a **composite** primary key when the natural identity is multi-column (e.g. `warehouse_bin`: `warehouse_code` + `bin_code`).
- **Surrogate key** (`SERIAL`): Stable, numeric, easy to join; not meaningful to end users.
- **Natural / business keys** (e.g. `sku`): What the business uses; often enforced with **UNIQUE** in addition to a surrogate id.

### DDL vs DML

- **DDL** (Data Definition Language): `CREATE TABLE`, `DROP TABLE` — defines or removes structure.
- **DML** (Data Manipulation Language): `INSERT`, `SELECT`, `UPDATE`, `DELETE` — works with rows.

### Inserting data

- `INSERT INTO … (columns) VALUES (…), (…), …` can add many rows in one statement.
- Literals: `TIMESTAMPTZ '…'`, `DATE '…'`, strings in single quotes; `NULL` where allowed.

---

## 2. Querying rows (`quering-data.sql`)

### Relational model in practice

A **query** returns a **relation** (a table-shaped result): columns and rows. `SELECT` lists **expressions** (column names or computed values); `FROM` names the source table(s); `WHERE` filters **rows** before they appear in the result.

### Comparisons

- Operators like `<`, `>`, `=`, `<=`, `>=` compare values of compatible types.
- `**BETWEEN a AND b`** is **inclusive** on both ends: equivalent to `value >= a AND value <= b` (for the same type rules).
- `**!=` and `<>`** both mean “not equal” in PostgreSQL.

### `IN` and `NOT IN`

- `**value IN (list)**`: true if `value` equals any listed item — convenient instead of many `OR` conditions.
- `**NOT IN**`: true if `value` matches none of the list.
**Advanced note:** If the list or subquery can contain `NULL`, `NOT IN` can behave unexpectedly; for class demos with literal lists, this is not an issue.

### NULL — three-valued logic

- `**NULL`** means “unknown” or “missing,” not zero or empty string.
- `**= NULL` is always unknown (treated as false in WHERE)**. Use `**IS NULL`** and `**IS NOT NULL**`.
- Boolean combinations with `NULL` follow **three-valued logic** (true / false / unknown).

### `AND`, `OR`, parentheses

- `**AND`**: all conditions must hold.
- `**OR**`: at least one condition holds.
- `**AND` binds tighter than `OR**` — use **parentheses** when you mean “(A or B) and C”.

### Pattern matching: `LIKE` / `ILIKE`

- `**LIKE`**: case-sensitive pattern match (PostgreSQL).
- `**ILIKE**`: **case-insensitive** `LIKE` (PostgreSQL).
- Wildcards: `**%`** = any sequence of characters; `**_**` = exactly one character.

### `CASE` expressions

- **Searched or simple `CASE`**: returns one of several values based on conditions — like `if / else` in SQL.
- Useful for **mapping** codes to labels, sort keys, or numeric ranks.

### `COALESCE` and `NULLIF`

- `**COALESCE(a, b, …)`**: returns the **first non-NULL** argument — common for display defaults (e.g. show `'N/A'` when a column is NULL).
- `**NULLIF(a, b)`**: returns **NULL** if `a = b`, otherwise returns `a` — useful to normalize “sentinel” values.

### Sorting and limiting

- `**ORDER BY column [ASC|DESC]`**: Defines **stable** ordering of result rows. Without `ORDER BY`, row order is **not guaranteed**.
- `**LIMIT n`**: take at most `n` rows (after sort, if any).
- `**OFFSET m**`: skip `m` rows — used with `LIMIT` for **pagination** (e.g. page size 10: `LIMIT 10 OFFSET 20` for page 3). Large `OFFSET` can be slow on huge tables; production systems often use **keyset pagination** later.

### String functions

- `**LENGTH`**, `**UPPER**`, `**LOWER**`, `**TRIM**`: operate per row on string values.
- `**STRING_AGG**`: **aggregate** — concatenates values from many rows into one string (often with `GROUP BY`).

---

## 3. Aggregates, grouping, and set operations (`aggregates.sql`)

### Aggregate functions

An **aggregate** computes **one value** from many rows: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `STRING_AGG`, etc.

- `**COUNT(*)`**: counts **rows** (including rows where all columns might be NULL — the row still exists).
- `**COUNT(column)`**: counts rows where `**column` is not NULL**.
- `**AVG`**, `**MIN**`, `**MAX**`: generally **ignore NULLs** in the argument; if all inputs are NULL, the result is often NULL (except `COUNT(*)`).

### `GROUP BY`

- Splits rows into **groups** (one group per distinct combination of grouped columns).
- Each group produces **one output row**.
- **Rule:** Every column in `SELECT` must either appear in `**GROUP BY`** or be used **inside an aggregate** (or be functionally dependent — PostgreSQL extends the standard in some cases).

### `WHERE` vs `HAVING`

- `**WHERE`**: filters **rows** **before** aggregation.
- `**HAVING`**: filters **groups** **after** `GROUP BY` / aggregates — can use aggregate expressions, e.g. `HAVING COUNT(*) > 5`.

### Combining queries: `UNION`, `UNION ALL`, `INTERSECT`

- `**UNION`**: Concatenates two **compatible** result sets (same columns count, matching types) and **removes duplicate** rows.
- `**UNION ALL`**: Concatenates without removing duplicates — **faster** when duplicates are acceptable or impossible.
- `**INTERSECT`**: Rows that appear in **both** queries (distinct row semantics per SQL).
- Column names in the result usually come from the **first** `SELECT`.

### `DISTINCT`

- `**SELECT DISTINCT column`**: returns **unique** values of that column — one row per distinct value (NULL appears at most once if present).

---

## 4. Constraints (`constraints.sql`)

Constraints are **declared rules** the database enforces on `INSERT`/`UPDATE` (and sometimes `DELETE` via foreign keys).

### `DEFAULT`

- If an `INSERT` **omits** the column, the **default expression** is used (e.g. `TRUE`, `NOW()`).
- Keeps application code simpler and avoids repeating the same literal.

### `UNIQUE`

- No two rows may share the same value in the constrained column(s).
- **Composite UNIQUE** `(a, b)`: the **pair** must be unique; `(1,2)` and `(1,3)` are allowed.
- **NULL handling:** In PostgreSQL, **multiple NULLs** are often allowed in a `UNIQUE` column (NULL is not equal to NULL); check docs if you rely on this.

### `CHECK`

- `**CHECK (expression)`** must evaluate to **true** (or unknown in some edge cases) for the row to be stored.
- Expresses **business rules** in the database: date ranges, positive prices when active, etc.

---

## 5. Suggested order for practice

1. `**create-and-insert-data.sql`** — build tables and load sample data.
2. `**quering-data.sql**` — filtering, NULL, patterns, expressions, sort, pagination.
3. `**aggregates.sql**` — counts, groups, `HAVING`, unions, `DISTINCT`.
4. `**constraints.sql**` — alter tables and observe **success vs error** when rules are violated.

---

## 6. Files in this folder


| File                         | Focus                                                              |
| ---------------------------- | ------------------------------------------------------------------ |
| `create-and-insert-data.sql` | `CREATE` / `DROP`, `INSERT`, demo schema                           |
| `quering-data.sql`           | `WHERE`, NULL, `ILIKE`, `CASE`, sort, `LIMIT`/`OFFSET`             |
| `aggregates.sql`             | Aggregates, `GROUP BY`, `HAVING`, `UNION`, `INTERSECT`, `DISTINCT` |
| `constraints.sql`            | `DEFAULT`, `UNIQUE`, `CHECK`                                       |
| `union.png`                  | Visual aid for set operations (if used in class)                   |


---

## 7. Further reading (PostgreSQL)

- [SELECT](https://www.postgresql.org/docs/current/sql-select.html) — full query syntax
- [Aggregate functions](https://www.postgresql.org/docs/current/functions-aggregate.html)
- [Constraints](https://www.postgresql.org/docs/current/ddl-constraints.html)

