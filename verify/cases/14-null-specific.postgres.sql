-- Section 14: PostgreSQL's NULL-safe comparison, || with NULL, NULLS LAST.
-- guide-sections: 14
CREATE TABLE customers (id INT PRIMARY KEY, name VARCHAR(50), city VARCHAR(50));
INSERT INTO customers VALUES (1, 'Ana', 'Madrid'), (2, 'Luis', 'Seville'), (3, 'Marta', NULL);
SELECT NULL IS NOT DISTINCT FROM NULL AS both_null, 'Hello ' || NULL IS NULL AS pipes_give_null;
SELECT name FROM customers ORDER BY city DESC NULLS LAST;
