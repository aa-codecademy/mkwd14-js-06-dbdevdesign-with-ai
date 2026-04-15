# Class 01 - PostgreSQL Setup and SQL Basics

## 1) pgAdmin local setup

### Download

- Download pgAdmin from [https://www.pgadmin.org/download/](https://www.pgadmin.org/download/).
- Install it for your operating system.

### PostgreSQL installer options

If you install PostgreSQL with the official installer:

- Keep the default port `5432` (**do not change the port number**).
- Use `postgres` as the password for user `postgres` (same as username).
- Keep locale as default.
- **Do not install Stack Builder** (no need for the stack option).

### Connect from pgAdmin

1. Open pgAdmin.
2. Right-click **Servers** -> **Register** -> **Server...**
3. In **General** tab:
   - Name: `local-postgres` (or any name you want)
4. In **Connection** tab:
   - Host: `localhost`
   - Port: `5432`
   - Maintenance database: `postgres`
   - Username: `postgres`
   - Password: `postgres`
5. Save.

---

## 2) PostgreSQL data types and when to use them

### Numeric types

- `smallint` - small whole numbers (`-32768` to `32767`), use when value range is limited.
- `integer` / `int` - standard whole numbers, most common integer type.
- `bigint` - very large whole numbers, use for large IDs/counters.
- `decimal(p,s)` / `numeric(p,s)` - exact precision numbers, use for money/financial values.
- `real` - single precision floating point, use when approximation is acceptable.
- `double precision` - double precision floating point, better precision for scientific data.
- `serial`, `smallserial`, `bigserial` - auto-incrementing integer helpers (legacy style identity columns).
- `money` - currency value type (less flexible than `numeric`, so `numeric` is usually preferred).

### Character/text types

- `char(n)` - fixed-length text, pads spaces to length `n`.
- `varchar(n)` - variable-length text with max length.
- `text` - variable-length text without limit; default choice in many cases.

### Boolean type

- `boolean` - `true`, `false`, `null`; use for flags/status fields.

### Date and time types

- `date` - date only.
- `time` - time only without timezone.
- `time with time zone` / `timetz` - time with timezone.
- `timestamp` - date + time without timezone.
- `timestamp with time zone` / `timestamptz` - date + time with timezone (recommended for global apps).
- `interval` - duration (for example `2 days`, `3 hours`).

### UUID type

- `uuid` - globally unique identifier, useful for distributed systems and public-safe IDs.

### JSON types

- `json` - stores JSON text, preserves input formatting.
- `jsonb` - binary JSON, faster to query/index, usually preferred in production.

### Binary data

- `bytea` - raw binary data (files, blobs, encrypted bytes).

### Enum type

- `enum` - fixed set of predefined string values, useful for controlled states.

### Array types

- `type[]` - array of values (for example `text[]`, `int[]`), useful for simple lists.

### Range and multirange types

- Ranges: `int4range`, `int8range`, `numrange`, `tsrange`, `tstzrange`, `daterange` - store start/end intervals.
- Multiranges: `int4multirange`, `int8multirange`, `nummultirange`, `tsmultirange`, `tstzmultirange`, `datemultirange` - store multiple non-contiguous ranges.

### Network address types

- `inet` - IPv4/IPv6 host or network.
- `cidr` - IPv4/IPv6 network blocks only.
- `macaddr`, `macaddr8` - MAC addresses.

### Geometric types

- `point`, `line`, `lseg`, `box`, `path`, `polygon`, `circle` - spatial/geometric values.

### Full-text search types

- `tsvector` - searchable document representation.
- `tsquery` - full-text query representation.

### Bit string types

- `bit(n)` - fixed-length bit string.
- `bit varying(n)` / `varbit(n)` - variable-length bit string.

### XML type

- `xml` - XML content with XML validation rules.

### Other useful/advanced types

- `oid` and object identifier-related types (`regclass`, `regtype`, etc.) - internal object references.
- `pg_lsn` - WAL location value, useful in replication/low-level ops.
- `txid_snapshot` - transaction snapshot representation.
- Composite types - row-like custom structures.
- Domain types - custom type with reusable constraints.

---

## 3) Create, update, delete table and column

### Create table

```sql
CREATE TABLE students (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text UNIQUE,
  age integer,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

### Update table (rename table)

```sql
ALTER TABLE students RENAME TO course_students;
```

### Delete table

```sql
DROP TABLE course_students;
```

```sql
DROP TABLE IF EXISTS course_students;
```

### Create column

```sql
ALTER TABLE students ADD COLUMN city text;
```

### Update column (rename/change type)

```sql
ALTER TABLE students RENAME COLUMN city TO city_name;
```

```sql
ALTER TABLE students ALTER COLUMN age TYPE smallint;
```

### Delete column

```sql
ALTER TABLE students DROP COLUMN city_name;
```

```sql
ALTER TABLE students DROP COLUMN IF EXISTS city_name;
```

---

## 4) Commands to check if something exists

### Tables

```sql
SELECT to_regclass('public.students') IS NOT NULL AS table_exists;
```

### Column in a table

```sql
SELECT EXISTS (
  SELECT 1
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'students'
    AND column_name = 'email'
) AS column_exists;
```

### Generic safe create/drop patterns

```sql
CREATE TABLE IF NOT EXISTS students (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY
);
```

```sql
DROP TABLE IF EXISTS students;
```

---

## 5) Using `WHERE` to filter

```sql
SELECT *
FROM students
WHERE age >= 18;
```

```sql
SELECT first_name, last_name
FROM students
WHERE city_name = 'Skopje' AND age BETWEEN 20 AND 30;
```

```sql
SELECT *
FROM students
WHERE email IS NULL;
```

Useful operators in `WHERE`:

- `=`, `<>`, `<`, `<=`, `>`, `>=`
- `AND`, `OR`, `NOT`
- `IN (...)`
- `BETWEEN ... AND ...`
- `LIKE`, `ILIKE`
- `IS NULL`, `IS NOT NULL`

---

## 6) `NULL` vs `NOT NULL`

- `NULL` means "no value" / unknown / missing.
- `NOT NULL` means this column must always have a value.
- `NULL` is not equal to anything, not even another `NULL`.
- To check nulls, use `IS NULL` and `IS NOT NULL` (not `= NULL`).

Example:

```sql
CREATE TABLE teachers (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  full_name text NOT NULL,
  phone text NULL
);
```

---

## 7) Primary keys

- A primary key uniquely identifies each row.
- Primary key values must be unique and cannot be `NULL`.
- A table should usually have one primary key.

Example:

```sql
CREATE TABLE courses (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code text NOT NULL UNIQUE,
  title text NOT NULL
);
```

---

## 8) Inserting values

### Insert one row

```sql
INSERT INTO students (first_name, last_name, email, age)
VALUES ('Ana', 'Petrova', 'ana@example.com', 21);
```

### Insert multiple rows

```sql
INSERT INTO students (first_name, last_name, email, age)
VALUES
  ('Marko', 'Jovanov', 'marko@example.com', 23),
  ('Elena', 'Stojanova', NULL, 20);
```

### Insert and return inserted data

```sql
INSERT INTO students (first_name, last_name, email, age)
VALUES ('Ivan', 'Nikolov', 'ivan@example.com', 25)
RETURNING id, first_name, email;
```
