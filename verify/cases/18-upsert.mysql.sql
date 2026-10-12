-- Section 18: UPSERT in MySQL.
-- guide-sections: 18
CREATE TABLE inventory (product VARCHAR(50) PRIMARY KEY, quantity INT);
INSERT INTO inventory VALUES ('Keyboard', 10);

INSERT INTO inventory (product, quantity)
VALUES ('Keyboard', 5), ('Mouse', 3) AS new
ON DUPLICATE KEY UPDATE quantity = inventory.quantity + new.quantity;

SELECT * FROM inventory ORDER BY product;
