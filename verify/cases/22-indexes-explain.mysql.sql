-- Section 22: when MySQL uses an index. EXPLAIN's row estimates vary between
-- runs, so only the access type and the chosen index are kept (EXPLAIN INTO
-- needs MySQL 8.1+).
-- guide-sections: 22
CREATE TABLE customers (id INT PRIMARY KEY, name VARCHAR(100), phone VARCHAR(20));
CREATE TABLE orders (id INT PRIMARY KEY, customer_id INT, order_date DATE, amount INT);
SET SESSION cte_max_recursion_depth = 20000;
INSERT INTO customers
WITH RECURSIVE n AS (SELECT 1 AS i UNION ALL SELECT i + 1 FROM n WHERE i < 10000)
SELECT i, CONCAT('Name', i), CAST(600000000 + i AS CHAR) FROM n;
INSERT INTO orders
WITH RECURSIVE n AS (SELECT 1 AS i UNION ALL SELECT i + 1 FROM n WHERE i < 10000)
SELECT i, i % 1000, DATE '2024-01-01' + INTERVAL (i % 1000) DAY, i % 300 FROM n;
ANALYZE TABLE orders, customers;

EXPLAIN FORMAT=JSON INTO @e SELECT * FROM orders WHERE customer_id = 1;
SELECT 'before index' AS query, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.access_type')) AS type, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.key')) AS key_used;
CREATE INDEX idx_orders_customer ON orders(customer_id);
EXPLAIN FORMAT=JSON INTO @e SELECT * FROM orders WHERE customer_id = 1;
SELECT 'after index' AS query, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.access_type')) AS type, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.key')) AS key_used;

CREATE INDEX idx_name ON customers(name);
CREATE INDEX idx_phone ON customers(phone);
CREATE INDEX idx_date ON orders(order_date);

EXPLAIN FORMAT=JSON INTO @e SELECT * FROM customers WHERE name LIKE 'Name12%';
SELECT 'LIKE prefix%' AS query, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.access_type')) AS type, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.key')) AS key_used;
EXPLAIN FORMAT=JSON INTO @e SELECT * FROM customers WHERE name LIKE '%12';
SELECT 'LIKE %suffix' AS query, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.access_type')) AS type, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.key')) AS key_used;
EXPLAIN FORMAT=JSON INTO @e SELECT * FROM orders WHERE YEAR(order_date) = 2024;
SELECT 'YEAR(column)' AS query, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.access_type')) AS type, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.key')) AS key_used;
EXPLAIN FORMAT=JSON INTO @e SELECT * FROM orders WHERE order_date >= '2024-03-01' AND order_date < '2024-03-05';
SELECT 'date range' AS query, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.access_type')) AS type, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.key')) AS key_used;
EXPLAIN FORMAT=JSON INTO @e SELECT * FROM customers WHERE phone = 600000123;
SELECT 'phone = number' AS query, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.access_type')) AS type, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.key')) AS key_used;
EXPLAIN FORMAT=JSON INTO @e SELECT * FROM customers WHERE phone = '600000123';
SELECT 'phone = string' AS query, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.access_type')) AS type, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.key')) AS key_used;

DROP INDEX idx_orders_customer ON orders;
DROP INDEX idx_date ON orders;
CREATE INDEX idx_customer_date ON orders (customer_id, order_date);
EXPLAIN FORMAT=JSON INTO @e SELECT * FROM orders WHERE customer_id = 1;
SELECT 'composite: first column' AS query, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.access_type')) AS type, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.key')) AS key_used;
EXPLAIN FORMAT=JSON INTO @e SELECT * FROM orders WHERE customer_id = 1 AND order_date > '2024-01-01';
SELECT 'composite: both columns' AS query, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.access_type')) AS type, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.key')) AS key_used;
EXPLAIN FORMAT=JSON INTO @e SELECT * FROM orders WHERE order_date > '2024-01-01';
SELECT 'composite: second only' AS query, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.access_type')) AS type, JSON_UNQUOTE(JSON_EXTRACT(@e, '$.query_block.table.key')) AS key_used;
