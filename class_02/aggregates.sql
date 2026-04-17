-- =============================================================================
-- AGGREGATE FUNCTIONS, GROUP BY, HAVING, UNION, INTERSECT, DISTINCT
-- =============================================================================
-- **Aggregate functions** take many rows and return one summary value (or one value
-- per group when used with GROUP BY). They "collapse" detail into totals.
--
-- **GROUP BY** splits rows into buckets; each bucket gets one result row in the
-- SELECT list. Columns in SELECT must either be grouped or used inside aggregates
-- (SQL standard rule — PostgreSQL enforces this).
--
-- **HAVING** filters **groups** after aggregation (like WHERE, but for GROUP BY).
-- WHERE filters rows **before** aggregation.
--
-- **UNION / UNION ALL / INTERSECT**: combine result sets from two SELECTs that
-- have the same number of columns and compatible types.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- COUNT
-- -----------------------------------------------------------------------------
-- COUNT(*) counts rows (including NULLs in any column — * means "row exists").
-- COUNT(column) counts non-NULL values in that column only.
SELECT COUNT(*) AS product_total FROM product;

-- Rows where stock_qty is non-NULL and > 0: COUNT(stock_qty) ignores NULLs
-- in stock_qty, so you measure "how many products have a positive stock figure."
SELECT COUNT(stock_qty) AS rows_with_stock_filled FROM product
WHERE stock_qty > 0;

-- Sanity check: inspect raw rows that feed the aggregates above.
SELECT * FROM product;

-- -----------------------------------------------------------------------------
-- MIN / MAX
-- -----------------------------------------------------------------------------
-- MIN/MAX work on orderable types (numbers, dates, strings). **NULLs are skipped**
-- unless all values are NULL (then result is NULL).
SELECT MIN(list_price) AS cheepest_product FROM product
WHERE list_price > 0;

-- Duplicate demo in the original lesson: same query twice — run once to see
-- the same minimum price for products with list_price > 0.
SELECT MIN(list_price) AS cheepest_product FROM product
WHERE list_price > 0;

-- -----------------------------------------------------------------------------
-- MAX
-- -----------------------------------------------------------------------------
SELECT MAX(list_price) as most_expensive_product FROM product;

-- -----------------------------------------------------------------------------
-- AVG
-- -----------------------------------------------------------------------------
-- AVG ignores NULLs. For NUMERIC inputs, PostgreSQL returns NUMERIC; you may cast
-- for display rounding (e.g. one decimal place).
SELECT AVG(list_price) as avg_product_price FROM product;

SELECT AVG(list_price)::NUMERIC(10,1) as avg_product_price FROM product;

-- -----------------------------------------------------------------------------
-- GROUP BY — ONE ROW PER DISTINCT GROUPING VALUE
-- -----------------------------------------------------------------------------
SELECT * FROM screening_session;

-- Count how many screening sessions exist per status value.
-- GROUP BY screening_status: each unique status becomes one output row.
SELECT screening_status, COUNT(screening_status) AS home_many_per_status
FROM screening_session
GROUP BY screening_status;

-- Count events per source (how many log lines came from each system).
SELECT * FROM event_log;

SELECT source, COUNT(*)
FROM event_log
GROUP BY source;

-- **Multi-column GROUP BY**: one group per unique (screening_status, hall_name) pair.
SELECT screening_status, hall_name, COUNT(*) AS sessions
FROM screening_session
GROUP BY screening_status, hall_name;

-- WHERE vs HAVING:
-- * WHERE available_seats > 0 — removes rows before counting.
-- * HAVING COUNT(*) >= 2 — keeps only groups with at least two rows after grouping.
SELECT screening_status, COUNT(*) as count
FROM screening_session
WHERE available_seats > 0
GROUP BY screening_status
HAVING COUNT(*) >= 2;

-- Sum stock per SKU, then keep only SKUs with total stock above 35.
SELECT sku, SUM(stock_qty) AS in_stock FROM product
GROUP BY sku
HAVING SUM(stock_qty) > 35;

-- -----------------------------------------------------------------------------
-- UNION / UNION ALL — COMBINE QUERY RESULTS VERTICALLY
-- -----------------------------------------------------------------------------
-- UNION ALL: keeps all rows from both queries (including duplicates).
-- UNION: removes duplicate rows (extra sort/work — use when you need uniqueness).
-- Column names in the result come from the **first** SELECT; aliases help readability.

SELECT sku as code, name as label, 'product' as row_kind
FROM product
UNION ALL
SELECT code, code, 'promo'
FROM promo_code;

-- UNION (no ALL): duplicates removed — here both sides read event_log with
-- severity 'info', so you still get one row per distinct severity value.
SELECT severity from event_log
UNION
SELECT severity from event_log;

-- -----------------------------------------------------------------------------
-- INTERSECT — ROWS THAT APPEAR IN BOTH RESULT SETS
-- -----------------------------------------------------------------------------
-- Sources that have **both** an 'info' row and a 'warn' row (set intersection
-- of the two source lists). Empty result is possible if no source matches both.
SELECT source FROM event_log
WHERE severity = 'info'
INTERSECT
SELECT source FROM event_log
WHERE severity = 'warn';

-- -----------------------------------------------------------------------------
-- DISTINCT — UNIQUE VALUES IN A SINGLE COLUMN LIST
-- -----------------------------------------------------------------------------
SELECT DISTINCT screening_status FROM screening_session;
