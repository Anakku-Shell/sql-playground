-- Section 13: procedure and function (PostgreSQL).
-- guide-sections: 13
CREATE TABLE orders (id INT PRIMARY KEY, customer_id INT, amount NUMERIC(10,2));
INSERT INTO orders VALUES (10, 1, 50), (11, 1, 30), (12, 2, 80);

CREATE OR REPLACE PROCEDURE apply_discount(p_customer_id INT, p_pct NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_pct <= 0 OR p_pct > 50 THEN
        RAISE EXCEPTION 'Discount out of range (0-50%%)';
    END IF;

    UPDATE orders
    SET amount = amount * (1 - p_pct / 100)
    WHERE customer_id = p_customer_id;
END;
$$;
CALL apply_discount(1, 10);
SELECT id, amount FROM orders WHERE customer_id = 1 ORDER BY id;
CALL apply_discount(1, 80);

CREATE OR REPLACE FUNCTION customer_orders(p_customer_id INT)
RETURNS TABLE (id INT, amount NUMERIC)
LANGUAGE sql
AS $$
    SELECT o.id, o.amount FROM orders o WHERE o.customer_id = p_customer_id;
$$;
SELECT * FROM customer_orders(1) ORDER BY id;
