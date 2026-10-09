-- Section 23: isolation level and SELECT ... FOR UPDATE (MySQL). The
-- two-session read anomalies need concurrent connections and aren't covered.
-- guide-sections: 23
CREATE TABLE inventory (product VARCHAR(50) PRIMARY KEY, quantity INT);
INSERT INTO inventory VALUES ('Keyboard', 10);

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
START TRANSACTION;
SELECT quantity FROM inventory WHERE product = 'Keyboard' FOR UPDATE;
UPDATE inventory SET quantity = quantity - 1 WHERE product = 'Keyboard';
COMMIT;
SELECT quantity FROM inventory;

-- Changing it inside a transaction is an error in MySQL.
START TRANSACTION;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
COMMIT;
