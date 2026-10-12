# SQL Quick Review

🇪🇸 [Versión en español](sql-guide-es.md)

📂 Also available as [one file per section](sections/en/README.md)

## How to read this guide

Each section shows its **level** and its **importance**:

| Level            | Importance                                          |
|------------------|-----------------------------------------------------|
| 🟢 Basic         | ⭐⭐⭐ Essential: used every day                      |
| 🟡 Intermediate  | ⭐⭐ Very useful: shows up often in real work         |
| 🔴 Advanced      | ⭐ Good to know: specific cases or more theory        |

Sections 1–13 are the **core**. Sections 14–23 are **going further**, ordered from easiest to hardest (and, within the same level, from most to least important). Section 24 has **exercises** to check what you've learned.

**Core**
1. Creating and altering tables · 🟢 ⭐⭐⭐
2. INSERT, UPDATE, DELETE · 🟢 ⭐⭐⭐
3. Basic SELECT · 🟢 ⭐⭐⭐
4. WHERE, LIKE and filters · 🟢 ⭐⭐⭐
5. ORDER BY and LIMIT · 🟢 ⭐⭐⭐
6. Aggregation and GROUP BY · 🟢 ⭐⭐⭐
7. JOINs · 🟡 ⭐⭐⭐
8. Subqueries · 🟡 ⭐⭐⭐
9. UNION, INTERSECT, EXCEPT · 🟡 ⭐⭐
10. Useful functions · 🟢 ⭐⭐
11. Indexes and views (the essentials) · 🟡 ⭐⭐
12. Transactions · 🟡 ⭐⭐⭐
13. Stored procedures · 🟡 ⭐⭐

**Going further**

14. NULL pitfalls · 🟢 ⭐⭐⭐
15. Constraints in depth · 🟢 ⭐⭐⭐
16. Normalization · 🟢 ⭐⭐
17. Window functions · 🟡 ⭐⭐⭐
18. UPSERT (insert or update) · 🟡 ⭐⭐
19. Triggers · 🟡 ⭐⭐
20. Users and permissions · 🟡 ⭐
21. Recursive CTEs · 🔴 ⭐⭐
22. Indexes in depth and EXPLAIN · 🔴 ⭐⭐
23. Transaction isolation and ACID · 🔴 ⭐

**Practice**

24. Exercises with solutions · 🟢🟡🔴

---

All examples use these two tables:

```sql
-- customers(id, name, email, city, signup_date)
-- orders(id, customer_id, product, amount, order_date)
```

---

## 1. Creating and altering tables (DDL) · 🟢 ⭐⭐⭐

```sql
CREATE TABLE customers (
    id           INT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    email        VARCHAR(150) UNIQUE,
    city         VARCHAR(50),
    signup_date  DATE DEFAULT (CURRENT_DATE)    -- MySQL requires the parentheses
);

CREATE TABLE orders (
    id           INT PRIMARY KEY,
    customer_id  INT,
    product      VARCHAR(100),
    amount       DECIMAL(10,2),
    order_date   DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(id)   -- foreign key
);

ALTER TABLE customers ADD COLUMN phone VARCHAR(20);   -- add a column
ALTER TABLE customers DROP COLUMN phone;              -- remove a column

DROP TABLE orders;        -- deletes the whole table (structure + data)
TRUNCATE TABLE orders;    -- empties the table but keeps it
```

> ⚠️ Declare the foreign key separately, as above. MySQL accepts `customer_id INT REFERENCES customers(id)` inside the column, but **silently ignores it** and creates no constraint (PostgreSQL does create it).

---

## 2. INSERT, UPDATE, DELETE (DML) · 🟢 ⭐⭐⭐

### INSERT

```sql
-- One row
INSERT INTO customers (id, name, email, city)
VALUES (1, 'Ana', 'ana@mail.com', 'Madrid');

-- Several rows at once
INSERT INTO customers (id, name, city) VALUES
    (2, 'Luis',  'Seville'),
    (3, 'Marta', 'Madrid');

-- Insert from a SELECT
INSERT INTO madrid_customers (id, name)
SELECT id, name FROM customers WHERE city = 'Madrid';
```

### UPDATE

```sql
UPDATE customers
SET city = 'Barcelona', email = 'luis@mail.com'
WHERE id = 2;
```

> ⚠️ Without `WHERE`, `UPDATE` affects **every** row.

### DELETE

```sql
DELETE FROM orders WHERE order_date < '2024-01-01';
```

> ⚠️ Same here: without `WHERE` it deletes everything.

---

## 3. Basic SELECT · 🟢 ⭐⭐⭐

```sql
SELECT * FROM customers;                        -- all columns
SELECT name, city FROM customers;               -- specific columns
SELECT name AS customer FROM customers;         -- column alias
SELECT DISTINCT city FROM customers;            -- no duplicates
```

### Logical order of a SELECT

```sql
SELECT    columns
FROM      table
WHERE     row filter
GROUP BY  grouping
HAVING    group filter
ORDER BY  sorting
LIMIT     n;
```

(It's written in that order, but it's *executed* roughly as FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT. That's why you can't use a SELECT alias inside the WHERE.)

> Without `ORDER BY`, row order is **not guaranteed**: each engine may return rows however it likes. This guide shows results in the order that's easiest to read.

---

## 4. WHERE and filter operators · 🟢 ⭐⭐⭐

```sql
-- Comparison: =, <>, !=, <, >, <=, >=
SELECT * FROM orders WHERE amount >= 100;

-- AND / OR / NOT
SELECT * FROM customers WHERE city = 'Madrid' AND signup_date > '2025-01-01';
SELECT * FROM customers WHERE NOT city = 'Madrid';

-- BETWEEN (both ends included)
SELECT * FROM orders WHERE amount BETWEEN 50 AND 200;

-- IN / NOT IN
SELECT * FROM customers WHERE city IN ('Madrid', 'Seville', 'Valencia');

-- NULL (never use = NULL!)
SELECT * FROM customers WHERE email IS NULL;
SELECT * FROM customers WHERE email IS NOT NULL;
```

### LIKE (text patterns)

| Wildcard | Means                       |
|----------|-----------------------------|
| `%`      | zero or more characters     |
| `_`      | exactly one character       |

```sql
SELECT * FROM customers WHERE name LIKE 'A%';       -- starts with A
SELECT * FROM customers WHERE name LIKE '%ez';      -- ends with "ez"
SELECT * FROM customers WHERE email LIKE '%gmail%'; -- contains "gmail"
SELECT * FROM customers WHERE name LIKE '_a%';      -- 2nd letter is "a"
SELECT * FROM customers WHERE name NOT LIKE 'A%';

-- Case-insensitive
SELECT * FROM customers WHERE LOWER(name) LIKE 'ana%';
SELECT * FROM customers WHERE name ILIKE 'ana%';    -- PostgreSQL only
```

---

## 5. ORDER BY and LIMIT · 🟢 ⭐⭐⭐

```sql
SELECT * FROM orders ORDER BY amount DESC;               -- highest to lowest
SELECT * FROM customers ORDER BY city ASC, name;         -- several criteria

SELECT * FROM orders ORDER BY amount DESC LIMIT 5;       -- top 5 (MySQL, PostgreSQL, SQLite)
SELECT * FROM orders ORDER BY order_date LIMIT 10 OFFSET 20; -- pagination

SELECT TOP 5 * FROM orders ORDER BY amount DESC;         -- SQL Server equivalent
```

---

## 6. Aggregate functions and GROUP BY · 🟢 ⭐⭐⭐

```sql
SELECT COUNT(*)       FROM orders;            -- number of rows
SELECT COUNT(email)   FROM customers;         -- number of NON-null values
SELECT SUM(amount)    FROM orders;
SELECT AVG(amount)    FROM orders;
SELECT MIN(amount), MAX(amount) FROM orders;
```

### GROUP BY

```sql
-- Total spent per customer
SELECT customer_id, SUM(amount) AS total
FROM orders
GROUP BY customer_id;

-- Customers per city
SELECT city, COUNT(*) AS customer_count
FROM customers
GROUP BY city
ORDER BY customer_count DESC;
```

> Rule: every column in the `SELECT` that isn't inside an aggregate function must be in the `GROUP BY`.

### HAVING (filtering groups)

```sql
-- Customers who have spent more than 500
SELECT customer_id, SUM(amount) AS total
FROM orders
GROUP BY customer_id
HAVING SUM(amount) > 500;
```

**WHERE vs HAVING:** `WHERE` filters rows *before* grouping; `HAVING` filters groups *after*.

---

## 7. JOINs · 🟡 ⭐⭐⭐

They combine rows from several tables based on a condition.

```
customers                orders
+----+-------+          +----+-------------+--------+
| id | name  |          | id | customer_id | amount |
+----+-------+          +----+-------------+--------+
| 1  | Ana   |          | 10 | 1           | 50     |
| 2  | Luis  |          | 11 | 1           | 30     |
| 3  | Marta |          | 12 | 2           | 80     |
+----+-------+          | 13 | 99          | 20     |  <- customer doesn't exist
                        +----+-------------+--------+
```

(Order 13 can only exist if `orders` has no foreign key; it's here to show what each JOIN does with unmatched rows.)

### INNER JOIN — only rows that match on both sides

```sql
SELECT c.name, o.amount
FROM customers c
INNER JOIN orders o ON o.customer_id = c.id;
-- Ana 50, Ana 30, Luis 80   (Marta doesn't appear, neither does order 13)
```

A plain `JOIN` = `INNER JOIN`.

### LEFT JOIN — every row on the left, even without a match

```sql
SELECT c.name, o.amount
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id;
-- Ana 50, Ana 30, Luis 80, Marta NULL
```

Classic trick — customers **without** orders:

```sql
SELECT c.name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.id IS NULL;
-- Marta
```

### RIGHT JOIN — every row on the right

```sql
SELECT c.name, o.amount
FROM customers c
RIGHT JOIN orders o ON o.customer_id = c.id;
-- Ana 50, Ana 30, Luis 80, NULL 20
```

(In practice people almost always use LEFT JOIN and swap the table order.)

### FULL OUTER JOIN — every row from both sides

```sql
SELECT c.name, o.amount
FROM customers c
FULL OUTER JOIN orders o ON o.customer_id = c.id;
-- Ana 50, Ana 30, Luis 80, Marta NULL, NULL 20
```

(MySQL doesn't support it; you simulate it with `LEFT JOIN ... UNION ... RIGHT JOIN`.)

### CROSS JOIN — Cartesian product (every row with every row)

It has no `ON`: it pairs **every** row on the left with **every** row on the right. If one table has 3 rows and the other has 3, you get 3 × 3 = 9.

```
sizes
+------+
| size |
+------+
| S    |
| M    |
| L    |
+------+
```

```sql
SELECT c.name, s.size
FROM customers c
CROSS JOIN sizes s;
```

```
+-------+------+
| name  | size |
+-------+------+
| Ana   | S    |
| Ana   | M    |
| Ana   | L    |
| Luis  | S    |
| Luis  | M    |
| Luis  | L    |
| Marta | S    |
| Marta | M    |
| Marta | L    |
+-------+------+
```

(Without `ORDER BY` the engine may return them in a different order; add `ORDER BY c.name` to group them by customer.)

Useful for generating every possible combination (products × sizes, employees × days of the month...). Careful with big tables: 10,000 × 10,000 = 100 million rows.

Fun fact: an `INNER JOIN` is really a `CROSS JOIN` with the `ON` filter applied afterwards. And writing `FROM customers, sizes` (with a comma and no `WHERE`) also produces a Cartesian product, often by accident.

### SELF JOIN — a table joined with itself

```
employees
+----+--------+------------+
| id | name   | manager_id |
+----+--------+------------+
| 1  | Carmen | NULL       |   <- the boss, has no manager
| 2  | Pedro  | 1          |
| 3  | Lucía  | 1          |
| 4  | Jorge  | 2          |
+----+--------+------------+
```

```sql
SELECT e.name AS employee, m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;
```

```
+----------+---------+
| employee | manager |
+----------+---------+
| Carmen   | NULL    |
| Pedro    | Carmen  |
| Lucía    | Carmen  |
| Jorge    | Pedro   |
+----------+---------+
```

The same table appears twice with different aliases (`e` = the employee, `m` = their manager). With `INNER JOIN` instead of `LEFT JOIN`, Carmen would disappear, because her `manager_id` is NULL and finds no match.

### JOIN + GROUP BY (a very common combination)

```sql
SELECT c.name, COUNT(o.id) AS order_count, COALESCE(SUM(o.amount), 0) AS total
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY total DESC, c.name;
```

```
+-------+-------------+-------+
| name  | order_count | total |
+-------+-------------+-------+
| Ana   | 2           | 80    |
| Luis  | 1           | 80    |
| Marta | 0           | 0     |
+-------+-------------+-------+
```

Note `COUNT(o.id)` rather than `COUNT(*)`: Marta has one row in the LEFT JOIN (with `o.id` set to NULL), so `COUNT(*)` would give 1, while `COUNT(o.id)` gives 0, which is correct. And `SUM` over only NULLs returns NULL; hence the `COALESCE(..., 0)`.

---

## 8. Subqueries · 🟡 ⭐⭐⭐

A `SELECT` inside another one.

### In the WHERE, returning a single value

```sql
-- Orders above the average
SELECT * FROM orders
WHERE amount > (SELECT AVG(amount) FROM orders);
```

### In the WHERE with IN / NOT IN

```sql
-- Customers who have placed at least one order
SELECT name FROM customers
WHERE id IN (SELECT customer_id FROM orders);

-- Customers who have never ordered
SELECT name FROM customers
WHERE id NOT IN (SELECT customer_id FROM orders WHERE customer_id IS NOT NULL);
```

> ⚠️ `NOT IN` returns **nothing** if the subquery contains any `NULL`. Hence the `IS NOT NULL` filter — or better, use `NOT EXISTS`.

### EXISTS / NOT EXISTS (correlated subquery)

```sql
-- Customers with at least one order over 100
SELECT c.name FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.id AND o.amount > 100
);
```

"Correlated" = the subquery uses columns from the outer query (`c.id`), so it's evaluated for each row.

### In the SELECT (scalar subquery)

```sql
SELECT c.name,
       (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.id) AS order_count
FROM customers c;
```

### In the FROM (derived table)

```sql
-- Average total spend per customer
SELECT AVG(total) AS avg_spend
FROM (
    SELECT customer_id, SUM(amount) AS total
    FROM orders
    GROUP BY customer_id
) AS totals;             -- the alias is mandatory in most engines
```

### CTE with WITH (a named, more readable subquery)

```sql
WITH totals AS (
    SELECT customer_id, SUM(amount) AS total
    FROM orders
    GROUP BY customer_id
)
SELECT c.name, t.total
FROM totals t
JOIN customers c ON c.id = t.customer_id
WHERE t.total > 100;
```

### ANY / ALL

```sql
-- Orders larger than ALL of customer 1's orders
SELECT * FROM orders
WHERE amount > ALL (SELECT amount FROM orders WHERE customer_id = 1);
```

---

## 9. UNION, INTERSECT, EXCEPT · 🟡 ⭐⭐

They combine the results of several SELECTs (same number of columns and compatible types).

```sql
SELECT city FROM customers
UNION                -- combines and removes duplicates
SELECT city FROM suppliers;

SELECT city FROM customers
UNION ALL            -- combines and keeps duplicates (faster)
SELECT city FROM suppliers;

SELECT city FROM customers
INTERSECT            -- only those in both
SELECT city FROM suppliers;

SELECT city FROM customers
EXCEPT               -- those in the top query but not in the bottom one (MINUS in Oracle)
SELECT city FROM suppliers;
```

---

## 10. Useful functions · 🟢 ⭐⭐

### CASE (if/else)

```sql
SELECT product, amount,
       CASE
           WHEN amount >= 100 THEN 'expensive'
           WHEN amount >= 50  THEN 'medium'
           ELSE 'cheap'
       END AS price_range
FROM orders;
```

### NULLs

```sql
SELECT COALESCE(email, 'no email') FROM customers;   -- first non-null value
SELECT NULLIF(amount, 0) FROM orders;                -- NULL if amount = 0
```

### Text

```sql
UPPER(name), LOWER(name)
LENGTH(name)                -- LEN() in SQL Server
TRIM(name)
SUBSTRING(name, 1, 3)
CONCAT(name, ' - ', city)   -- or name || ' - ' || city in PostgreSQL/SQLite (in MySQL, || is a logical OR)
REPLACE(email, '@', ' at ')
```

### Dates (vary a lot between engines)

```sql
CURRENT_DATE, CURRENT_TIMESTAMP
EXTRACT(YEAR FROM order_date)      -- PostgreSQL / MySQL
YEAR(order_date)                   -- MySQL / SQL Server
```

---

## 11. Indexes and views (the essentials) · 🟡 ⭐⭐

```sql
CREATE INDEX idx_orders_date ON orders(order_date);       -- speeds up searching and sorting by date
DROP INDEX idx_orders_date ON orders;                     -- MySQL and SQL Server
DROP INDEX idx_orders_date;                               -- PostgreSQL and SQLite

CREATE VIEW customer_summary AS                           -- a "saved query"
SELECT c.name, SUM(o.amount) AS total
FROM customers c JOIN orders o ON o.customer_id = c.id
GROUP BY c.name;

SELECT * FROM customer_summary WHERE total > 100;
```

---

## 12. Transactions · 🟡 ⭐⭐⭐

```sql
BEGIN;   -- or START TRANSACTION
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;  -- saves the changes

-- If something goes wrong:
ROLLBACK; -- undoes everything since BEGIN
```

---

## 13. Stored procedures · 🟡 ⭐⭐

A stored procedure is a named block of SQL that's saved **in the database** and run with a call. It can take parameters and use variables, `IF`, loops and transactions.

They're useful for:
- Reusing logic: write it once and call it from any application.
- Doing multi-step operations in a single call, with fewer round trips to the server.
- Security: you can grant permission to run the procedure without granting direct access to the tables.

> ⚠️ The syntax varies **a lot** between engines. The examples below are in **MySQL**; equivalents for SQL Server and PostgreSQL are at the end.

### Basic procedure with an input parameter

```sql
DELIMITER //                      -- changes the statement terminator so the inner ; don't cut off the CREATE

CREATE PROCEDURE customer_orders(IN p_customer_id INT)
BEGIN
    SELECT id, amount
    FROM orders
    WHERE customer_id = p_customer_id
    ORDER BY id;
END //

DELIMITER ;                       -- back to the normal ;
```

```sql
CALL customer_orders(1);
```

```
+----+--------+
| id | amount |
+----+--------+
| 10 | 50     |
| 11 | 30     |
+----+--------+
```

### Output parameter (OUT)

```sql
DELIMITER //

CREATE PROCEDURE get_customer_total(IN p_customer_id INT, OUT p_total DECIMAL(10,2))
BEGIN
    SELECT COALESCE(SUM(amount), 0)
    INTO p_total                  -- stores the result in the output parameter
    FROM orders
    WHERE customer_id = p_customer_id;
END //

DELIMITER ;
```

```sql
CALL get_customer_total(1, @total);   -- @total is a session variable
SELECT @total;
```

```
+--------+
| @total |
+--------+
| 80.00  |
+--------+
```

Parameter types: `IN` (input, the default), `OUT` (output) and `INOUT` (a value goes in and comes out modified).

### Variables, IF and errors

```sql
DELIMITER //

CREATE PROCEDURE apply_discount(IN p_customer_id INT, IN p_pct DECIMAL(5,2))
BEGIN
    DECLARE v_order_count INT;            -- local variable (always at the start of the BEGIN)

    IF p_pct <= 0 OR p_pct > 50 THEN
        SIGNAL SQLSTATE '45000'           -- raises an error and stops execution
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
```

```sql
CALL apply_discount(1, 10);
-- updated_orders = 2   (Ana's orders go from 50 and 30 to 45 and 27)

CALL apply_discount(3, 10);
-- message = 'The customer has no orders'   (Marta)

CALL apply_discount(1, 80);
-- ERROR 1644 (45000): Discount out of range (0-50%)
```

### With a transaction (all or nothing)

Uses the `accounts` table from the transactions section:

```sql
DELIMITER //

CREATE PROCEDURE transfer_funds(IN p_from INT, IN p_to INT, IN p_amount DECIMAL(10,2))
BEGIN
    -- On any SQL error: undo everything and re-raise the error
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
```

### Loop (WHILE)

```sql
DELIMITER //

CREATE PROCEDURE fill_sizes()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 3 DO
        INSERT INTO sizes (size) VALUES (ELT(i, 'S', 'M', 'L'));  -- ELT picks the i-th value
        SET i = i + 1;
    END WHILE;
END //

DELIMITER ;
```

(In SQL it's almost always better to work on sets than to loop. A single `INSERT ... VALUES (...), (...), (...)` would do the same.)

### Managing them

```sql
SHOW PROCEDURE STATUS WHERE Db = DATABASE();   -- list those in the current database
SHOW CREATE PROCEDURE apply_discount;          -- see the code
DROP PROCEDURE IF EXISTS apply_discount;       -- delete
```

To change one in MySQL you `DROP` it and `CREATE` it again (there's no `CREATE OR REPLACE PROCEDURE`).

### The same in other engines

**SQL Server (T-SQL):** parameters start with `@`, there's no `DELIMITER`, and you run it with `EXEC`.

```sql
CREATE OR ALTER PROCEDURE get_customer_total
    @customer_id INT,
    @total DECIMAL(10,2) OUTPUT
AS
BEGIN
    SELECT @total = COALESCE(SUM(amount), 0)
    FROM orders
    WHERE customer_id = @customer_id;
END;

DECLARE @t DECIMAL(10,2);
EXEC get_customer_total @customer_id = 1, @total = @t OUTPUT;
SELECT @t;   -- 80.00
```

**PostgreSQL:** the body goes between `$$` and you specify the language (`plpgsql`). A `PROCEDURE` is used to make changes; to **return data** you use a `FUNCTION`.

```sql
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
```

```sql
-- Function that returns a table: used inside a SELECT
CREATE OR REPLACE FUNCTION customer_orders(p_customer_id INT)
RETURNS TABLE (id INT, amount NUMERIC)
LANGUAGE sql
AS $$
    SELECT o.id, o.amount FROM orders o WHERE o.customer_id = p_customer_id;
$$;

SELECT * FROM customer_orders(1);
```

### Procedure vs function

|                           | Procedure                      | Function                              |
|---------------------------|--------------------------------|---------------------------------------|
| How it's called           | `CALL` / `EXEC`                | Inside a query: `SELECT f(x)`         |
| Returns                   | Nothing, OUT parameters or SELECT results | A value or a table         |
| Can modify data           | Yes                            | Usually not, or with restrictions     |
| Can manage transactions   | Yes (`COMMIT` / `ROLLBACK`)    | No                                    |

---

# Going further

---

## 14. NULL pitfalls · 🟢 ⭐⭐⭐

`NULL` isn't a value: it means **"unknown"**. That's why it doesn't behave like 0 or an empty string, and it's the most common source of bugs in SQL.

### NULL is never equal to anything (not even another NULL)

```sql
SELECT * FROM customers WHERE email = NULL;     -- ❌ never returns anything
SELECT * FROM customers WHERE email IS NULL;    -- ✅

-- Comparing two columns that may be NULL
WHERE a <=> b                    -- MySQL ("NULL-safe equal")
WHERE a IS NOT DISTINCT FROM b   -- PostgreSQL / standard
```

SQL uses **three-valued** logic: true, false and unknown. `NULL = NULL` is *unknown*, and `WHERE` only lets *true* through.

### "Negative" filters swallow NULLs

```
customers: Ana (Madrid), Luis (Seville), Marta (NULL)
```

```sql
SELECT name FROM customers WHERE city <> 'Madrid';
-- Luis      ← Marta is missing! NULL <> 'Madrid' is "unknown"

SELECT name FROM customers WHERE city <> 'Madrid' OR city IS NULL;
-- Luis, Marta
```

### Aggregate functions ignore NULLs

```
amounts: 10, NULL, 20
```

```sql
SELECT COUNT(*)       -- 3   (counts rows)
     , COUNT(amount)  -- 2   (counts non-null values)
     , SUM(amount)    -- 30
     , AVG(amount)    -- 15  (30 / 2, not 30 / 3 = 10!)
FROM t;

SELECT AVG(COALESCE(amount, 0)) FROM t;   -- 10, if you want NULL to count as 0
```

### Any operation with NULL gives NULL

```sql
SELECT 100 + NULL;                 -- NULL
SELECT amount * NULL;              -- NULL
SELECT CONCAT('Hello ', NULL);     -- NULL in MySQL; 'Hello ' in PostgreSQL
SELECT 'Hello ' || NULL;           -- NULL in PostgreSQL / SQLite
```

### Other details

- **`NOT IN` with a NULL in the list returns nothing** (see section 8). Use `NOT EXISTS`.
- **`GROUP BY`** puts all NULLs in the same group.
- **`ORDER BY`**: NULLs come first in MySQL and SQL Server (with ASC) and last in PostgreSQL and Oracle. In PostgreSQL you can force it with `ORDER BY city NULLS LAST`.
- **`UNIQUE`** allows multiple NULLs in most engines (SQL Server allows only one).

---

## 15. Constraints in depth · 🟢 ⭐⭐⭐

Constraints make the **database** reject bad data, instead of trusting the application never to make a mistake.

```sql
CREATE TABLE orders (
    id           INT AUTO_INCREMENT PRIMARY KEY,           -- automatic id (MySQL; other engines below)
    customer_id  INT NOT NULL,
    product      VARCHAR(100) NOT NULL,
    amount       DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    status       VARCHAR(20) DEFAULT 'pending'
                 CHECK (status IN ('pending', 'shipped', 'delivered')),
    order_date   DATE NOT NULL,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(id)
        ON DELETE CASCADE           -- if the customer is deleted, their orders are deleted too
        ON UPDATE CASCADE,          -- if the customer's id changes, it's updated here

    CONSTRAINT uq_order_day
        UNIQUE (customer_id, product, order_date)   -- unique across several columns
);
```

| Constraint     | What it prevents                                         |
|----------------|----------------------------------------------------------|
| `NOT NULL`     | Leaving the column empty                                 |
| `UNIQUE`       | Duplicate values                                         |
| `PRIMARY KEY`  | Duplicates and NULLs (= `UNIQUE` + `NOT NULL`); one per table |
| `FOREIGN KEY`  | Pointing to a row that doesn't exist in the other table  |
| `CHECK`        | Values that don't meet a condition                       |
| `DEFAULT`      | (Prevents nothing) Sets a value when none is given       |

### When a constraint is violated

```sql
INSERT INTO orders (customer_id, product, amount, order_date)
VALUES (1, 'Keyboard', -5, '2026-01-10');
-- ERROR: Check constraint 'orders_chk_1' is violated.

INSERT INTO orders (customer_id, product, amount, order_date)
VALUES (999, 'Keyboard', 50, '2026-01-10');
-- ERROR: Cannot add or update a child row: a foreign key constraint fails
```

### ON DELETE / ON UPDATE options

| Option                  | When the customer is deleted...                          |
|-------------------------|----------------------------------------------------------|
| `RESTRICT` / `NO ACTION`| Error if they have orders (the default behaviour)        |
| `CASCADE`               | Deletes their orders too                                 |
| `SET NULL`              | Sets `customer_id = NULL` on their orders                |
| `SET DEFAULT`           | Sets the default value (rarely supported)                |

> ⚠️ `CASCADE` is convenient but dangerous: one `DELETE` can remove far more than it seems.

### Auto-generated IDs by engine

```sql
id INT AUTO_INCREMENT PRIMARY KEY                    -- MySQL
id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY      -- PostgreSQL (modern); formerly: id SERIAL
id INT IDENTITY(1,1) PRIMARY KEY                     -- SQL Server
id INTEGER PRIMARY KEY AUTOINCREMENT                 -- SQLite
```

### Composite primary key

```sql
-- One row per product in each order
CREATE TABLE order_items (
    order_id    INT,
    product_id  INT,
    quantity    INT NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (order_id, product_id)         -- the pair can't repeat
);
```

### Adding or removing constraints on an existing table

```sql
ALTER TABLE customers ADD CONSTRAINT uq_email UNIQUE (email);
ALTER TABLE customers ADD CONSTRAINT chk_name CHECK (LENGTH(name) > 1);
ALTER TABLE customers DROP CONSTRAINT chk_name;    -- MySQL < 8.0.19: DROP CHECK / DROP INDEX
```

(In MySQL, `CHECK` is only actually enforced since version 8.0.16; before that it was silently ignored.)

---

## 16. Normalization · 🟢 ⭐⭐

It's the way to split data into tables so you **don't repeat information**. Repeated data leads to inconsistencies: if Ana's city appears in 50 rows, sooner or later one of them won't get updated.

### A badly designed table

```
bad_orders
+----------+----------+---------+-------------------+--------+
| order_id | customer | city    | products          | amount |
+----------+----------+---------+-------------------+--------+
| 10       | Ana      | Madrid  | Keyboard, Mouse   | 80     |
| 11       | Ana      | Madrid  | Monitor           | 120    |
| 12       | Luis     | Seville | Monitor, Keyboard | 130    |
+----------+----------+---------+-------------------+--------+
```

### 1st normal form (1NF): one value per cell

No lists like `"Keyboard, Mouse"`, and no repeated columns like `product1, product2, product3`. Each product goes in its own row, in an `order_items` table.

> If you find yourself doing `LIKE '%Keyboard%'` to search inside a list, the table isn't in 1NF.

### 2nd normal form (2NF): everything depends on the **whole** key

This only affects tables with a composite key. In `order_items(order_id, product_id, quantity, product_name)`, `product_name` depends only on `product_id`, not on the whole pair. So it moves to its own `products(id, name, price)` table.

### 3rd normal form (3NF): nothing depends on a column other than the key

In `orders(id, customer_id, customer_city)`, the city depends on the **customer**, not the order. It belongs in `customers`.

### Result

```
customers(id, name, city)
products(id, name, price)
orders(id, customer_id, order_date)
order_items(order_id, product_id, quantity)
```

The classic summary: *every column depends on the key, the whole key, and nothing but the key.*

> Sometimes you **denormalize** on purpose (for example, storing a pre-computed `total` in `orders`) to make queries faster. That's a deliberate decision, not an oversight.

---

## 17. Window functions · 🟡 ⭐⭐⭐

They compute over a group of rows **without collapsing them into one**, unlike `GROUP BY`. Each row keeps its data and also gets the result. Available in MySQL 8+, PostgreSQL, SQL Server and SQLite 3.25+.

```sql
function() OVER (
    PARTITION BY column   -- groups (optional; without it, the whole table is one group)
    ORDER BY column       -- order within each group (optional depending on the function)
)
```

Data for this section:

```
orders
+----+-------------+------------+--------+
| id | customer_id | order_date | amount |
+----+-------------+------------+--------+
| 10 | 1           | 2026-01-10 | 50     |
| 11 | 1           | 2026-02-15 | 30     |
| 12 | 2           | 2026-01-20 | 80     |
| 14 | 2           | 2026-03-05 | 40     |
| 15 | 3           | 2026-02-01 | 60     |
+----+-------------+------------+--------+
```

### GROUP BY vs window

```sql
-- GROUP BY: one row per customer
SELECT customer_id, SUM(amount) AS total
FROM orders GROUP BY customer_id;
```

```sql
-- Window: every row, each with its customer's total
SELECT id, customer_id, amount,
       SUM(amount) OVER (PARTITION BY customer_id) AS customer_total
FROM orders;
```

```
+----+-------------+--------+----------------+
| id | customer_id | amount | customer_total |
+----+-------------+--------+----------------+
| 10 | 1           | 50     | 80             |
| 11 | 1           | 30     | 80             |
| 12 | 2           | 80     | 120            |
| 14 | 2           | 40     | 120            |
| 15 | 3           | 60     | 60             |
+----+-------------+--------+----------------+
```

This lets you, for example, work out what percentage of its customer's spending each order represents: `amount * 100.0 / SUM(amount) OVER (PARTITION BY customer_id)`.

### ROW_NUMBER, RANK and DENSE_RANK (numbering and ranking)

```
scores: 100, 90, 90, 80
```

```sql
SELECT points,
       ROW_NUMBER() OVER (ORDER BY points DESC) AS row_num,
       RANK()       OVER (ORDER BY points DESC) AS rnk,
       DENSE_RANK() OVER (ORDER BY points DESC) AS dense_rnk
FROM scores;
```

```
+--------+------------+------+------------+
| points | row_num    | rnk  | dense_rnk  |
+--------+------------+------+------------+
| 100    | 1          | 1    | 1          |
| 90     | 2          | 2    | 2          |
| 90     | 3          | 2    | 2          |
| 80     | 4          | 4    | 3          |
+--------+------------+------+------------+
```

- `ROW_NUMBER`: numbers 1, 2, 3... even with ties.
- `RANK`: ties share a position **and the next one is skipped** (like in a race).
- `DENSE_RANK`: ties share a position, **with no gaps**.

### Top N per group (the most typical use)

Each customer's most expensive order:

```sql
WITH ranked AS (
    SELECT o.*,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY amount DESC) AS rn
    FROM orders o
)
SELECT id, customer_id, amount
FROM ranked
WHERE rn = 1;            -- rn <= 3 for the top 3
```

```
+----+-------------+--------+
| id | customer_id | amount |
+----+-------------+--------+
| 10 | 1           | 50     |
| 12 | 2           | 80     |
| 15 | 3           | 60     |
+----+-------------+--------+
```

(You can't put `WHERE rn = 1` in the same query, because windows are computed after the `WHERE`. That's why you need the CTE or a subquery.)

### Running total

```sql
SELECT id, order_date, amount,
       SUM(amount) OVER (ORDER BY order_date) AS running_total
FROM orders;
```

```
+----+------------+--------+---------------+
| id | order_date | amount | running_total |
+----+------------+--------+---------------+
| 10 | 2026-01-10 | 50     | 50            |
| 12 | 2026-01-20 | 80     | 130           |
| 15 | 2026-02-01 | 60     | 190           |
| 11 | 2026-02-15 | 30     | 220           |
| 14 | 2026-03-05 | 40     | 260           |
+----+------------+--------+---------------+
```

With `ORDER BY` inside the `OVER`, `SUM` adds up "from the start up to this row".

### LAG and LEAD (looking at the previous or next row)

```sql
SELECT id, customer_id, order_date, amount,
       LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous,
       amount - LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS difference
FROM orders;
```

```
+----+-------------+------------+--------+----------+------------+
| id | customer_id | order_date | amount | previous | difference |
+----+-------------+------------+--------+----------+------------+
| 10 | 1           | 2026-01-10 | 50     | NULL     | NULL       |
| 11 | 1           | 2026-02-15 | 30     | 50       | -20        |
| 12 | 2           | 2026-01-20 | 80     | NULL     | NULL       |
| 14 | 2           | 2026-03-05 | 40     | 80       | -40        |
| 15 | 3           | 2026-02-01 | 60     | NULL     | NULL       |
+----+-------------+------------+--------+----------+------------+
```

`LEAD` works the same way but looks at the **next** row. Both accept a default value: `LAG(amount, 1, 0)` returns 0 instead of NULL.

### Window frame (moving average)

```sql
-- Average of this order and the 2 before it
AVG(amount) OVER (ORDER BY order_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
```

### Other window functions

`FIRST_VALUE(col)`, `LAST_VALUE(col)`, `NTILE(4)` (splits into 4 groups, i.e. quartiles), and any aggregate (`COUNT`, `AVG`, `MIN`, `MAX`) with `OVER`.

---

## 18. UPSERT (insert or update) · 🟡 ⭐⭐

"If the row doesn't exist, insert it; if it does, update it", in a single statement. It needs a `PRIMARY KEY` or `UNIQUE` to know what "already exists" means.

```
inventory (product is the PRIMARY KEY)
+----------+----------+
| product  | quantity |
+----------+----------+
| Keyboard | 10       |
+----------+----------+
```

**MySQL**

```sql
INSERT INTO inventory (product, quantity)
VALUES ('Keyboard', 5), ('Mouse', 3) AS new
ON DUPLICATE KEY UPDATE quantity = inventory.quantity + new.quantity;
```

(Before 8.0.19 you wrote `quantity = quantity + VALUES(quantity)`.)

**PostgreSQL / SQLite**

```sql
INSERT INTO inventory (product, quantity)
VALUES ('Keyboard', 5), ('Mouse', 3)
ON CONFLICT (product)
DO UPDATE SET quantity = inventory.quantity + EXCLUDED.quantity;   -- EXCLUDED = the row you tried to insert

-- If it already exists, ignore it:
INSERT INTO inventory VALUES ('Keyboard', 5) ON CONFLICT DO NOTHING;
```

**SQL Server (MERGE)**

```sql
MERGE inventory AS t
USING (VALUES ('Keyboard', 5), ('Mouse', 3)) AS s (product, quantity)
ON t.product = s.product
WHEN MATCHED THEN
    UPDATE SET t.quantity = t.quantity + s.quantity
WHEN NOT MATCHED THEN
    INSERT (product, quantity) VALUES (s.product, s.quantity);
```

Result in every case:

```
+----------+----------+
| product  | quantity |
+----------+----------+
| Keyboard | 15       |   ← already existed: 10 + 5
| Mouse    | 3        |   ← didn't exist: inserted
+----------+----------+
```

---

## 19. Triggers · 🟡 ⭐⭐

A trigger is a block of code the database runs **automatically** when an `INSERT`, `UPDATE` or `DELETE` happens on a table. It's like a stored procedure nobody calls by hand.

| Timing   | Event                        | You can                                       |
|----------|------------------------------|-----------------------------------------------|
| `BEFORE` | `INSERT`/`UPDATE`/`DELETE` | Validate or modify `NEW` before it's saved    |
| `AFTER`  | `INSERT`/`UPDATE`/`DELETE` | React: history, auditing, totals              |

- `NEW` = the row as it will end up (in `INSERT` and `UPDATE`).
- `OLD` = the row as it was before (in `UPDATE` and `DELETE`).

### Keeping a change history (MySQL)

```sql
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
    IF NOT (OLD.amount <=> NEW.amount) THEN       -- <=> so it works with NULL (section 14)
        INSERT INTO amount_history (order_id, old_amount, new_amount, changed_at)
        VALUES (OLD.id, OLD.amount, NEW.amount, NOW());
    END IF;
END //

DELIMITER ;
```

```sql
UPDATE orders SET amount = 45 WHERE id = 10;
SELECT order_id, old_amount, new_amount FROM amount_history;
```

```
+----------+------------+------------+
| order_id | old_amount | new_amount |
+----------+------------+------------+
| 10       | 50.00      | 45.00      |
+----------+------------+------------+
```

### Normalizing data before saving (BEFORE)

```sql
DELIMITER //

CREATE TRIGGER trg_customers_email
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
    SET NEW.email = LOWER(TRIM(NEW.email));     -- 'Ana@Mail.com ' is stored as 'ana@mail.com'
END //

DELIMITER ;
```

### Managing them

```sql
SHOW TRIGGERS;
DROP TRIGGER IF EXISTS trg_customers_email;
```

In **PostgreSQL** you first create a function that `RETURNS trigger` and then `CREATE TRIGGER ... EXECUTE FUNCTION name()`. In **SQL Server** there's no `NEW` or `OLD`; you use the virtual tables `inserted` and `deleted`.

> ⚠️ Use them sparingly: it's "hidden" logic, because whoever runs an `UPDATE` doesn't see that something fires, and they slow down every write. They're ideal for auditing and history. For complex business rules, the application or a procedure is usually better.

---

## 20. Users and permissions · 🟡 ⭐

Golden rule: **least privilege**. Each user or application gets only the permissions it needs.

**MySQL**

```sql
CREATE USER 'analyst'@'localhost' IDENTIFIED BY 'change_this_password';
CREATE USER 'app'@'%' IDENTIFIED BY 'change_this_password';           -- '%' = from any host

GRANT SELECT ON shop.* TO 'analyst'@'localhost';                     -- read the whole database
GRANT SELECT, INSERT, UPDATE ON shop.orders TO 'app'@'%';            -- a specific table
GRANT EXECUTE ON PROCEDURE shop.apply_discount TO 'app'@'%';         -- only run one procedure

REVOKE UPDATE ON shop.orders FROM 'app'@'%';                         -- remove a permission

SHOW GRANTS FOR 'analyst'@'localhost';
DROP USER 'analyst'@'localhost';
```

### Roles (groups of permissions)

```sql
CREATE ROLE read_only;
GRANT SELECT ON shop.* TO read_only;

GRANT read_only TO 'analyst'@'localhost';
SET DEFAULT ROLE read_only TO 'analyst'@'localhost';   -- MySQL: activate it on login
```

**PostgreSQL**

```sql
CREATE ROLE analyst LOGIN PASSWORD 'change_this_password';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analyst;
REVOKE SELECT ON orders FROM analyst;
```

Common permissions: `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `EXECUTE`, `CREATE`, `ALTER`, `DROP` and `ALL PRIVILEGES`.

---

## 21. Recursive CTEs · 🔴 ⭐⭐

A CTE that calls itself. Useful for walking **hierarchies** (org charts, categories and subcategories, folders) and for **generating series**.

Structure:

```sql
WITH RECURSIVE name AS (
    -- 1) base case: the starting point
    SELECT ...
    UNION ALL
    -- 2) recursive step: joins to "name" to go one level further
    SELECT ... FROM table JOIN name ON ...
)
SELECT * FROM name;
```

### Full org chart

Uses the `employees` table from the self join (section 7): Carmen is the boss, Pedro and Lucía report to Carmen, and Jorge reports to Pedro.

```sql
-- MySQL
WITH RECURSIVE hierarchy AS (
    SELECT id, name, 1 AS level,
           CAST(name AS CHAR(200)) AS path            -- base case: whoever has no manager
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.id, e.name, h.level + 1,
           CONCAT(h.path, ' > ', e.name)              -- step: the reports of those already found
    FROM employees e
    JOIN hierarchy h ON e.manager_id = h.id
)
SELECT name, level, path
FROM hierarchy
ORDER BY path;
```

```
+--------+-------+-------------------------+
| name   | level | path                    |
+--------+-------+-------------------------+
| Carmen | 1     | Carmen                  |
| Lucía  | 2     | Carmen > Lucía          |
| Pedro  | 2     | Carmen > Pedro          |
| Jorge  | 3     | Carmen > Pedro > Jorge  |
+--------+-------+-------------------------+
```

A normal self join only gets you one level. The recursive one gets you all of them, without knowing how many there are.

In **PostgreSQL**, replace `CAST(name AS CHAR(200))` with `CAST(name AS TEXT)`: the column must have the same type in the base case and the recursive step.

### Generating a series (e.g. the days of a month)

```sql
-- MySQL
WITH RECURSIVE days AS (
    SELECT DATE '2026-01-01' AS day
    UNION ALL
    SELECT day + INTERVAL 1 DAY FROM days WHERE day < '2026-01-31'
)
SELECT d.day, COALESCE(SUM(o.amount), 0) AS sales
FROM days d
LEFT JOIN orders o ON o.order_date = d.day
GROUP BY d.day;           -- days WITHOUT sales also show up, with 0
```

In **PostgreSQL**, the recursive step is `SELECT CAST(day + INTERVAL '1 day' AS DATE) FROM days ...`. For series you can also use `generate_series(DATE '2026-01-01', DATE '2026-01-31', INTERVAL '1 day')` directly.

> ⚠️ If the recursive step never stops producing rows, the loop is infinite. MySQL stops it at 1000 iterations (`cte_max_recursion_depth`) and SQL Server at 100 (`OPTION (MAXRECURSION n)`).
>
> In SQL Server you write `WITH` without the `RECURSIVE` keyword.

---

## 22. Indexes in depth and EXPLAIN · 🔴 ⭐⭐

An index is like the index of a book: instead of reading every page (a *full scan*), you jump straight to where the data is. It's almost always implemented as a B-tree.

- **Benefit:** much faster reads in `WHERE`, `JOIN` and `ORDER BY`.
- **Cost:** it takes up space, and every `INSERT`, `UPDATE` or `DELETE` also has to update the index.

### What to index

- Columns used a lot in `WHERE` and `JOIN`, especially **foreign keys** (`orders.customer_id`). The `PRIMARY KEY` already gets an index automatically, and in MySQL so does every `FOREIGN KEY` (PostgreSQL doesn't index foreign keys for you).
- Columns with many distinct values (*high selectivity*): `email` yes; `gender` or `active (yes/no)` usually not.

### When the index ISN'T used even though it exists

```sql
-- Index on name
WHERE name LIKE 'Ana%'          -- ✅ uses it (knows where to start)
WHERE name LIKE '%Ana'          -- ❌ can't: a leading wildcard forces it to check everything

-- Index on order_date
WHERE YEAR(order_date) = 2026                                    -- ❌ a function on the column defeats the index
WHERE order_date >= '2026-01-01' AND order_date < '2027-01-01'   -- ✅ same query, rewritten

-- Index on phone (VARCHAR)
WHERE phone = 600123123         -- ❌ implicit type conversion
WHERE phone = '600123123'       -- ✅
```

### Composite indexes: the leftmost-prefix rule

```sql
CREATE INDEX idx_customer_date ON orders (customer_id, order_date);
```

| Query                                                 | Uses the index?               |
|-------------------------------------------------------|-------------------------------|
| `WHERE customer_id = 1`                               | ✅                            |
| `WHERE customer_id = 1 AND order_date > '2026-01-01'` | ✅ (ideal)                    |
| `WHERE order_date > '2026-01-01'`                     | ❌ the first column is missing |

It works like a phone book sorted by (last name, first name): you can look up by last name, but not by first name alone.

### EXPLAIN: seeing how the query will be executed

```sql
EXPLAIN SELECT * FROM orders WHERE customer_id = 1;
```

Example MySQL output (simplified), **before** creating the index:

```
+--------+------+------+--------+
| table  | type | key  | rows   |
+--------+------+------+--------+
| orders | ALL  | NULL | 100000 |   ← ALL = scans the whole table
+--------+------+------+--------+
```

**After** `CREATE INDEX idx_orders_customer ON orders(customer_id)` (in MySQL, a `FOREIGN KEY` on that column would already have created one):

```
+--------+------+---------------------+------+
| table  | type | key                 | rows |
+--------+------+---------------------+------+
| orders | ref  | idx_orders_customer | 12   |   ← uses the index and reads 12 rows
+--------+------+---------------------+------+
```

What to look at:
- **`type`**: from worst to best, `ALL` (whole table) → `index` → `range` → `ref` → `eq_ref` → `const`.
- **`key`**: the index it uses (`NULL` = none).
- **`rows`**: how many rows it estimates it will read.

In **PostgreSQL**, `EXPLAIN ANALYZE` actually runs the query and shows the real timings. Look for `Seq Scan` (full scan) versus `Index Scan`.

---

## 23. Transaction isolation and ACID · 🔴 ⭐

### ACID: what a transaction guarantees

| Letter | Property     | Means                                                                 |
|--------|--------------|-----------------------------------------------------------------------|
| **A**  | Atomicity    | All or nothing: if one step fails, everything is undone               |
| **C**  | Consistency  | When it finishes, every constraint still holds                        |
| **I**  | Isolation    | Concurrent transactions don't step on each other (or only as much as you allow) |
| **D**  | Durability   | After `COMMIT`, the data survives even if the server crashes          |

### Problems when several transactions run at once

**Dirty read:** you read a change someone else **hasn't committed yet** and might roll back.

**Non-repeatable read:** you read the same row twice inside your transaction and get different values, because someone else changed and committed it in between.

| Step | Session A                                         | Session B                                              |
|------|---------------------------------------------------|--------------------------------------------------------|
| 1    | `BEGIN;`                                          |                                                        |
| 2    | `SELECT balance FROM accounts WHERE id=1;` → 500  |                                                        |
| 3    |                                                   | `UPDATE accounts SET balance=300 WHERE id=1; COMMIT;`  |
| 4    | `SELECT balance FROM accounts WHERE id=1;` → **?** |                                                       |

At step 4: with `READ COMMITTED` → **300**; with `REPEATABLE READ` → **500**.

**Phantom read:** you repeat a query with a `WHERE` and **new** rows appear that someone else inserted.

### Isolation levels

| Level              | Dirty read     | Non-repeatable | Phantom |
|--------------------|:--------------:|:--------------:|:-------:|
| `READ UNCOMMITTED` | ❌ can happen  | ❌             | ❌      |
| `READ COMMITTED`   | ✅ prevented   | ❌             | ❌      |
| `REPEATABLE READ`  | ✅             | ✅             | ❌*     |
| `SERIALIZABLE`     | ✅             | ✅             | ✅      |

\* MySQL (InnoDB) also prevents most phantoms under `REPEATABLE READ`.

More isolation means more safety, but more locking and lower performance.

- Defaults: **MySQL** uses `REPEATABLE READ`; **PostgreSQL**, **SQL Server** and **Oracle** use `READ COMMITTED`.

```sql
-- MySQL: set it BEFORE the transaction; it applies to the next one
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
START TRANSACTION;
...
COMMIT;

-- PostgreSQL: set it INSIDE the transaction (before outside it does nothing)
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;   -- or: BEGIN ISOLATION LEVEL SERIALIZABLE;
...
COMMIT;
```

### Lost update and SELECT ... FOR UPDATE

Two sessions read `stock = 10`, both sell 1, and both save `stock = 9`. It should be 8. To prevent this, you **lock the row** when reading it:

```sql
BEGIN;
SELECT quantity FROM inventory WHERE product = 'Keyboard' FOR UPDATE;  -- others wait here
UPDATE inventory SET quantity = quantity - 1 WHERE product = 'Keyboard';
COMMIT;                                                                -- the lock is released
```

(For this particular case, a single `UPDATE ... SET quantity = quantity - 1` is already safe on its own. `FOR UPDATE` is needed when you read, decide something in the application, and then write.)

### Deadlock

A locks row 1 and waits for row 2, while B locks row 2 and waits for row 1. The engine detects it and **cancels one of the two** with an error. The application should retry it.

To avoid it: keep transactions short and always access rows in the same order.

---

## 24. Exercises with solutions · 🟢🟡🔴

Script to create the data (drop everything first if you already had these tables):

```sql
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    id INT PRIMARY KEY, name VARCHAR(100), email VARCHAR(150),
    city VARCHAR(50), signup_date DATE
);
CREATE TABLE orders (
    id INT PRIMARY KEY, customer_id INT,
    product VARCHAR(100), amount DECIMAL(10,2), order_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

INSERT INTO customers VALUES
    (1, 'Ana',   'ana@mail.com',    'Madrid',   '2025-03-01'),
    (2, 'Luis',  NULL,              'Seville',  '2025-06-15'),
    (3, 'Marta', 'marta@gmail.com', 'Madrid',   '2026-01-10'),
    (4, 'Pablo', 'pablo@gmail.com', 'Valencia', '2026-02-20');

INSERT INTO orders VALUES
    (10, 1, 'Keyboard',  50, '2026-01-10'),
    (11, 1, 'Mouse',     30, '2026-02-15'),
    (12, 2, 'Monitor',   80, '2026-01-20'),
    (14, 2, 'Keyboard',  40, '2026-03-05'),
    (15, 3, 'Monitor',   60, '2026-02-01'),
    (16, 1, 'Monitor',  120, '2026-03-12');
```

Try each one before opening the solution.

### 🟢 1. Customers from Madrid, sorted by name

<details><summary>Solution</summary>

```sql
SELECT name FROM customers
WHERE city = 'Madrid'
ORDER BY name;
```
Result: Ana, Marta
</details>

### 🟢 2. Customers with a Gmail address

<details><summary>Solution</summary>

```sql
SELECT name, email FROM customers
WHERE email LIKE '%@gmail.com';
```
Result: Marta, Pablo
</details>

### 🟢 3. Customers without an email

<details><summary>Solution</summary>

```sql
SELECT name FROM customers WHERE email IS NULL;
```
Result: Luis. (`= NULL` wouldn't work; see section 14.)
</details>

### 🟢 4. Number of orders and total amount per product

<details><summary>Solution</summary>

```sql
SELECT product, COUNT(*) AS order_count, SUM(amount) AS total
FROM orders
GROUP BY product
ORDER BY total DESC;
```
Result: Monitor 3 / 260 · Keyboard 2 / 90 · Mouse 1 / 30
</details>

### 🟡 5. Total spent by each customer, including those who haven't ordered anything

<details><summary>Solution</summary>

```sql
SELECT c.name, COALESCE(SUM(o.amount), 0) AS total
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY total DESC;
```
Result: Ana 200 · Luis 120 · Marta 60 · Pablo 0
</details>

### 🟡 6. Customers who have never placed an order

<details><summary>Solution</summary>

```sql
SELECT c.name FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id);
```
Result: Pablo. (`LEFT JOIN ... WHERE o.id IS NULL` works too.)
</details>

### 🟡 7. Orders with an amount above the average

<details><summary>Solution</summary>

```sql
SELECT id, product, amount FROM orders
WHERE amount > (SELECT AVG(amount) FROM orders);
```
Average = 380 / 6 ≈ 63.33. Result: order 12 (80) and order 16 (120)
</details>

### 🟡 8. Cities with more than one customer

<details><summary>Solution</summary>

```sql
SELECT city, COUNT(*) AS customer_count
FROM customers
GROUP BY city
HAVING COUNT(*) > 1;
```
Result: Madrid 2
</details>

### 🟡 9. Customers who have spent more than the average spend per customer (counting only those who have ordered)

<details><summary>Solution</summary>

```sql
WITH totals AS (
    SELECT customer_id, SUM(amount) AS total
    FROM orders
    GROUP BY customer_id
)
SELECT c.name, t.total
FROM totals t
JOIN customers c ON c.id = t.customer_id
WHERE t.total > (SELECT AVG(total) FROM totals);
```
Totals: 200, 120 and 60, with an average of ≈ 126.67. Result: Ana (200)
</details>

### 🔴 10. Each customer's most expensive order

<details><summary>Solution</summary>

```sql
WITH ranked AS (
    SELECT o.*,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY amount DESC) AS rn
    FROM orders o
)
SELECT c.name, r.product, r.amount
FROM ranked r
JOIN customers c ON c.id = r.customer_id
WHERE r.rn = 1;
```
Result: Ana Monitor 120 · Luis Monitor 80 · Marta Monitor 60
</details>

### 🔴 11. Each customer's cumulative spend over time

<details><summary>Solution</summary>

```sql
SELECT c.name, o.order_date, o.amount,
       SUM(o.amount) OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS running_total
FROM orders o
JOIN customers c ON c.id = o.customer_id
ORDER BY c.name, o.order_date;
```
Result:
- Ana: 50 → 80 → 200
- Luis: 80 → 120
- Marta: 60
</details>

### 🔴 12. Difference between each order and the same customer's previous one

<details><summary>Solution</summary>

```sql
SELECT c.name, o.order_date, o.amount,
       o.amount - LAG(o.amount) OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS difference
FROM orders o
JOIN customers c ON c.id = o.customer_id
ORDER BY c.name, o.order_date;
```
Result:
- Ana: NULL, −20, +90
- Luis: NULL, −40
- Marta: NULL
</details>

### 🔴 13. Customers ranked by total spend (ties share a position)

<details><summary>Solution</summary>

```sql
SELECT c.name, SUM(o.amount) AS total,
       DENSE_RANK() OVER (ORDER BY SUM(o.amount) DESC) AS position
FROM customers c
JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name;
```
Result: Ana 1 · Luis 2 · Marta 3. The window is applied on top of the `GROUP BY` result, which is why it can use `SUM(...)`.
</details>

---

## Cheat sheet

| I want to...                           | Use                              |
|----------------------------------------|----------------------------------|
| Filter rows                            | `WHERE`                          |
| Search for similar text                | `LIKE '%text%'`                  |
| Match a value in a list                | `IN (...)`                       |
| Match a range                          | `BETWEEN a AND b`                |
| Check for NULLs                        | `IS NULL` / `IS NOT NULL`        |
| Remove duplicates                      | `DISTINCT`                       |
| Group and summarize                    | `GROUP BY` + `COUNT/SUM/AVG...`  |
| Filter groups                          | `HAVING`                         |
| Get matching data from 2 tables        | `INNER JOIN`                     |
| Get all of A even if not in B          | `LEFT JOIN`                      |
| Get the rows of A that are NOT in B    | `LEFT JOIN ... WHERE b.id IS NULL` or `NOT EXISTS` |
| Compare against a calculation on the table | Subquery in the `WHERE`      |
| Make a complex query readable          | `WITH` (CTE)                     |
| Combine results of two queries         | `UNION` / `UNION ALL`            |
| Use conditionals                       | `CASE WHEN ... THEN ... END`     |
| Store reusable logic in the database   | `CREATE PROCEDURE` + `CALL`      |
| Compare with NULL                      | `IS NULL`, never `= NULL`        |
| Prevent bad data                       | `NOT NULL`, `UNIQUE`, `CHECK`, `FOREIGN KEY` |
| Calculate per group without losing rows | `SUM(...) OVER (PARTITION BY ...)` |
| Get the top N per group                | `ROW_NUMBER() OVER (...)` + filter `rn <= N` |
| Get a running total                    | `SUM(...) OVER (ORDER BY ...)`   |
| Compare with the previous row          | `LAG(...) OVER (...)`            |
| Insert, or update if it exists         | `ON DUPLICATE KEY` / `ON CONFLICT` / `MERGE` |
| React automatically to changes         | `CREATE TRIGGER`                 |
| Grant or revoke permissions            | `GRANT` / `REVOKE`               |
| Walk hierarchies or generate series    | `WITH RECURSIVE`                 |
| Check whether a query uses indexes     | `EXPLAIN`                        |
| Lock a row to modify it                | `SELECT ... FOR UPDATE`          |
