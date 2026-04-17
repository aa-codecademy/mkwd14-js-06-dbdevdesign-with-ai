-- DEFAULT CONSTRAINT

ALTER TABLE product
	ALTER COLUMN is_active 
	SET DEFAULT TRUE;


INSERT INTO product (sku, name, list_price, stock_qty, created_at)
VALUES
    ('DVD-005', 'Classic Horror Collection', 20.99, 40, TIMESTAMPTZ '2026-01-10 09:00:00+00')

ALTER TABLE product
	ALTER COLUMN created_at
	SET DEFAULT NOW();

INSERT INTO product (sku, name, list_price, stock_qty)
VALUES
    ('DVD-006', 'Classic Comedy Collection', 12.99, 13)

SELECT * FROM product

-- UNIQUE CONSTRAINT

ALTER TABLE product
	ADD CONSTRAINT uq_sku UNIQUE (sku);

INSERT INTO product (sku, name, list_price, stock_qty)
VALUES
    ('DVD-007', 'Classic Comedy Collection', 12.99, 13)

ALTER TABLE screening_session
	ADD CONSTRAINT uq_hall_start UNIQUE (hall_name, starts_at);

INSERT INTO screening_session (
    movie_title,
    hall_name,
    starts_at,
    total_seats,
    available_seats,
    screening_status
)
VALUES
    ('Titanic', 'Cineplex 1', TIMESTAMPTZ '2026-01-01 18:00:00+00', 120, 118, 'selling')

INSERT INTO screening_session (
    movie_title,
    hall_name,
    starts_at,
    total_seats,
    available_seats,
    screening_status
)
VALUES
    ('Titanic', 'Cineplex 2', TIMESTAMPTZ '2026-01-01 18:00:00+00', 120, 118, 'selling')

INSERT INTO screening_session (
    movie_title,
    hall_name,
    starts_at,
    total_seats,
    available_seats,
    screening_status
)
VALUES
    ('Titanic', 'Cineplex 2', TIMESTAMPTZ '2026-01-01 20:00:00+00', 120, 118, 'selling')

SELECT * FROM screening_session

-- CHECK CONSTRAINT

ALTER TABLE promo_code
	ADD CONSTRAINT chk_promo_code_date_order
	CHECK (ends_on >= starts_on)

INSERT INTO promo_code (code, discount_pct, starts_on, ends_on, is_stackable)
VALUES
    ('NOVO123', 10.00, DATE '2026-01-10', DATE '2026-01-01', TRUE)

SELECT * FROM promo_code


ALTER TABLE product
	ADD CONSTRAINT chk_product_positive_price_when_active
	CHECK (NOT is_active OR list_price > 0)

INSERT INTO product (sku, name, list_price, stock_qty, is_active)
VALUES
    ('DVD-010', 'Classic Thriller Collection', 19.99, 40, FALSE)

INSERT INTO product (sku, name, list_price, stock_qty, is_active)
VALUES
    ('DVD-011', 'Classic Thriller Collection', 0, 40, FALSE)

INSERT INTO product (sku, name, list_price, stock_qty, is_active)
VALUES
    ('DVD-012', 'Classic Thriller Collection', 10, 40, TRUE)

INSERT INTO product (sku, name, list_price, stock_qty, is_active)
VALUES
    ('DVD-012', 'Classic Thriller Collection', 0, 40, TRUE)

SELECT * FROM product
	