-- Sections 8-10: subqueries, UNION/INTERSECT/EXCEPT, useful functions.
-- guide-sections: 8, 9, 10
CREATE TABLE customers (id INT PRIMARY KEY, name VARCHAR(100), email VARCHAR(150), city VARCHAR(50));
CREATE TABLE orders (id INT PRIMARY KEY, customer_id INT, product VARCHAR(100), amount DECIMAL(10,2), order_date DATE);
INSERT INTO customers VALUES (1, 'Ana', 'ana@mail.com', 'Madrid'), (2, 'Luis', NULL, 'Seville'), (3, 'Marta', NULL, 'Madrid');
INSERT INTO orders VALUES (10, 1, 'Keyboard', 50, '2026-01-10'), (11, 1, 'Mouse', 30, '2026-02-15'),
                          (12, 2, 'Monitor', 80, '2026-01-20'), (16, 1, 'Monitor', 120, '2026-03-12');

SELECT id FROM orders WHERE amount > (SELECT AVG(amount) FROM orders) ORDER BY id;
SELECT name FROM customers WHERE id IN (SELECT customer_id FROM orders) ORDER BY id;
SELECT name FROM customers WHERE id NOT IN (SELECT customer_id FROM orders WHERE customer_id IS NOT NULL);
SELECT c.name FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id AND o.amount > 100);
SELECT c.name, (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.id) AS order_count
FROM customers c ORDER BY c.id;
SELECT AVG(total) AS avg_spend
FROM (SELECT customer_id, SUM(amount) AS total FROM orders GROUP BY customer_id) AS totals;
WITH totals AS (SELECT customer_id, SUM(amount) AS total FROM orders GROUP BY customer_id)
SELECT c.name, t.total FROM totals t JOIN customers c ON c.id = t.customer_id WHERE t.total > 100;
SELECT id FROM orders WHERE amount > ALL (SELECT amount FROM orders WHERE customer_id = 2) ORDER BY id;

CREATE TABLE suppliers (city VARCHAR(50));
INSERT INTO suppliers VALUES ('Madrid'), ('Bilbao');
SELECT city FROM customers UNION SELECT city FROM suppliers ORDER BY city;
SELECT city FROM customers UNION ALL SELECT city FROM suppliers ORDER BY city;
SELECT city FROM customers INTERSECT SELECT city FROM suppliers;
SELECT city FROM customers EXCEPT SELECT city FROM suppliers;

SELECT product, amount,
       CASE
           WHEN amount >= 100 THEN 'expensive'
           WHEN amount >= 50  THEN 'medium'
           ELSE 'cheap'
       END AS price_range
FROM orders ORDER BY id;
SELECT name, COALESCE(email, 'no email') AS email FROM customers ORDER BY id;
SELECT NULLIF(0, 0) AS nullif_zero;
SELECT UPPER(name) AS u, LOWER(name) AS l, LENGTH(name) AS len, TRIM(' x ') AS t,
       SUBSTRING(name, 1, 3) AS sub, CONCAT(name, ' - ', city) AS c, REPLACE(email, '@', ' at ') AS r
FROM customers WHERE id = 1;
-- In MySQL || is a logical OR, so this returns 0 there.
SELECT name || ' - ' || city AS pipes FROM customers WHERE id = 1;
SELECT EXTRACT(YEAR FROM order_date) AS y FROM orders WHERE id = 10;
-- YEAR() doesn't exist in PostgreSQL.
SELECT YEAR(order_date) AS y FROM orders WHERE id = 10;
