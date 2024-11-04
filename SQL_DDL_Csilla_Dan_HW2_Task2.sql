-----PART2------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*1. Create table ‘table_to_delete’ and fill it with the following query:

               CREATE TABLE table_to_delete AS
               SELECT 'veeeeeeery_long_string' || x AS col
               FROM generate_series(1,(10^7)::int) x; -- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)*/
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1, (10^7)::int) x;
--2. Lookup how much space this table consumes with the following query:
               SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';
--3. Issue the following DELETE operation on ‘table_to_delete’         
EXPLAIN ANALYZE                        -- a, how much time it takes to perform this DELETE statement
DELETE FROM table_to_delete            
WHERE REPLACE(col, 'veeeeeeery_long_string', '')::int % 3 = 0;    
--  b) Lookup how much space this table consumes after previous DELETE;
SELECT *,
       pg_size_pretty(total_bytes) AS total,
       pg_size_pretty(index_bytes) AS INDEX,
       pg_size_pretty(toast_bytes) AS toast,
       pg_size_pretty(table_bytes) AS TABLE
FROM (
    SELECT *,
           total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
    FROM (
        SELECT c.oid,
               nspname AS table_schema,
               relname AS table_name,
               c.reltuples AS row_estimate,
               pg_total_relation_size(c.oid) AS total_bytes,
               pg_indexes_size(c.oid) AS index_bytes,
               pg_total_relation_size(reltoastrelid) AS toast_bytes
        FROM pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
    ) a
) a
WHERE table_name LIKE '%table_to_delete%';
--      c) Perform the following command (if you're using DBeaver, press Ctrl+Shift+O to observe server output (VACUUM results)): 
VACUUM FULL VERBOSE table_to_delete;
--      d) Check space consumption of the table once again and make conclusions;
SELECT *,
       pg_size_pretty(total_bytes) AS total,
       pg_size_pretty(index_bytes) AS INDEX,
       pg_size_pretty(toast_bytes) AS toast,
       pg_size_pretty(table_bytes) AS TABLE
FROM (
    SELECT *,
           total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
    FROM (
        SELECT c.oid,
               nspname AS table_schema,
               relname AS table_name,
               c.reltuples AS row_estimate,
               pg_total_relation_size(c.oid) AS total_bytes,
               pg_indexes_size(c.oid) AS index_bytes,
               pg_total_relation_size(reltoastrelid) AS toast_bytes
        FROM pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
    ) a
) a
WHERE table_name LIKE '%table_to_delete%';
--      e) Recreate ‘table_to_delete’ table;
DROP TABLE IF EXISTS table_to_delete;
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1, (10^7)::int) x;

--4. Issue the following TRUNCATE operation:
TRUNCATE table_to_delete;
--      a) Note how much time it takes to perform this TRUNCATE statement.
DO $$ 
DECLARE 
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    start_time := clock_timestamp();
    EXECUTE 'TRUNCATE table_to_delete';
    end_time := clock_timestamp();
    RAISE NOTICE 'Duration: %', end_time - start_time;
END $$;
--      b) Compare with previous results and make conclusion.
--      c) Check space consumption of the table once again and make conclusions;
SELECT *,
       pg_size_pretty(total_bytes) AS total,
       pg_size_pretty(index_bytes) AS INDEX,
       pg_size_pretty(toast_bytes) AS toast,
       pg_size_pretty(table_bytes) AS TABLE
FROM (
    SELECT *,
           total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
    FROM (
        SELECT c.oid,
               nspname AS table_schema,
               relname AS table_name,
               c.reltuples AS row_estimate,
               pg_total_relation_size(c.oid) AS total_bytes,
               pg_indexes_size(c.oid) AS index_bytes,
               pg_total_relation_size(reltoastrelid) AS toast_bytes
        FROM pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
    ) a
) a
WHERE table_name LIKE '%table_to_delete%';
/*5. Hand over your investigation's results to your trainer. The results must include:

a) Space consumption of ‘table_to_delete’ table before and after each operation;

Operation	            				Space consumption
Before delete	         				    574 MB
After delete								575 MB
Before truncate, but after vacuum			383 MB
After truncate								8192 bytes



b) Duration of each operation (DELETE, TRUNCATE)

Operation								Duration
Delete									19174.854 ms
Truncate								30 ms


Results: 
Comparing the DELETE and TRUNCATE function in space consumption, we can see that although we deleted the data, 
the space consumption became even higher than before. The reason for that is when rows are deleted PostgreSQL does not immediately reclaim the space. 
Instead, it marks the rows as dead tuples in the table. These dead tuples are invisible to new transactions but still occupy space, 
which allows PostgreSQL to roll back transactions if needed. As a result, deleted rows remain in the storage until a VACUUM operation removes them. 
On the other hand, TRUNCATE directly removes all rows and frees up space immediately, so it does not create dead tuples and does not require a VACUUM to reclaim storage.

Comparing Delete and Truncate we can also see a huge difference in execution time, the same result was established with delete for approximately 19175 ms,
while with truncate only 30 ms. The reason for that is DELETE is a row-level operation, meaning it processes each row individually and logs each deletion, 
while TRUNCATE operates at the table level and simply removes all rows at once without processing each row individually, making it significantly faster. */





