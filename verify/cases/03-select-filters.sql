-- Sections 3-6: SELECT, WHERE, LIKE, ORDER BY/LIMIT, aggregation.
-- guide-sections: 3, 4, 5, 6
CREATE TABLE customers (id INT PRIMARY KEY, name VARCHAR(100), email VARCHAR(150), city VARCHAR(50), signup_date DATE);
CREATE TABLE orders (id INT PRIMARY KEY, customer_id INT, product VARCHAR(100), amount DECIMAL(10,2), order_date DATE);
INSERT INTO customers VALUES
    (1, 'Ana',    'ana@mail.com',    'Madrid',  '2025-03-01'),
    (2, 'Luis',   NULL,              'Seville', '2024-06-15'),
    (3, 'Marta',  'marta@gmail.com', 'Madrid',  '2026-01-10'),
    (4, 'Álvarez','alv@mail.com',    'Valencia','2025-09-01');
INSERT INTO orders VALUES
    (10, 1, 'Keyboard', 50,  '2026-01-10'),
    (11, 1, 'Mouse',    30,  '2026-02-15'),
    (12, 2, 'Monitor',  80,  '2026-01-20'),
    (16, 1, 'Monitor',  120, '2026-03-12'),
    (17, 3, 'Laptop',   900, '2026-03-20');

SELECT name AS customer FROM customers ORDER BY id;
SELECT DISTINCT city FROM customers ORDER BY city;
SELECT id FROM orders WHERE amount >= 100 ORDER BY id;
SELECT name FROM customers WHERE city = 'Madrid' AND signup_date > '2025-01-01' ORDER BY id;
SELECT name FROM customers WHERE NOT city = 'Madrid' ORDER BY id;
SELECT id FROM orders WHERE amount BETWEEN 50 AND 200 ORDER BY id;
SELECT name FROM customers WHERE city IN ('Madrid', 'Seville', 'Valencia') ORDER BY id;
SELECT name FROM customers WHERE email IS NULL;
SELECT name AS starts_with_a FROM customers WHERE name LIKE 'A%' ORDER BY id;
SELECT name AS ends_with_ez FROM customers WHERE name LIKE '%ez';
SELECT name AS gmail FROM customers WHERE email LIKE '%gmail%';
SELECT name AS second_letter_a FROM customers WHERE name LIKE '_a%' ORDER BY id;
SELECT name AS not_a FROM customers WHERE name NOT LIKE 'A%' ORDER BY id;
SELECT name AS lower_like FROM customers WHERE LOWER(name) LIKE 'ana%';
SELECT name AS ilike FROM customers WHERE name ILIKE 'ana%';   -- PostgreSQL only

SELECT id, amount FROM orders ORDER BY amount DESC LIMIT 2;
SELECT id FROM orders ORDER BY order_date LIMIT 2 OFFSET 1;
SELECT name FROM customers ORDER BY city ASC, name;

SELECT COUNT(*) AS n, COUNT(email) AS with_email FROM customers;
SELECT SUM(amount) AS total, MIN(amount) AS min_amount, MAX(amount) AS max_amount FROM orders;
SELECT customer_id, SUM(amount) AS total FROM orders GROUP BY customer_id ORDER BY customer_id;
SELECT city, COUNT(*) AS customer_count FROM customers GROUP BY city ORDER BY customer_count DESC, city;
SELECT customer_id, SUM(amount) AS total FROM orders GROUP BY customer_id HAVING SUM(amount) > 500;
