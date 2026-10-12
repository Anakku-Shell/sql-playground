-- Section 13: stored procedures (MySQL).
-- guide-sections: 13
CREATE TABLE orders (id INT PRIMARY KEY, customer_id INT, amount DECIMAL(10,2));
INSERT INTO orders VALUES (10, 1, 50), (11, 1, 30), (12, 2, 80);
CREATE TABLE accounts (id INT PRIMARY KEY, balance DECIMAL(10,2));
INSERT INTO accounts VALUES (1, 500), (2, 100);
CREATE TABLE sizes (size VARCHAR(5));

DELIMITER //
CREATE PROCEDURE customer_orders(IN p_customer_id INT)
BEGIN
    SELECT id, amount
    FROM orders
    WHERE customer_id = p_customer_id
    ORDER BY id;
END //
DELIMITER ;
CALL customer_orders(1);

DELIMITER //
CREATE PROCEDURE get_customer_total(IN p_customer_id INT, OUT p_total DECIMAL(10,2))
BEGIN
    SELECT COALESCE(SUM(amount), 0)
    INTO p_total
    FROM orders
    WHERE customer_id = p_customer_id;
END //
DELIMITER ;
CALL get_customer_total(1, @total);
SELECT @total;

DELIMITER //
CREATE PROCEDURE apply_discount(IN p_customer_id INT, IN p_pct DECIMAL(5,2))
BEGIN
    DECLARE v_order_count INT;

    IF p_pct <= 0 OR p_pct > 50 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Discount out of range (0-50%)';
    END IF;

    SELECT COUNT(*) INTO v_order_count
    FROM orders WHERE customer_id = p_customer_id;

    IF v_order_count = 0 THEN
        SELECT 'The customer has no orders' AS message;
    ELSE
        UPDATE orders
        SET amount = amount * (1 - p_pct / 100)
        WHERE customer_id = p_customer_id;

        SELECT ROW_COUNT() AS updated_orders;
    END IF;
END //
DELIMITER ;
CALL apply_discount(1, 10);
SELECT id, amount FROM orders WHERE customer_id = 1 ORDER BY id;
CALL apply_discount(3, 10);
CALL apply_discount(1, 80);

DELIMITER //
CREATE PROCEDURE transfer_funds(IN p_from INT, IN p_to INT, IN p_amount DECIMAL(10,2))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        UPDATE accounts SET balance = balance - p_amount WHERE id = p_from;
        UPDATE accounts SET balance = balance + p_amount WHERE id = p_to;
    COMMIT;
END //
DELIMITER ;
CALL transfer_funds(1, 2, 100);
SELECT * FROM accounts ORDER BY id;

DELIMITER //
CREATE PROCEDURE fill_sizes()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 3 DO
        INSERT INTO sizes (size) VALUES (ELT(i, 'S', 'M', 'L'));
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;
CALL fill_sizes();
SELECT * FROM sizes;

DROP PROCEDURE IF EXISTS apply_discount;
SELECT ROUTINE_NAME FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = DATABASE() ORDER BY ROUTINE_NAME;
