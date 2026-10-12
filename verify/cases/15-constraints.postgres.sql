-- Section 15: identity columns and ALTER TABLE constraints (PostgreSQL).
-- guide-sections: 15
CREATE TABLE customers (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150)
);
CREATE TABLE legacy (id SERIAL PRIMARY KEY, note TEXT);
INSERT INTO customers (name) VALUES ('Ana'), ('Luis');
INSERT INTO legacy (note) VALUES ('a'), ('b');
SELECT id, name FROM customers ORDER BY id;
SELECT id, note FROM legacy ORDER BY id;

CREATE TABLE orders (
    id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    amount      NUMERIC(10,2) NOT NULL CHECK (amount >= 0)
);
INSERT INTO orders (customer_id, amount) VALUES (1, -5);
INSERT INTO orders (customer_id, amount) VALUES (999, 50);
INSERT INTO orders (customer_id, amount) VALUES (1, 50);
DELETE FROM customers WHERE id = 1;
SELECT COUNT(*) AS orders_after_cascade FROM orders;

ALTER TABLE customers ADD CONSTRAINT uq_email UNIQUE (email);
ALTER TABLE customers ADD CONSTRAINT chk_name CHECK (LENGTH(name) > 1);
INSERT INTO customers (name) VALUES ('X');
ALTER TABLE customers DROP CONSTRAINT chk_name;
INSERT INTO customers (name) VALUES ('X');
SELECT name FROM customers ORDER BY id;
