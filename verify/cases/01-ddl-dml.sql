-- Sections 1-2: creating tables, INSERT/UPDATE/DELETE.
-- guide-sections: 1, 2
CREATE TABLE customers (
    id           INT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    email        VARCHAR(150) UNIQUE,
    city         VARCHAR(50),
    signup_date  DATE DEFAULT (CURRENT_DATE)
);
CREATE TABLE orders (
    id           INT PRIMARY KEY,
    customer_id  INT,
    product      VARCHAR(100),
    amount       DECIMAL(10,2),
    order_date   DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);
ALTER TABLE customers ADD COLUMN phone VARCHAR(20);
ALTER TABLE customers DROP COLUMN phone;
TRUNCATE TABLE orders;

-- The foreign key must reject an order for a customer that doesn't exist.
INSERT INTO orders (id, customer_id) VALUES (1, 999);
SELECT COUNT(*) AS orphan_orders FROM orders;

INSERT INTO customers (id, name, email, city) VALUES (1, 'Ana', 'ana@mail.com', 'Madrid');
INSERT INTO customers (id, name, city) VALUES
    (2, 'Luis',  'Seville'),
    (3, 'Marta', 'Madrid');
SELECT id, signup_date IS NOT NULL AS has_default_date FROM customers ORDER BY id;

CREATE TABLE madrid_customers (id INT, name VARCHAR(100));
INSERT INTO madrid_customers (id, name)
SELECT id, name FROM customers WHERE city = 'Madrid';
SELECT * FROM madrid_customers ORDER BY id;

UPDATE customers
SET city = 'Barcelona', email = 'luis@mail.com'
WHERE id = 2;
SELECT id, name, email, city FROM customers ORDER BY id;

DELETE FROM orders WHERE order_date < '2024-01-01';
DROP TABLE madrid_customers;
DROP TABLE orders;
