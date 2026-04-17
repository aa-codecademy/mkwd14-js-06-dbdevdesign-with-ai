-- COUNT

SELECT COUNT(*) AS product_total FROM product;

SELECT COUNT(stock_qty) AS rows_with_stock_filled FROM product
WHERE stock_qty > 0

SELECT * FROM product

-- MIN

SELECT MIN(list_price) AS cheepest_product FROM product
WHERE list_price > 0

SELECT MIN(list_price) AS cheepest_product FROM product
WHERE list_price > 0

-- MAX

SELECT MAX(list_price) as most_expensive_product FROM product

-- AVG

SELECT AVG(list_price) as avg_product_price FROM product
SELECT AVG(list_price)::NUMERIC(10,1) as avg_product_price FROM product

-- GROUP BY

SELECT * FROM screening_session

SELECT screening_status, COUNT(screening_status) AS home_many_per_status
FROM screening_session
GROUP BY screening_status

SELECT * FROM event_log;

SELECT source, COUNT(*)
FROM event_log
GROUP BY source

SELECT screening_status, hall_name, COUNT(*) AS sessions
FROM screening_session
GROUP BY screening_status, hall_name

SELECT screening_status, COUNT(*) as count
FROM screening_session
WHERE available_seats > 0
GROUP BY screening_status
HAVING COUNT(*) >= 2

SELECT sku, SUM(stock_qty) AS in_stock FROM product
GROUP BY sku
HAVING SUM(stock_qty) > 35

-- UNION

-- UNION ALL

SELECT sku as code, name as label, 'product' as row_kind
FROM product
UNION ALL
SELECT code, code, 'promo'
FROM promo_code

SELECT severity from event_log
UNION
SELECT severity from event_log

-- INTERSECT
SELECT source FROM event_log
WHERE severity = 'info'
INTERSECT
SELECT source FROM event_log
WHERE severity = 'warn'

-- DISTINCT
SELECT DISTINCT screening_status FROM screening_session




