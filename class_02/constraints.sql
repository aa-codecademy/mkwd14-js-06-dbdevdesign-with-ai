-- =============================================================================
-- TABLE CONSTRAINTS: DEFAULT, UNIQUE, CHECK
-- =============================================================================
-- **Constraints** are rules the database enforces on every INSERT/UPDATE.
-- They protect data quality: duplicates, impossible dates, invalid combinations.
--
-- Order of topics in this script:
-- 1. DEFAULT — value used when INSERT omits the column.
-- 2. UNIQUE — no two rows may share the same value (NULL usually allowed, and
--    multiple NULLs may be allowed depending on DB — know your PostgreSQL version).
-- 3. CHECK — arbitrary boolean expression that must be true for the row.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- DEFAULT CONSTRAINT
-- -----------------------------------------------------------------------------
-- When INSERT does not mention `is_active`, PostgreSQL stores TRUE automatically.
ALTER TABLE product
	ALTER COLUMN is_active
	SET DEFAULT TRUE;

-- Explicit INSERT still supplies created_at; is_active can be omitted later once
-- DEFAULT is relied on.
INSERT INTO product (sku, name, list_price, stock_qty, created_at)
VALUES
    ('DVD-005', 'Classic Horror Collection', 20.99, 40, TIMESTAMPTZ '2026-01-10 09:00:00+00');

-- NOW() evaluates at insert time (UTC or session TZ depending on column type).
-- TIMESTAMPTZ column + NOW() keeps "when was this row created" consistent.
ALTER TABLE product
	ALTER COLUMN created_at
	SET DEFAULT NOW();

-- Omit both is_active and created_at: both columns come from defaults.
INSERT INTO product (sku, name, list_price, stock_qty)
VALUES
    ('DVD-006', 'Classic Comedy Collection', 12.99, 13);

SELECT * FROM product;

-- -----------------------------------------------------------------------------
-- UNIQUE CONSTRAINT — NO DUPLICATE VALUES IN COLUMN(S)
-- -----------------------------------------------------------------------------
-- uq_sku: two products cannot share the same SKU (business key).
ALTER TABLE product
	ADD CONSTRAINT uq_sku UNIQUE (sku);

-- This INSERT uses a **new** SKU — allowed.
INSERT INTO product (sku, name, list_price, stock_qty)
VALUES
    ('DVD-007', 'Classic Comedy Collection', 12.99, 13);

-- **Composite UNIQUE**: same hall + same start time cannot be booked twice.
-- Different halls at the same time, or same hall at different times, are OK.
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
    ('Titanic', 'Cineplex 1', TIMESTAMPTZ '2026-01-01 18:00:00+00', 120, 118, 'selling');

-- Different hall, same time — unique pair (hall_name, starts_at) is new.
INSERT INTO screening_session (
    movie_title,
    hall_name,
    starts_at,
    total_seats,
    available_seats,
    screening_status
)
VALUES
    ('Titanic', 'Cineplex 2', TIMESTAMPTZ '2026-01-01 18:00:00+00', 120, 118, 'selling');

-- Same hall as previous row but **different** start time — still allowed.
INSERT INTO screening_session (
    movie_title,
    hall_name,
    starts_at,
    total_seats,
    available_seats,
    screening_status
)
VALUES
    ('Titanic', 'Cineplex 2', TIMESTAMPTZ '2026-01-01 20:00:00+00', 120, 118, 'selling');

SELECT * FROM screening_session;

-- -----------------------------------------------------------------------------
-- CHECK CONSTRAINT — CUSTOM VALIDATION RULES
-- -----------------------------------------------------------------------------
-- Promo must end on or after it starts: `ends_on >= starts_on`.
ALTER TABLE promo_code
	ADD CONSTRAINT chk_promo_code_date_order
	CHECK (ends_on >= starts_on);

-- This INSERT **violates** the CHECK (end before start) — expect an error.
INSERT INTO promo_code (code, discount_pct, starts_on, ends_on, is_stackable)
VALUES
    ('NOVO123', 10.00, DATE '2026-01-10', DATE '2026-01-01', TRUE);

SELECT * FROM promo_code;

-- Logical implication encoded as: **inactive OR price > 0**.
-- If is_active is TRUE, list_price must be > 0; if inactive, price can be 0.
ALTER TABLE product
	ADD CONSTRAINT chk_product_positive_price_when_active
	CHECK (NOT is_active OR list_price > 0);

-- Inactive product with positive price — OK.
INSERT INTO product (sku, name, list_price, stock_qty, is_active)
VALUES
    ('DVD-010', 'Classic Thriller Collection', 19.99, 40, FALSE);

-- Inactive with price 0 — OK (CHECK passes because is_active is FALSE).
INSERT INTO product (sku, name, list_price, stock_qty, is_active)
VALUES
    ('DVD-011', 'Classic Thriller Collection', 0, 40, FALSE);

-- Active with positive price — OK.
INSERT INTO product (sku, name, list_price, stock_qty, is_active)
VALUES
    ('DVD-012', 'Classic Thriller Collection', 10, 40, TRUE);

-- Active with price 0 — **violates** CHECK (active products must have price > 0).
INSERT INTO product (sku, name, list_price, stock_qty, is_active)
VALUES
    ('DVD-012', 'Classic Thriller Collection', 0, 40, TRUE);

SELECT * FROM product;
