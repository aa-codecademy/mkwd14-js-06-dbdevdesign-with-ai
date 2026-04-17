# Homework 02 — Cafeteria menu items (constraints & querying)

## Goal

Practice **table constraints** (validation, defaults) and **reading data** with **filtering, searching, ordering, grouping, and pagination** — on a single table.

## What you are practicing

- `NOT NULL`, `UNIQUE`, `CHECK`, `DEFAULT`
- Primary key (the starter is incomplete — you must fix it)
- `WHERE`, pattern matching for search, `ORDER BY`, `GROUP BY` / aggregates, `LIMIT` / `OFFSET` (pagination)
- Optional: `HAVING` where it helps

## Part 1 — Constraints (business rules)

Start from the provided starter script: `[homework_02_starter.sql](./homework_02_starter.sql)`.

It creates one table, `cafeteria_menu_item`, and inserts **20** sample rows (pizzas, salads, grill plates, and so on). The schema is **intentionally loose** (almost no rules). Your job is to turn it into something a real cafeteria could run in production.

### 1.1 Primary key

- Make sure there is one column that is a primary key.

### 1.2 Identification

- `code` must be **present** on every row and **unique** across the table (POS / kitchen tickets cannot reuse a dish code).

### 1.3 Required fields

- Every row must have a `**dish_name`** and a `**category\*\*` (for example Pizza, Salad, Soup).

### 1.4 Spice & price

- `**spice_level**` must be an integer from **1** (mild) to **5** (very hot).
- `**price_eur`\*\* cannot be negative.

### 1.5 Dates and stock checks

- `**added_to_menu**` is required (when the dish first appeared on the menu).
- `**last_restocked_at**` defaults to **current timestamp** on insert if not provided (use a sensible `DEFAULT`).

### 1.6 Late-night flag

- `**is_late_night`** must always be known: **not null**, default `**FALSE`\*\* if omitted (whether it is offered on the late-night menu).

### 1.7 Remakes

- `**remake_count**` (how many times the dish was remade after a complaint) cannot be negative.

### 1.8 Prep stations

- `**prep_station_code**` is required and must match the pattern: **uppercase `K-` followed by exactly four A–Z letters** (for example `K-ALFA`, `K-BETA`, `K-GAMM`). In PostgreSQL you can enforce this with a `CHECK` constraint and the `~` regex operator, for example `prep_station_code ~ '^K-[A-Z]{4}$'`. Reject invalid codes at insert time.

### How to add constraints

You may either define **everything inside `CREATE TABLE`**, or create the loose table first and then add constraints with `**ALTER TABLE**` (one statement per constraint, or grouped — whatever you prefer). Both approaches are fine.

### How this will be graded

Your final script will be run, and **bad data must be rejected**: when someone tries to insert values that break the rules in Part 1, the database should **refuse the insert** — no invalid row should be stored.

Optional self-check: after your table has all constraints, run `[homework_02_invalid_inserts.sql](./homework_02_invalid_inserts.sql)`. That file is **intentionally wrong**: **none** of those inserts should succeed. If any of them succeeds, tighten your constraints.

---

## Part 2 — Queries (filtering, search, sort, group, page)

Write **read-only** `SELECT` statements (no changing data in this section). Use only the `cafeteria_menu_item` table. For each task, return the columns that make the answer easy to read (you choose sensible column lists and aliases).

Assume **page size = 5** wherever pagination is asked.

**Filters & sorting**

1. **Very spicy** — Dishes with **`spice_level` ≥ 4**, ordered by **`price_eur`** descending, then by **`dish_name`** ascending.
2. **Oven section** — Rows whose **`kitchen_section`** contains the word **`Hollow`** (case-insensitive search). Order by **`category`**, then **`code`**.
3. **Late-night trouble** — Dishes on the **late-night** menu with **`remake_count` > 0**, sorted by **`remake_count`** descending.
4. **Mid price band** — Dishes with **`price_eur`** strictly between 5 and 12 (exclusive of 5 and 12), ordered by **`added_to_menu`** (oldest first).
5. **Restock check (simple rule)** — Dishes whose **`last_restocked_at`** is **before** `2025-01-16 00:00:00+00` (treat as “needs a restock check”). Show **`code`**, **`dish_name`**, **`last_restocked_at`**, ordered by **`last_restocked_at`** ascending.

**Aggregates (`GROUP BY`, `HAVING`)**

6. **Group stats** — For each **`category`**, show **how many dishes** (`COUNT`) and the **average `price_eur`**, rounded to two decimal places. Only include categories with **at least 2** dishes (`HAVING`). Sort by **count descending**, then **`category`** ascending.
7. **Station workload** — For each **`prep_station_code`**, show the **total `remake_count`** (`SUM`) and **how many distinct `categories`** that station prepares (`COUNT(DISTINCT …)`). Sort by **total remakes** descending.

**Simple single-number summaries (`COUNT`, `SUM`, `AVG`, `MIN` / `MAX`)**

8. **Menu size** — One row: the **total number of dishes** on the menu (all rows).
9. **Average heat** — One row: the **average `spice_level`** across all dishes, rounded to two decimal places.
10. **Remakes in total** — One row: the **sum** of all **`remake_count`** values.
11. **Price range** — One row: the **minimum** and **maximum** **`price_eur`** (`MIN` / `MAX`) as two columns.
12. **Kitchen sections** — One row: **how many different** **`kitchen_section`** values appear (ignore `NULL` if any).
13. **Late-night tally** — One row: **how many dishes** are on the late-night menu (**`is_late_night`** is true).

**Pagination**

14. **Second page of spicy dishes** — Same filter and ordering as task 1 (**`spice_level` ≥ 4**, then **`price_eur`** desc, then **`dish_name`** asc). Return **page 2** only (`LIMIT` / `OFFSET` with page size 5).

---

## Deliverables

Submit SQL query script file, It should contain, in a sensible order:

1. `CREATE TABLE` / `ALTER TABLE` / constraints so the final schema matches Part 1.
2. All **Part 2** queries, clearly labeled with comments (for example `-- Task 1` … `-- Task 14`).
