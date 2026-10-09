-- Section 21: recursive CTEs with the PostgreSQL changes the guide describes
-- (CAST AS TEXT, INTERVAL '1 day' cast back to DATE, generate_series).
-- guide-sections: 21
CREATE TABLE employees (id INT PRIMARY KEY, name VARCHAR(50), manager_id INT);
INSERT INTO employees VALUES (1, 'Carmen', NULL), (2, 'Pedro', 1), (3, 'Lucía', 1), (4, 'Jorge', 2);
CREATE TABLE orders (id INT PRIMARY KEY, amount DECIMAL(10,2), order_date DATE);
INSERT INTO orders VALUES (1, 50, '2026-01-02'), (2, 30, '2026-01-02'), (3, 10, '2026-01-04');

WITH RECURSIVE hierarchy AS (
    SELECT id, name, 1 AS level,
           CAST(name AS TEXT) AS path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.id, e.name, h.level + 1,
           CONCAT(h.path, ' > ', e.name)
    FROM employees e
    JOIN hierarchy h ON e.manager_id = h.id
)
SELECT name, level, path
FROM hierarchy
ORDER BY path;

WITH RECURSIVE days AS (
    SELECT DATE '2026-01-01' AS day
    UNION ALL
    SELECT CAST(day + INTERVAL '1 day' AS DATE) FROM days WHERE day < '2026-01-31'
)
SELECT d.day, COALESCE(SUM(o.amount), 0) AS sales
FROM days d
LEFT JOIN orders o ON o.order_date = d.day
GROUP BY d.day
ORDER BY d.day
LIMIT 5;

SELECT COUNT(*) AS days_in_january
FROM generate_series(DATE '2026-01-01', DATE '2026-01-31', INTERVAL '1 day');
