-- Section 14: NULL behaviour shared by both engines (differences show in the
-- snapshots: CONCAT with NULL, NULL position in ORDER BY).
-- guide-sections: 14
CREATE TABLE customers (id INT PRIMARY KEY, name VARCHAR(50), email VARCHAR(50), city VARCHAR(50));
INSERT INTO customers VALUES (1, 'Ana', 'ana@mail.com', 'Madrid'), (2, 'Luis', NULL, 'Seville'), (3, 'Marta', NULL, NULL);

SELECT COUNT(*) AS eq_null FROM customers WHERE email = NULL;
SELECT COUNT(*) AS is_null FROM customers WHERE email IS NULL;
SELECT name AS not_madrid FROM customers WHERE city <> 'Madrid' ORDER BY id;
SELECT name AS not_madrid_or_null FROM customers WHERE city <> 'Madrid' OR city IS NULL ORDER BY id;

CREATE TABLE t (amount INT);
INSERT INTO t VALUES (10), (NULL), (20);
SELECT COUNT(*) AS c_all, COUNT(amount) AS c_amount, SUM(amount) AS s, AVG(amount) AS a FROM t;
SELECT AVG(COALESCE(amount, 0)) AS avg_null_as_zero FROM t;
SELECT 100 + NULL AS plus_null;
SELECT CONCAT('Hello ', NULL) AS concat_null;
SELECT name AS ordered_by_city FROM customers ORDER BY city;
SELECT city, COUNT(*) AS n FROM customers GROUP BY city ORDER BY n, city;

CREATE TABLE u (x INT UNIQUE);
INSERT INTO u VALUES (NULL), (NULL);
SELECT COUNT(*) AS unique_nulls FROM u;
