CREATE TABLE test_showcase (
	id SERIAL PRIMARY KEY,

	-- Numeric types
	tiny_number SMALLINT,
	regular_number INTEGER,
	huge_number BIGINT,
	exact_price NUMERIC(10, 2),
	decimal_discount DECIMAL(5, 2),
	approx_rating REAL,
	procise_score DOUBLE PRECISION,

	-- Text types
	-- for cyrilic use NCHAR and NVARCHAR
	fixed_code CHAR(3), 
	short_title VARCHAR(80),
	long_description TEXT,

	-- Logical types
	is_featured BOOLEAN,

	-- Date and time types
	release_date DATE,
	release_time TIME,
	created_at TIMESTAMP,
	published_at TIMESTAMPTZ,
	watch_duration INTERVAL,

	-- Common PostgreSQL extras
	external_id UUID,
	metadata JSONB,
	poster_signature BYTEA,
	server_ip INET,
	office_network CIDR,
	device_mac MACADDR,
	map_position POINT,
	tags TEXT[]
);

SELECT * FROM test_showcase;

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
    12,
    2026,
    9876543210,
    14.99,
    2.50,
    8.7,
    9.125,
    'MOV',
    'SQL Types Demo',
    'One row that demonstrates many different PostgreSQL data types.',
    TRUE,
    '2026-04-15',
    '18:30:00',
    '2026-04-15 10:45:00',
    '2026-04-15 18:30:00+02',
    '2 hours 15 minutes',
    '550e8400-e29b-41d4-a716-446655440000',
    '{"genre":"teaching-demo","level":"intro","seats":120}',
    '\xDEADBEEF',
    '192.168.1.25',
    '192.168.1.0/24',
    '08:00:2b:01:02:03',
    POINT(12.5, 8.3),
    ARRAY['intro', 'sql', 'postgresql']
);

INSERT INTO test_showcase (tiny_number) VALUES (13)
