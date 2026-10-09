-- Section 15: constraints (the guide's CREATE TABLE uses MySQL's AUTO_INCREMENT).
-- guide-sections: 15
CREATE TABLE customers (id INT PRIMARY KEY, name VARCHAR(100) NOT NULL, email VARCHAR(150));
INSERT INTO customers VALUES (1, 'Ana', 'ana@mail.com');

CREATE TABLE orders (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    customer_id  INT NOT NULL,
    product      VARCHAR(100) NOT NULL,
    amount       DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    status       VARCHAR(20) DEFAULT 'pending'
                 CHECK (status IN ('pending', 'shipped', 'delivered')),
    order_date   DATE NOT NULL,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT uq_order_day
        UNIQUE (customer_id, product, order_date)
);

INSERT INTO orders (customer_id, product, amount, order_date)
VALUES (1, 'Keyboard', -5, '2026-01-10');
INSERT INTO orders (customer_id, product, amount, order_date)
VALUES (999, 'Keyboard', 50, '2026-01-10');
INSERT INTO orders (customer_id, product, amount, order_date)
VALUES (1, 'Keyboard', 50, '2026-01-10');
INSERT INTO orders (customer_id, product, amount, order_date)
VALUES (1, 'Keyboard', 60, '2026-01-10');
SELECT customer_id, product, status FROM orders;
DELETE FROM customers WHERE id = 1;
SELECT COUNT(*) AS orders_after_cascade FROM orders;

CREATE TABLE order_items (
    order_id    INT,
    product_id  INT,
    quantity    INT NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (order_id, product_id)
);
INSERT INTO order_items VALUES (1, 1, 1);
INSERT INTO order_items VALUES (1, 1, 2);

ALTER TABLE customers ADD CONSTRAINT uq_email UNIQUE (email);
ALTER TABLE customers ADD CONSTRAINT chk_name CHECK (LENGTH(name) > 1);
INSERT INTO customers VALUES (2, 'X', 'x@mail.com');
ALTER TABLE customers DROP CONSTRAINT chk_name;
INSERT INTO customers VALUES (2, 'X', 'x@mail.com');
SELECT id, name FROM customers;
