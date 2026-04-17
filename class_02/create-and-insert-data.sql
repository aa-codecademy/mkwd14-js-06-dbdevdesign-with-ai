DROP TABLE IF EXISTS tag_catalog;
DROP TABLE IF EXISTS event_log;
DROP TABLE IF EXISTS promo_code;
DROP TABLE IF EXISTS screening_session;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS warehouse_bin;

CREATE TABLE product (
	product_id SERIAL PRIMARY KEY,
	sku VARCHAR(32) NOT NULL,
	name TEXT NOT NULL,
	list_price NUMERIC(10, 2),
	stock_qty INTEGER,
	is_active BOOL,
	created_at TIMESTAMPTZ
);

CREATE TABLE warehouse_bin (
    warehouse_code CHAR(2) NOT NULL,
    bin_code VARCHAR(12) NOT NULL,
    capacity_units INTEGER NOT NULL,
    notes TEXT,
    PRIMARY KEY (warehouse_code, bin_code)
);

CREATE TABLE tag_catalog (
    tag_id SERIAL PRIMARY KEY,
    label VARCHAR(40) NOT NULL,
    sort_order INTEGER NOT NULL
);


CREATE TABLE screening_session (
	screening_id SERIAL PRIMARY KEY,
	movie_title VARCHAR(120) NOT NULL,
	hall_name VARCHAR(40) NOT NULL,
	starts_at TIMESTAMPTZ NOT NULL,
	total_seats INTEGER NOT NULL,
    available_seats INTEGER NOT NULL,
    screening_status VARCHAR(20) NOT NULL
);

CREATE TABLE event_log (
    event_id SERIAL PRIMARY KEY,
    source VARCHAR(40) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL,
    payload_json TEXT
);

CREATE TABLE promo_code (
    promo_id SERIAL PRIMARY KEY,
    code VARCHAR(24) NOT NULL,
    discount_pct NUMERIC(5, 2) NOT NULL,
    starts_on DATE NOT NULL,
    ends_on DATE NOT NULL,
    is_stackable BOOLEAN NOT NULL
);

INSERT INTO product (sku, name, list_price, stock_qty, is_active, created_at)
VALUES
    ('DVD-001', 'Classic Drama Collection', 19.99, 40, TRUE, TIMESTAMPTZ '2026-01-10 09:00:00+00'),
    ('BD-204', 'Sci-Fi Anthology', 29.50, 12, TRUE, TIMESTAMPTZ '2026-02-01 11:30:00+00'),
    ('MERCH-T1', 'Themed T-Shirt', 24.00, 0, FALSE, TIMESTAMPTZ '2026-03-05 08:15:00+00'),
    ('SNACK-7', 'Popcorn Bucket', 6.50, 200, TRUE, TIMESTAMPTZ '2026-03-20 17:45:00+00');

INSERT INTO screening_session (
    movie_title,
    hall_name,
    starts_at,
    total_seats,
    available_seats,
    screening_status
)
VALUES
    ('Nordic Lights', 'Hall A', TIMESTAMPTZ '2026-05-08 18:00:00+00', 120, 118, 'selling'),
    ('Nordic Lights', 'Hall B', TIMESTAMPTZ '2026-05-08 21:30:00+00', 80, 80, 'scheduled'),
    ('Metro Heist', 'Hall A', TIMESTAMPTZ '2026-05-09 20:00:00+00', 120, 45, 'selling'),
    ('Metro Heist', 'Hall C', TIMESTAMPTZ '2026-05-09 22:00:00+00', 50, 0, 'sold_out');

INSERT INTO event_log (source, severity, message, occurred_at, payload_json)
VALUES
    ('pos', 'info', 'Sale completed', TIMESTAMPTZ '2026-04-01 10:05:00+00', '{"amount": 24.5}'),
    ('pos', 'warn', 'Low stock threshold', TIMESTAMPTZ '2026-04-02 09:40:00+00', '{"sku": "BD-204"}'),
    ('api', 'error', 'Timeout contacting printer', TIMESTAMPTZ '2026-04-03 19:22:00+00', NULL),
    ('admin', 'info', 'Price update scheduled', TIMESTAMPTZ '2026-04-04 07:00:00+00', '{"sku": "DVD-001"}');

INSERT INTO promo_code (code, discount_pct, starts_on, ends_on, is_stackable)
VALUES
    ('SPRING10', 10.00, DATE '2026-04-01', DATE '2026-04-30', TRUE),
    ('VIP5', 5.00, DATE '2026-01-01', DATE '2026-12-31', FALSE),
    ('FLASH25', 25.00, DATE '2026-05-01', DATE '2026-05-03', FALSE);

INSERT INTO warehouse_bin (warehouse_code, bin_code, capacity_units, notes)
VALUES
    ('A1', 'R01', 200, 'Retail overflow'),
    ('A1', 'R02', 150, NULL),
    ('B2', 'C10', 400, 'Bulk pallets');

INSERT INTO tag_catalog (label, sort_order)
VALUES
    ('staff-pick', 10),
    ('new-release', 20),
    ('sale', 30);

SELECT * FROM product
SELECT * FROM screening_session
SELECT * FROM event_log
SELECT * FROM promo_code
SELECT * FROM warehouse_bin
SELECT * FROM tag_catalog
