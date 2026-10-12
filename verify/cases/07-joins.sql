-- Section 7: JOINs, with the data shown in the guide. ORDER BY added so the
-- output doesn't depend on the engine's row order.
-- guide-sections: 7
CREATE TABLE customers (id INT PRIMARY KEY, name VARCHAR(100));
CREATE TABLE orders (id INT PRIMARY KEY, customer_id INT, amount DECIMAL(10,2));
INSERT INTO customers VALUES (1, 'Ana'), (2, 'Luis'), (3, 'Marta');
INSERT INTO orders VALUES (10, 1, 50), (11, 1, 30), (12, 2, 80), (13, 99, 20);

SELECT c.name, o.amount FROM customers c INNER JOIN orders o ON o.customer_id = c.id ORDER BY o.id;
SELECT c.name, o.amount FROM customers c LEFT JOIN orders o ON o.customer_id = c.id ORDER BY c.id, o.id;
SELECT c.name FROM customers c LEFT JOIN orders o ON o.customer_id = c.id WHERE o.id IS NULL;
SELECT c.name, o.amount FROM customers c RIGHT JOIN orders o ON o.customer_id = c.id ORDER BY o.id;
SELECT c.name, o.amount FROM customers c FULL OUTER JOIN orders o ON o.customer_id = c.id ORDER BY c.id, o.id;   -- not in MySQL

CREATE TABLE sizes (size VARCHAR(5));
INSERT INTO sizes VALUES ('S'), ('M'), ('L');
SELECT c.name, s.size FROM customers c CROSS JOIN sizes s ORDER BY c.id, s.size DESC;

CREATE TABLE employees (id INT PRIMARY KEY, name VARCHAR(50), manager_id INT);
INSERT INTO employees VALUES (1, 'Carmen', NULL), (2, 'Pedro', 1), (3, 'Lucía', 1), (4, 'Jorge', 2);
SELECT e.name AS employee, m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id
ORDER BY e.id;

SELECT c.name, COUNT(o.id) AS order_count, COALESCE(SUM(o.amount), 0) AS total
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY total DESC, c.name;
