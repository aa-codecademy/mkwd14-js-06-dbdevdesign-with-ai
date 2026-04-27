-- ============================================================================
-- INDEXES
-- ============================================================================
--
-- An INDEX is a side data structure (typically a B-tree) that lets the database
-- find rows by a column value WITHOUT scanning the whole table.
--
--   without index → "Sequential Scan" → reads every row, O(N)
--   with index    → "Index Scan"      → jumps straight to matching rows, O(log N)
--
-- Trade-offs:
--   + dramatically faster reads on the indexed expression
--   - extra disk space
--   - every INSERT / UPDATE / DELETE on the column also has to update the index
--
-- Index ONLY columns/expressions you actually filter, join, or sort on.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- Functional (expression) index on LOWER(title)
-- ----------------------------------------------------------------------------
-- Why LOWER(title) and not just title?
--   Users search case-insensitively, e.g.  WHERE LOWER(title) LIKE 'co%'.
--   A plain index on `title` would NOT be used in that case, because the
--   planner sees a function applied to the column and must scan everything.
--   By indexing the expression itself, the planner can do a fast index lookup.
--
-- For ILIKE / LIKE with leading wildcards ('%co%') a B-tree index can't help
-- with the prefix-less pattern. For that, see PostgreSQL's `pg_trgm` extension
-- and a GIN index on `gin_trgm_ops`.
CREATE INDEX idx_movie_title_lower
	ON movie(LOWER(title))


-- Sample query that benefits from a case-insensitive title search.
-- Tip: prefix this with EXPLAIN (or EXPLAIN ANALYZE) to confirm the planner
-- is actually using `idx_movie_title_lower`:
--     EXPLAIN ANALYZE SELECT * FROM movie WHERE title ILIKE '%co%';
SELECT * FROM movie
WHERE title ILIKE '%co%'
