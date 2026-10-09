-- Section 18: UPSERT in PostgreSQL.
-- guide-sections: 18
CREATE TABLE inventory (product VARCHAR(50) PRIMARY KEY, quantity INT);
INSERT INTO inventory VALUES ('Keyboard', 10);

INSERT INTO inventory (product, quantity)
VALUES ('Keyboard', 5), ('Mouse', 3)
ON CONFLICT (product)
DO UPDATE SET quantity = inventory.quantity + EXCLUDED.quantity;

INSERT INTO inventory VALUES ('Keyboard', 5) ON CONFLICT DO NOTHING;

SELECT * FROM inventory ORDER BY product;
