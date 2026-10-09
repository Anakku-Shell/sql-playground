-- Sections 11-12: indexes, views, transactions. Each engine rejects the
-- DROP INDEX form that belongs to the other one.
-- guide-sections: 11, 12
CREATE TABLE customers (id INT PRIMARY KEY, name VARCHAR(100));
CREATE TABLE orders (id INT PRIMARY KEY, customer_id INT, amount DECIMAL(10,2), order_date DATE,
                     FOREIGN KEY (customer_id) REFERENCES customers(id));
INSERT INTO customers VALUES (1, 'Ana'), (2, 'Luis');
INSERT INTO orders VALUES (10, 1, 50, '2026-01-10'), (11, 1, 30, '2026-02-15'), (12, 2, 80, '2026-01-20'), (16, 1, 120, '2026-03-12');

CREATE INDEX idx_orders_date ON orders(order_date);
DROP INDEX idx_orders_date ON orders;
DROP INDEX idx_orders_date;

CREATE VIEW customer_summary AS
SELECT c.name, SUM(o.amount) AS total
FROM customers c JOIN orders o ON o.customer_id = c.id
GROUP BY c.name;
SELECT * FROM customer_summary WHERE total > 100;

CREATE TABLE accounts (id INT PRIMARY KEY, balance DECIMAL(10,2));
INSERT INTO accounts VALUES (1, 500), (2, 100);
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;
BEGIN;
UPDATE accounts SET balance = 0;
ROLLBACK;
SELECT * FROM accounts ORDER BY id;
