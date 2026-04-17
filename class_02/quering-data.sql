-- =============================================================================
-- QUERYING DATA — FILTERS, SEARCH, EXPRESSIONS, SORTING, PAGINATION
-- =============================================================================
-- Prerequisites: run `create-and-insert-data.sql` so these tables exist and contain rows.
--
-- Topics covered:
-- * Comparison: <, BETWEEN, <>/!=, IN / NOT IN
-- * NULL handling: IS NULL / IS NOT NULL (you cannot use = NULL)
-- * Boolean logic: AND, OR, parentheses for precedence
-- * Pattern matching: ILIKE (case-insensitive LIKE in PostgreSQL)
-- * Conditional expressions: CASE, COALESCE, NULLIF
-- * ORDER BY, LIMIT, OFFSET (pagination)
-- * String helpers: LENGTH, UPPER, LOWER, TRIM, STRING_AGG
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BASIC COMPARISONS
-- -----------------------------------------------------------------------------
-- Rows where list_price is strictly less than 20.
SELECT *
FROM product
WHERE list_price < 20;

-- BETWEEN is **inclusive** on both ends: 10 <= list_price <= 20.
SELECT *
FROM product
WHERE list_price BETWEEN 10 AND 20;

-- TIMESTAMPTZ compared to date-like strings: PostgreSQL casts bounds to timestamps.
-- All screenings in May 2026 (watch time zones if your data is not UTC).
SELECT *
FROM screening_session
WHERE starts_at BETWEEN '2026-05-01' AND '2026-05-31';

-- Inequality: != and <> are equivalent in PostgreSQL.
SELECT *
FROM event_log
WHERE severity != 'info';

SELECT *
FROM event_log
WHERE severity <> 'info';

-- -----------------------------------------------------------------------------
-- IN / NOT IN — MEMBERSHIP IN A FIXED LIST
-- -----------------------------------------------------------------------------
-- IN (…) is shorthand for OR = … OR = … ; good for small static lists.
SELECT sku, name
FROM product
WHERE sku IN ('DVD-001', 'MERCH-T1', 'DVD-010', 'DVD-110');

-- NOT IN: exclude severities — note that NOT IN with NULLs in the subquery/list
-- can yield surprising results in advanced cases; here literals are safe.
SELECT source, message, severity
FROM event_log
WHERE severity NOT IN ('info', 'warn');

-- -----------------------------------------------------------------------------
-- NULL SEMANTICS
-- -----------------------------------------------------------------------------
-- NULL means "unknown" — use IS NULL / IS NOT NULL, never `= NULL`.
SELECT *
FROM warehouse_bin
WHERE notes IS NULL;

SELECT *
FROM warehouse_bin
WHERE notes IS NOT NULL;

-- -----------------------------------------------------------------------------
-- COMBINING CONDITIONS — AND / OR / PARENS
-- -----------------------------------------------------------------------------
-- Selling sessions that are not completely empty (some seats already sold).
SELECT * FROM screening_session
WHERE screening_status = 'selling' AND available_seats < total_seats;

-- Either sold out OR low availability (under 50 seats left).
SELECT * FROM screening_session
WHERE screening_status = 'sold_out' OR available_seats < 50;

-- Parentheses matter: (cheap OR out of stock) AND still active product.
SELECT sku, name, stock_qty
FROM product
WHERE (list_price <= 10 OR stock_qty = 0) AND is_active = TRUE;

-- =============================================================================
-- SEARCHING — ILIKE PATTERNS
-- =============================================================================
-- % = any sequence of characters; _ = exactly one character.
-- ILIKE = case-insensitive match (PostgreSQL-specific; LIKE is case-sensitive).

-- Names starting with 'c' (any case).
SELECT *
FROM PRODUCT
WHERE name ILIKE 'c%';

-- Names ending with 'n'.
SELECT *
FROM PRODUCT
WHERE name ILIKE '%n';

-- Names ending with 'y'.
SELECT *
FROM PRODUCT
WHERE name ILIKE '%y';

-- Names containing the letter 'o' anywhere.
SELECT *
FROM PRODUCT
WHERE name ILIKE '%o%';

-- Substring search for "corn" (e.g. "Popcorn").
SELECT *
FROM PRODUCT
WHERE name ILIKE '%corn%';

-- -----------------------------------------------------------------------------
-- CASE EXPRESSION — MAP VALUES TO NEW COLUMNS (HERE: NUMERIC RANK)
-- -----------------------------------------------------------------------------
-- CASE evaluates top-to-bottom; ELSE catches anything unmatched.
SELECT
	severity,
	CASE severity
		WHEN 'error' THEN 3
		WHEN 'warn' THEN 2
		WHEN 'info' THEN 1
		ELSE 0
	END AS severity_rank
FROM event_log;

-- -----------------------------------------------------------------------------
-- COALESCE / NULLIF — NULL-HANDLING HELPERS
-- -----------------------------------------------------------------------------
-- COALESCE(a, b, …): first non-NULL argument wins; common for display defaults.
SELECT COALESCE(notes, 'N/A')
FROM warehouse_bin;

-- NULLIF(a, b): returns NULL if a = b, else returns a.
-- Here: show NULL instead of 0 for stock_qty (treat zero as "no stock to show").
SELECT name, NULLIF(stock_qty, 0) AS stock_qty FROM product;

-- =============================================================================
-- ORDERING — SORT ORDER OF RESULT ROWS
-- =============================================================================
-- Without ORDER BY, row order is **not guaranteed** — always sort if order matters.
SELECT * FROM product
ORDER BY list_price DESC;

SELECT * FROM product
ORDER BY list_price ASC;

-- "Top 1 cheapest" — LIMIT after ORDER picks the first row in that sort order.
SELECT * FROM product
ORDER BY list_price DESC
LIMIT 1;

-- =============================================================================
-- PAGINATION — LIMIT AND OFFSET
-- =============================================================================
-- Page size = 2 rows. OFFSET skips earlier rows (0-based page index × page size).
-- OFFSET can get slow on huge tables — keyset pagination is preferred at scale.

-- Page 1 (rows 1–2)
SELECT * FROM product
LIMIT 2;

-- Page 2 (skip 2, take 2)
SELECT * FROM product
LIMIT 2 OFFSET 2;

-- Page 3
SELECT * FROM product
LIMIT 2 OFFSET 4;

-- Page 4
SELECT * FROM product
LIMIT 2 OFFSET 6;

-- -----------------------------------------------------------------------------
-- STRING FUNCTIONS — LENGTH, CASE, TRIM
-- -----------------------------------------------------------------------------
SELECT name, LENGTH(name)
FROM product;

SELECT name, UPPER(name)
FROM product;

SELECT name, LOWER(name)
FROM product;

SELECT name, TRIM(name)
FROM product;

-- -----------------------------------------------------------------------------
-- STRING_AGG — CONCATENATE VALUES ACROSS ROWS (AGGREGATE)
-- -----------------------------------------------------------------------------
-- One row: all movie titles in the table joined into one comma-separated string.
SELECT STRING_AGG(movie_title, ', ') FROM screening_session;
