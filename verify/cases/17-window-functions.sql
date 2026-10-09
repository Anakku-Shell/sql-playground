-- Section 17: window functions, with the data shown in the guide.
-- guide-sections: 17
CREATE TABLE orders (id INT PRIMARY KEY, customer_id INT, order_date DATE, amount INT);
INSERT INTO orders VALUES
    (10, 1, '2026-01-10', 50), (11, 1, '2026-02-15', 30), (12, 2, '2026-01-20', 80),
    (14, 2, '2026-03-05', 40), (15, 3, '2026-02-01', 60);

SELECT customer_id, SUM(amount) AS total FROM orders GROUP BY customer_id ORDER BY customer_id;

SELECT id, customer_id, amount,
       SUM(amount) OVER (PARTITION BY customer_id) AS customer_total
FROM orders ORDER BY id;

CREATE TABLE scores (points INT);
INSERT INTO scores VALUES (100), (90), (90), (80);
SELECT points,
       ROW_NUMBER() OVER (ORDER BY points DESC) AS row_num,
       RANK()       OVER (ORDER BY points DESC) AS rnk,
       DENSE_RANK() OVER (ORDER BY points DESC) AS dense_rnk
FROM scores
ORDER BY row_num;

WITH ranked AS (
    SELECT o.*,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY amount DESC) AS rn
    FROM orders o
)
SELECT id, customer_id, amount
FROM ranked
WHERE rn = 1
ORDER BY customer_id;

SELECT id, order_date, amount,
       SUM(amount) OVER (ORDER BY order_date) AS running_total
FROM orders ORDER BY order_date;

SELECT id, customer_id, order_date, amount,
       LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous,
       amount - LAG(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS difference
FROM orders ORDER BY customer_id, order_date;

SELECT id, ROUND(AVG(amount) OVER (ORDER BY order_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg
FROM orders ORDER BY order_date;

SELECT id, LAG(amount, 1, 0) OVER (ORDER BY id) AS lag_or_zero,
       FIRST_VALUE(amount) OVER (ORDER BY id) AS first_amount,
       NTILE(4) OVER (ORDER BY id) AS quartile
FROM orders ORDER BY id;
