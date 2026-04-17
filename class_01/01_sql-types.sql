-- =============================================================================
-- SQL DATA TYPES IN POSTGRESQL (SHOWCASE TABLE)
-- =============================================================================
-- This script creates one wide table named `test_showcase` so you can see how
-- different PostgreSQL types are declared in CREATE TABLE and how literals are
-- written in INSERT. Run it step by step (CREATE, then INSERT, then SELECT) or
-- as a whole script if your client sends multiple statements at once.
--
-- Key ideas for beginners:
-- * A **type** tells the database how to store values (numbers, text, dates…)
--   and which operations are allowed (e.g. you can add two integers, but not two UUIDs).
-- * **SERIAL** is a convenience: PostgreSQL creates a sequence and auto-fills
--   integer primary keys for new rows.
-- * Choosing the right type saves space, avoids rounding surprises, and keeps
--   invalid data out (e.g. use NUMERIC for money, not FLOAT).
-- =============================================================================

CREATE TABLE test_showcase (
	-- Primary key: auto-incrementing integer (SERIAL = sequence-backed INTEGER).
	id SERIAL PRIMARY KEY,

	-- -------------------------------------------------------------------------
	-- NUMERIC TYPES
	-- -------------------------------------------------------------------------
	-- SMALLINT, INTEGER, BIGINT: whole numbers; larger types use more storage
	-- but allow a bigger range. Pick the smallest type that fits your domain.
	tiny_number SMALLINT,
	regular_number INTEGER,
	huge_number BIGINT,

	-- NUMERIC(precision, scale) and DECIMAL: **exact** decimal arithmetic.
	-- Example: NUMERIC(10,2) can store up to 10 digits total, 2 after the dot.
	-- Use these for money and anything where floating-point rounding is unacceptable.
	exact_price NUMERIC(10, 2),
	decimal_discount DECIMAL(5, 2),

	-- REAL and DOUBLE PRECISION: **approximate** binary floating-point (IEEE 754).
	-- Good for scientific/engineering values; bad for currency (rounding errors).
	approx_rating REAL,
	procise_score DOUBLE PRECISION, -- demo column name (often spelled "precise")

	-- -------------------------------------------------------------------------
	-- TEXT TYPES
	-- -------------------------------------------------------------------------
	-- CHAR(n): fixed length, padded with spaces to n characters.
	-- VARCHAR(n): variable length up to n characters.
	-- TEXT: unlimited-length string; in PostgreSQL it is first-class and fast.
	-- Note: For Unicode-heavy content, people sometimes use NCHAR/NVARCHAR in
	-- other databases; in PostgreSQL UTF-8 TEXT/VARCHAR usually suffices.
	fixed_code CHAR(3),
	short_title VARCHAR(80),
	long_description TEXT,

	-- -------------------------------------------------------------------------
	-- BOOLEAN
	-- -------------------------------------------------------------------------
	-- TRUE / FALSE / NULL — three-valued logic: comparisons with NULL need IS NULL.
	is_featured BOOLEAN,

	-- -------------------------------------------------------------------------
	-- DATE AND TIME
	-- -------------------------------------------------------------------------
	-- DATE: calendar date (no time zone).
	-- TIME: time of day without date.
	-- TIMESTAMP: date + time **without** time zone stored as given.
	-- TIMESTAMPTZ: "timestamp with time zone" — stored in UTC, shown in session TZ.
	-- INTERVAL: a duration (e.g. between two events), not a point in time.
	release_date DATE,
	release_time TIME,
	created_at TIMESTAMP,
	published_at TIMESTAMPTZ,
	watch_duration INTERVAL,

	-- -------------------------------------------------------------------------
	-- POSTGRESQL EXTRAS (VERY COMMON IN REAL APPS)
	-- -------------------------------------------------------------------------
	-- UUID: 128-bit unique identifiers (often generated with gen_random_uuid()).
	external_id UUID,

	-- JSONB: binary JSON — efficient storage, indexing, and operators for JSON.
	metadata JSONB,

	-- BYTEA: raw bytes (files, hashes, signatures) — not human-readable in plain SQL.
	poster_signature BYTEA,

	-- INET / CIDR: IP addresses and networks (routing, firewall rules, geo).
	server_ip INET,
	office_network CIDR,

	-- MACADDR: network card hardware address.
	device_mac MACADDR,

	-- POINT: a 2D geometric point (x, y) — part of PostGIS-adjacent geometry types.
	map_position POINT,

	-- TEXT[]: array of text values — PostgreSQL has rich array support.
	tags TEXT[]
);

-- After CREATE, the table is empty. SELECT * returns all columns and all rows
-- (here: zero rows until you INSERT).
SELECT * FROM test_showcase;

-- =============================================================================
-- INSERT: ONE ROW THAT EXERCISES MANY TYPES
-- =============================================================================
-- Column list matches VALUES positionally: first value → first column, etc.
-- String literals use single quotes; escape a single quote inside a string as ''.
-- =============================================================================
INSERT INTO test_showcase (
		tiny_number,
		regular_number,
		huge_number,
		exact_price,
		decimal_discount,
		approx_rating,
		procise_score,
		fixed_code,
		short_title,
		long_description,
		is_featured,
		release_date,
		release_time,
		created_at,
		published_at,
		watch_duration,
		external_id,
		metadata,
		poster_signature,
		server_ip,
		office_network,
		device_mac,
		map_position,
		tags
	)
VALUES (
    12,                                    -- SMALLINT
    2026,                                  -- INTEGER
    9876543210,                            -- BIGINT
    14.99,                                 -- NUMERIC: exact decimal
    2.50,                                  -- DECIMAL: exact decimal
    8.7,                                   -- REAL: approximate float
    9.125,                                 -- DOUBLE PRECISION
    'MOV',                                 -- CHAR(3): padded/truncated to length
    'SQL Types Demo',                      -- VARCHAR
    'One row that demonstrates many different PostgreSQL data types.', -- TEXT
    TRUE,                                  -- BOOLEAN
    '2026-04-15',                          -- DATE literal
    '18:30:00',                            -- TIME literal
    '2026-04-15 10:45:00',                 -- TIMESTAMP (no zone in literal)
    '2026-04-15 18:30:00+02',              -- TIMESTAMPTZ: offset +02 interpreted, stored in UTC
    '2 hours 15 minutes',                  -- INTERVAL literal
    '550e8400-e29b-41d4-a716-446655440000', -- UUID text format
    '{"genre":"teaching-demo","level":"intro","seats":120}', -- JSONB: must be valid JSON
    '\xDEADBEEF',                          -- BYTEA: hex byte sequence
    '192.168.1.25',                        -- INET: host address
    '192.168.1.0/24',                      -- CIDR: network + prefix length
    '08:00:2b:01:02:03',                   -- MACADDR
    POINT(12.5, 8.3),                      -- POINT(x, y)
    ARRAY['intro', 'sql', 'postgresql']    -- TEXT[] array literal
);

-- Minimal INSERT: only `tiny_number`; all other columns get NULL (if allowed)
-- or use table defaults (none here except SERIAL on id).
INSERT INTO test_showcase (tiny_number) VALUES (13);
