-- Homework 03 starter — e-commerce sample data (NO foreign keys).
-- Tables are related only by naming and integer columns you must discover.
-- Run as-is before Part 1 and Part 2.

CREATE TABLE customer (
    id           SERIAL,
    email        TEXT,
    full_name    TEXT,
    created_at   TIMESTAMPTZ
);

CREATE TABLE customer_profile (
    id               SERIAL,
    customer_id      INTEGER,
    loyalty_tier     TEXT,
    newsletter_opt_in BOOLEAN
);

CREATE TABLE category (
    id    SERIAL,
    name  TEXT,
    slug  TEXT
);

CREATE TABLE product (
    id           SERIAL,
    category_id  INTEGER,
    sku          TEXT,
    name         TEXT,
    unit_price   NUMERIC(10, 2),
    is_active    BOOLEAN
);

CREATE TABLE tag (
    id   SERIAL,
    name TEXT
);

CREATE TABLE product_tag (
    product_id INTEGER,
    tag_id     INTEGER
);

CREATE TABLE address (
    id            SERIAL,
    customer_id   INTEGER,
    line1         TEXT,
    city          TEXT,
    country_code  TEXT,
    is_default    BOOLEAN
);

CREATE TABLE shop_order (
    id                   SERIAL,
    customer_id          INTEGER,
    order_number         TEXT,
    placed_at            TIMESTAMPTZ,
    status               TEXT,
    shipping_address_id  INTEGER
);

CREATE TABLE order_line (
    id           SERIAL,
    order_id     INTEGER,
    product_id   INTEGER,
    quantity     INTEGER,
    line_total   NUMERIC(10, 2)
);

CREATE TABLE order_shipment (
    id          SERIAL,
    order_id    INTEGER,
    carrier     TEXT,
    tracking_code TEXT,
    shipped_at  TIMESTAMPTZ
);

INSERT INTO customer (email, full_name, created_at) VALUES
    ('ana@example.com', 'Ana Stojkovska', '2024-01-10 09:00:00+00'),
    ('boris@example.com', 'Boris Nikolov', '2024-02-15 11:30:00+00'),
    ('cveta@example.com', 'Cveta Ristova', '2023-11-20 08:15:00+00'),
    ('dime@example.com', 'Dime Angelov', '2025-01-05 14:00:00+00'),
    ('elena@example.com', 'Elena Kostova', '2024-06-01 10:00:00+00'),
    ('filip@example.com', 'Filip Trajkov', '2024-09-12 16:45:00+00');

INSERT INTO customer_profile (customer_id, loyalty_tier, newsletter_opt_in) VALUES
    (1, 'gold', TRUE),
    (2, 'silver', FALSE),
    (3, 'bronze', TRUE),
    (4, 'bronze', FALSE),
    (5, 'gold', TRUE),
    (6, 'silver', TRUE);

INSERT INTO category (name, slug) VALUES
    ('Electronics', 'electronics'),
    ('Books', 'books'),
    ('Home', 'home'),
    ('Sports', 'sports');

INSERT INTO product (category_id, sku, name, unit_price, is_active) VALUES
    (1, 'SKU-E-001', 'Wireless earbuds', 79.99, TRUE),
    (1, 'SKU-E-002', 'USB-C hub', 45.50, TRUE),
    (1, 'SKU-E-003', 'Smart watch', 199.00, FALSE),
    (2, 'SKU-B-001', 'SQL for beginners', 29.99, TRUE),
    (2, 'SKU-B-002', 'Cookbook MK', 24.50, TRUE),
    (3, 'SKU-H-001', 'Desk lamp', 35.00, TRUE),
    (3, 'SKU-H-002', 'Ceramic mug set', 18.75, TRUE),
    (4, 'SKU-S-001', 'Yoga mat', 22.00, TRUE),
    (4, 'SKU-S-002', 'Running shoes', 89.99, TRUE),
    (1, 'SKU-E-004', 'Phone case', 15.00, TRUE);

INSERT INTO tag (name) VALUES
    ('bestseller'),
    ('gift'),
    ('eco'),
    ('new'),
    ('clearance');

INSERT INTO product_tag (product_id, tag_id) VALUES
    (1, 1), (1, 4),
    (2, 3),
    (4, 1), (4, 2),
    (5, 2),
    (6, 3),
    (8, 1),
    (9, 1), (9, 5),
    (10, 4);

INSERT INTO address (customer_id, line1, city, country_code, is_default) VALUES
    (1, 'Partizanska 12', 'Skopje', 'MK', TRUE),
    (1, 'Bul. VMRO 5', 'Bitola', 'MK', FALSE),
    (2, 'Ul. Makedonija 3', 'Skopje', 'MK', TRUE),
    (3, 'Nerezi 7', 'Skopje', 'MK', TRUE),
    (4, 'GTC L2', 'Skopje', 'MK', TRUE),
    (5, 'Str. Nikola Karev 20', 'Ohrid', 'MK', TRUE),
    (6, 'Ul. Goce 1', 'Kumanovo', 'MK', TRUE);

INSERT INTO shop_order (customer_id, order_number, placed_at, status, shipping_address_id) VALUES
    (1, 'ORD-2024-0001', '2024-03-01 10:00:00+00', 'delivered', 1),
    (1, 'ORD-2024-0002', '2024-05-10 12:30:00+00', 'delivered', 2),
    (2, 'ORD-2024-0003', '2024-05-11 09:15:00+00', 'cancelled', 3),
    (3, 'ORD-2024-0004', '2024-06-20 18:00:00+00', 'delivered', 4),
    (1, 'ORD-2025-0005', '2025-01-12 08:00:00+00', 'paid', 1),
    (5, 'ORD-2025-0006', '2025-02-01 14:20:00+00', 'shipped', 6),
    (6, 'ORD-2025-0007', '2025-02-14 11:00:00+00', 'new', 7),
    (4, 'ORD-2025-0008', '2025-02-15 16:45:00+00', 'paid', 5);

INSERT INTO order_line (order_id, product_id, quantity, line_total) VALUES
    (1, 1, 1, 79.99),
    (1, 10, 2, 30.00),
    (2, 4, 1, 29.99),
    (2, 6, 1, 35.00),
    (3, 2, 1, 45.50),
    (4, 8, 1, 22.00),
    (4, 9, 1, 89.99),
    (5, 1, 1, 79.99),
    (5, 2, 1, 45.50),
    (6, 3, 1, 199.00),
    (7, 5, 3, 73.50),
    (8, 7, 2, 37.50);

INSERT INTO order_shipment (order_id, carrier, tracking_code, shipped_at) VALUES
    (1, 'PostMK', 'PMK-10001', '2024-03-02 08:00:00+00'),
    (2, 'ExpressMK', 'EX-22002', '2024-05-11 07:00:00+00'),
    (4, 'PostMK', 'PMK-10044', '2024-06-21 09:30:00+00'),
    (6, 'ExpressMK', 'EX-99006', '2025-02-02 10:00:00+00');
