# Homework 03 — E-commerce relations (modeling & multi-table SQL)

## Goal

Work with a small **e-commerce** dataset where tables are **not** linked by declared `FOREIGN KEY` constraints. You infer how rows relate from column names and data, then practice **joins**, **filtering**, **grouping**, and **aggregates** across several tables.

## What you are practicing

- Inferring how tables connect when only naming and values suggest links.
- Choosing appropriate **joins** and combining **multiple tables** in one query.
- `WHERE`, `ORDER BY`, `GROUP BY`, `HAVING`, and aggregate functions.
- Deciding how you would enforce integrity in SQL (e.g. keys and references) once the model is clear.

## Starter data

Use `[homework_03_starter.sql](./homework_03_starter.sql)`. It creates **ten** tables and inserts sample rows. Inspect the `CREATE TABLE` and `INSERT` statements yourself; the README does not duplicate the full schema.

---

## Part 1 — Relationships and keys

1. **Document** how the tables connect: for each association you believe exists, identify the participating tables and columns and **classify** the cardinality (**one-to-one**, **one-to-many**, or **many-to-many**). Use a diagram or a structured list, per instructor preference.
2. Argue **where** primary keys and foreign keys (or other uniqueness rules) **belong** in this design, and why — without copying labels from this README; base your reasoning on the data and business meaning.

---

## Part 2 — Query tasks

Write **one main SQL statement** per task (CTEs allowed if you already use them). Prefer connecting entities through joins rather than hard-coding surrogate keys you looked up by hand. Number your answers to match the list.

### A. Warm-up

1. List every product **name** with its **category name**.
2. List **customer email** and **loyalty tier**.
3. List **order number** and **customer full name** for all orders.
4. List each **order line** with **product name** and **quantity**.
5. List **tag names** for the product named `Wireless earbuds`.

### B. Filters

1. Orders with status `**delivered`**: order number, placed date, customer email.
2. Active products (`is_active = TRUE`) in the category `**Books**`: SKU and price.
3. Customers with `**newsletter_opt_in = TRUE**`: email and loyalty tier.
4. Order lines with `**line_total > 50**`: order number, product name, line total.
5. Addresses in `**Skopje**`: customer full name, line1, `is_default`.

### C. Counts and grouping

1. Per customer: full name and **count of addresses**.
2. Per customer: how many **orders** (include customers who never ordered).
3. Per order: order number and **count of order lines**.
4. Categories that have **at least two** products: category name and product count.
5. Customers with **more than one** address: email only.

### D. Products and tags

1. Product names that have the tag `**bestseller`**.
2. Per tag: tag name and **how many products** carry that tag.
3. Products that appear **in no tag rows**.
4. All **(product name, tag name)** pairs from the assignment table.
5. Tags **not** used by any product.

### E. Money and aggregates

1. Per order: order number and **sum** of `line_total`.
2. Per category: **average** `unit_price` among active products.
3. The single order line with the **largest** `line_total`; show order number and product name.
4. Per customer: email and **sum** of all their order lines’ `line_total`.
5. Orders whose **total** of line totals is **greater than 100**: order number and that total.

### F. Dates and sorting

1. Orders placed in **2025**: order number, `placed_at`, status — newest first.
2. The **earliest** order by `placed_at`: order number and customer email.
3. Active products whose `unit_price` is **below** the overall average for active products: name and price.

### G. Missing rows

1. Customers who have **no** row in `customer_profile`: email.
2. Orders with **no** row in `order_shipment`: order number, status.
3. Categories with **no** products: category name.

### H. Combined reports

1. For orders in status `**delivered`**: order number, **tracking code**, **carrier**.
2. Per order: order number, customer full name, and the **city** of the address used as `shipping_address_id` on that order.
3. Distinct emails of customers with loyalty tier `**gold`** who have at least one order.
4. List `customer_id` values that occur **more than once** in `customer_profile`.

### I. Stretch

1. Per **category**: category name and **sum** of `line_total` for all order lines whose product belongs to that category.
2. The customer (**email**) with the **highest** total spend (sum of their order lines’ `line_total`); break ties however you like and state the rule.
3. Distinct pairs of **different** product names that appear on the **same** order (each pair once; define a consistent ordering so `(A,B)` and `(B,A)` do not both appear).
4. For **2024**, **month-by-month** count of orders (month identifier + count).
5. Values of `shop_order.shipping_address_id` that **do not** match any `address.id`.

