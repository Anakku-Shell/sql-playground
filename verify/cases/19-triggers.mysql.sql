-- Section 19: triggers (MySQL).
-- guide-sections: 19
CREATE TABLE orders (id INT PRIMARY KEY, amount DECIMAL(10,2));
INSERT INTO orders VALUES (10, 50);
CREATE TABLE customers (id INT PRIMARY KEY, email VARCHAR(100));

CREATE TABLE amount_history (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    order_id      INT,
    old_amount    DECIMAL(10,2),
    new_amount    DECIMAL(10,2),
    changed_at    DATETIME
);

DELIMITER //

CREATE TRIGGER trg_orders_history
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF NOT (OLD.amount <=> NEW.amount) THEN
        INSERT INTO amount_history (order_id, old_amount, new_amount, changed_at)
        VALUES (OLD.id, OLD.amount, NEW.amount, NOW());
    END IF;
END //

DELIMITER ;

UPDATE orders SET amount = 45 WHERE id = 10;
-- Same value again: the trigger must not log it.
UPDATE orders SET amount = 45 WHERE id = 10;
SELECT order_id, old_amount, new_amount FROM amount_history;

DELIMITER //

CREATE TRIGGER trg_customers_email
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
    SET NEW.email = LOWER(TRIM(NEW.email));
END //

DELIMITER ;

INSERT INTO customers VALUES (1, 'Ana@Mail.com ');
SELECT CONCAT('[', email, ']') AS saved_email FROM customers;

DROP TRIGGER IF EXISTS trg_customers_email;
SELECT TRIGGER_NAME FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA = DATABASE();
