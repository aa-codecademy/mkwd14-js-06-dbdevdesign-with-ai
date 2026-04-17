# Homework 03 — E-commerce relations (modeling & multi-table SQL)

## Goal

Understand **how relational tables connect** in real systems and practice **joins**, **filtering**, **aggregation**, and **relationship patterns**: **one-to-one**, **one-to-many**, and **many-to-many**. You work with a small **e-commerce** dataset where relationships exist only through column names and values — **no foreign keys** in the starter script.

## What you are practicing

- Reading a schema and inferring **logical links** between tables (`*_id` columns, uniqueness rules).
- **INNER** vs **LEFT** (and when **RIGHT** / **FULL** might appear) **JOIN**.
- **Composite joins** and joining more than two tables.
- **One-to-one**, **one-to-many**, **many-to-many** (junction / bridge tables).
- `WHERE`, `ORDER BY`, `GROUP BY`, `HAVING`, aggregates (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`).
- Thinking about **referential integrity** (what a foreign key would enforce — you may add it in your own solution file if the course allows it).

## Starter data

Use the provided script: [`homework_03_starter.sql`](./homework_03_starter.sql).

It creates and fills these tables (intentionally **without** `FOREIGN KEY` constraints):

| Table              | Role in the story (you verify this)                             |
| ------------------ | --------------------------------------------------------------- |
| `customer`         | People who can place orders.                                    |
| `customer_profile` | Extra data per customer — intended as a **one-to-one** pair.    |
| `category`         | Product groupings — **one-to-many** toward products.            |
| `product`          | Sellable items; links to a category.                            |
| `tag`              | Labels like “bestseller”, “gift”.                               |
| `product_tag`      | **Many-to-many** bridge between products and tags.              |
| `address`          | Shipping/billing addresses — **one-to-many** from a customer.   |
| `shop_order`       | Orders; links to customer and a shipping address.               |
| `order_line`       | Line items — **one-to-many** from an order; links to products.  |
| `order_shipment`   | Shipment row per order — intended as **one-to-one** with order. |

> **Important:** The script is consistent for this homework, but in the real world orphan IDs or duplicates could exist. Part of your learning is to state which columns **should** be unique or referenced (e.g. “each `customer_profile.customer_id` should appear at most once”).

---

## Part 1 — Map the relationships (relations focus)

1. **Draw or list** the relationships between tables: for each logical link, name the **from** table/column, **to** table/column, and classify it as **1:1**, **1:N**, or **M:N** (use a short written description or a diagram — whatever your instructor accepts).
2. For **each** of the three pattern types (**one-to-one**, **one-to-many**, **many-to-many**), write **one sentence** explaining which tables demonstrate it and **why** (which column(s) tie the rows together).
3. **Optional (if required by your instructor):** In a separate `.sql` file, add `PRIMARY KEY` / `UNIQUE` / `FOREIGN KEY` constraints that match your map. Explain any place where you chose `UNIQUE` instead of a foreign key only.

---

## Part 2 — Query tasks (30+)

Write **one SQL `SELECT` (or `SELECT …` with CTEs if you know them)** per task. Use **joins** where needed; avoid guessing IDs when you can join on relationships. Number your answers to match the list.

### A. Warm-up — single links (inner join)

1. List every product **name** with its **category name** (two tables).
2. List **customer email** and **loyalty tier** (customer + profile).
3. List **order number** and **customer full name** for all orders.
4. List **order line** rows showing **product name** and **quantity** (lines + products).
5. List **tag names** attached to the product named `Wireless earbuds`.

### B. Filtering before or after joins

6. Orders with status **`delivered`**: show order number, placed date, customer email.
7. Products that are **`is_active = TRUE`** and belong to category **`Books`**: show SKU and price.
8. Customers who **`newsletter_opt_in = TRUE`**: email and loyalty tier.
9. Order lines where **`line_total > 50`**: show order number, product name, line total.
10. Addresses in **`Skopje`**: customer full name, line1, `is_default`.

### C. One-to-many — counts and existence

11. How many **addresses** does each customer have? (customer name + count.)
12. How many **orders** per customer? (Include customers with **zero** orders — hint: outer join.)
13. How many **order lines** per order? (order number + line count.)
14. Categories with **at least two** products (category name + product count).
15. Customers who have **more than one** address (email only).

### D. Many-to-many — bridge table

16. All **product names** that have the tag **`bestseller`**.
17. For each **tag**, how many **products** use it? (tag name + count.)
18. Products that have **no tags** (hint: `LEFT JOIN` + `IS NULL` or `NOT EXISTS`).
19. Pairs **(product name, tag name)** for all assignments in `product_tag`.
20. Tags that are **not used** by any product.

### E. Money and aggregates

21. **Total** `line_total` per order (order number + sum).
22. **Average** `unit_price` of active products per **category**.
23. **Highest** single line_total across all order lines; show order number and product name for that line.
24. **Sum** of line totals per **customer** (customer email + sum).
25. Orders whose **sum of line totals** is **greater than 100** (order number + sum — use `HAVING`).

### F. Dates and sorting

26. Orders in **2025** only: order number, placed_at, status — newest first.
27. The **first** order ever placed (by `placed_at`): show order number and customer email.
28. Products **cheaper than** the average `unit_price` of all active products (name + price).

### G. Left join — “missing” side

29. Customers with **no** profile row (email) — if any; if empty, say so in a comment.
30. Orders with **no** shipment row: order number, status.
31. Categories with **no** products (category name).

### H. One-to-one and composite picture

32. For **delivered** orders, list order number, **tracking code**, and **carrier** (orders + shipments).
33. Full order “header”: order number, customer name, **shipping** city (join order → address for `shipping_address_id`).
34. Customers with **`gold`** tier who ordered at least once: distinct email.
35. **Duplicate check:** write a query that would list `customer_id` values that appear **more than once** in `customer_profile` (should return no rows if data is clean).

### I. Stretch (advanced)

36. **Revenue by category**: sum of `order_line.line_total` for lines whose product belongs to that category (category name + sum).
37. **Top customer** by total spent (sum of line totals across their orders): email + total.
38. **Product pairs** on the same order: list distinct pairs `(product A name, product B name)` where both appear on the same `order_id` and `A < B` by product id to avoid duplicates (self-join on `order_line`).
39. Running **order count per month** in 2024: month + count of orders (use date truncation or `EXTRACT` depending on your SQL dialect).
40. **Anti-pattern check**: list `shop_order.shipping_address_id` values that **do not** exist in `address.id` (should be empty if data is consistent).

---

## Deliverables

Submit what your instructor asks for (commonly: relationship write-up + `.sql` with numbered queries, or a single document with code blocks). If a task has **no rows**, note it and still show the query you used.

## Academic honesty

You may use course notes and official documentation. If you use an AI assistant, paste its help only in line with your course policy.
