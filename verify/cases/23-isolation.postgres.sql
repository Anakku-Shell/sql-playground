-- Section 23: isolation level and SELECT ... FOR UPDATE (PostgreSQL). The
-- two-session read anomalies need concurrent connections and aren't covered.
-- guide-sections: 23
CREATE TABLE inventory (product VARCHAR(50) PRIMARY KEY, quantity INT);
INSERT INTO inventory VALUES ('Keyboard', 10);

BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SHOW transaction_isolation;
SELECT quantity FROM inventory WHERE product = 'Keyboard' FOR UPDATE;
UPDATE inventory SET quantity = quantity - 1 WHERE product = 'Keyboard';
COMMIT;
SELECT quantity FROM inventory;

BEGIN ISOLATION LEVEL REPEATABLE READ;
SHOW transaction_isolation;
COMMIT;

-- Outside a transaction it only warns and changes nothing.
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
