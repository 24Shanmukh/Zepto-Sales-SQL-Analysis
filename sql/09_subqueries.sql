-- =============================================
-- File: 09_subqueries.sql
-- Purpose: Level 8 - Subqueries in WHERE, FROM and SELECT; correlated subqueries
-- =============================================

USE zepto_sales;

-- Q1: Products priced above the average MRP (subquery in WHERE)
SELECT product_name, mrp
FROM products
WHERE mrp > (SELECT AVG(mrp) FROM products)
ORDER BY mrp DESC;
-- The inner query runs first and returns one number (the average MRP)

-- Q2: Products priced above THEIR OWN category's average (correlated subquery)
SELECT
    p.product_name,
    p.category_id,
    p.mrp
FROM products AS p
WHERE p.mrp > (
    SELECT AVG(p2.mrp)
    FROM products AS p2
    WHERE p2.category_id = p.category_id   -- links the inner query to the outer row
)
ORDER BY p.category_id, p.mrp DESC;

-- Q3: Category share of revenue (subquery in SELECT)
SELECT
    c.category_name,
    ROUND(SUM(oi.quantity * oi.selling_price), 0) AS revenue,
    ROUND(100 * SUM(oi.quantity * oi.selling_price) / (
        SELECT SUM(oi2.quantity * oi2.selling_price)
        FROM order_items AS oi2
        JOIN orders AS o2 ON oi2.order_id = o2.order_id
        WHERE o2.order_status = 'Delivered'
    ), 1) AS revenue_share_pct
FROM orders AS o
JOIN order_items AS oi ON o.order_id    = oi.order_id
JOIN products    AS p  ON oi.product_id = p.product_id
JOIN categories  AS c  ON p.category_id = c.category_id
WHERE o.order_status = 'Delivered'
GROUP BY c.category_name
ORDER BY revenue_share_pct DESC;

-- Q4: Orders worth more than the average order value (subquery in FROM)
SELECT COUNT(*) AS orders_above_average
FROM (
    SELECT order_id, SUM(quantity * selling_price) AS order_value
    FROM order_items
    GROUP BY order_id
) AS order_totals
WHERE order_value > (
    SELECT AVG(order_value)
    FROM (
        SELECT SUM(quantity * selling_price) AS order_value
        FROM order_items
        GROUP BY order_id
    ) AS t
);

-- Q5: Share of orders that qualify for free delivery (order value >= Rs 199)
SELECT
    ROUND(100 * AVG(order_value >= 199), 1)                       AS pct_free_delivery,
    ROUND(100 * AVG(order_value >= 150 AND order_value < 199), 1) AS pct_just_below_199
FROM (
    SELECT order_id, SUM(quantity * selling_price) AS order_value
    FROM order_items
    GROUP BY order_id
) AS order_totals;
-- Result: 73.7% of orders qualify; 7.4% are Rs 150-198 - one more item would make them free

-- Q6: Customers who placed at least one order worth over Rs 1,500 (IN subquery)
SELECT customer_id, customer_name, city
FROM customers
WHERE customer_id IN (
    SELECT o.customer_id
    FROM orders AS o
    JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY o.order_id, o.customer_id
    HAVING SUM(oi.quantity * oi.selling_price) > 1500
);

-- Q7: Products that were NEVER returned in a returned order (NOT IN subquery)
SELECT product_name
FROM products
WHERE product_id NOT IN (
    SELECT oi.product_id
    FROM order_items AS oi
    JOIN orders AS o ON oi.order_id = o.order_id
    WHERE o.order_status = 'Returned'
);

-- Q8: Customers whose total spend is above the average customer spend
SELECT customer_id, ROUND(total_spend, 0) AS total_spend
FROM (
    SELECT o.customer_id, SUM(oi.quantity * oi.selling_price) AS total_spend
    FROM orders AS o
    JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY o.customer_id
) AS customer_spend
WHERE total_spend > (
    SELECT AVG(total_spend)
    FROM (
        SELECT SUM(oi.quantity * oi.selling_price) AS total_spend
        FROM orders AS o
        JOIN order_items AS oi ON o.order_id = oi.order_id
        WHERE o.order_status = 'Delivered'
        GROUP BY o.customer_id
    ) AS t
)
ORDER BY total_spend DESC;
-- Notice how long Q8 gets - the same subquery is written twice. CTEs (next file) fix this.
