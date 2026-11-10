-- =============================================
-- File: 11_window_functions.sql
-- Purpose: Level 10 - RANK, DENSE_RANK, ROW_NUMBER, LAG, NTILE,
--          SUM() OVER, PARTITION BY, running totals
-- A window function calculates across related rows WITHOUT collapsing them like GROUP BY.
-- =============================================

USE zepto_sales;

-- Q1: Top 3 products in each category by revenue (RANK + PARTITION BY)
WITH product_revenue AS (
    SELECT
        c.category_name,
        p.product_name,
        SUM(oi.quantity * oi.selling_price) AS revenue
    FROM orders AS o
    JOIN order_items AS oi ON o.order_id    = oi.order_id
    JOIN products    AS p  ON oi.product_id = p.product_id
    JOIN categories  AS c  ON p.category_id = c.category_id
    WHERE o.order_status = 'Delivered'
    GROUP BY c.category_name, p.product_name
),
ranked AS (
    SELECT
        category_name,
        product_name,
        revenue,
        RANK() OVER (PARTITION BY category_name ORDER BY revenue DESC) AS rank_in_category
    FROM product_revenue
)
SELECT category_name, rank_in_category, product_name, ROUND(revenue, 0) AS revenue
FROM ranked
WHERE rank_in_category <= 3
ORDER BY category_name, rank_in_category;

-- Q2: Month-over-month revenue growth (LAG looks at the previous row)
WITH monthly AS (
    SELECT
        DATE_FORMAT(o.order_datetime, '%Y-%m') AS sales_month,
        SUM(oi.quantity * oi.selling_price)    AS revenue
    FROM orders AS o
    JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY sales_month
)
SELECT
    sales_month,
    ROUND(revenue, 0)                                    AS revenue,
    ROUND(LAG(revenue) OVER (ORDER BY sales_month), 0)   AS previous_month,
    ROUND(100 * (revenue - LAG(revenue) OVER (ORDER BY sales_month))
              / LAG(revenue) OVER (ORDER BY sales_month), 1) AS mom_growth_pct
FROM monthly
ORDER BY sales_month;
-- Result: growth every month: +11.3%, +15.9%, +7.3%, +13.4%, +4.3%

-- Q3: Running (cumulative) revenue through the half-year
WITH monthly AS (
    SELECT
        DATE_FORMAT(o.order_datetime, '%Y-%m') AS sales_month,
        SUM(oi.quantity * oi.selling_price)    AS revenue
    FROM orders AS o
    JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY sales_month
)
SELECT
    sales_month,
    ROUND(revenue, 0)                                   AS revenue,
    ROUND(SUM(revenue) OVER (ORDER BY sales_month), 0)  AS cumulative_revenue
FROM monthly
ORDER BY sales_month;

-- Q4: Each category's share of total revenue (SUM() OVER () = grand total on every row)
WITH category_revenue AS (
    SELECT c.category_name, SUM(oi.quantity * oi.selling_price) AS revenue
    FROM orders AS o
    JOIN order_items AS oi ON o.order_id    = oi.order_id
    JOIN products    AS p  ON oi.product_id = p.product_id
    JOIN categories  AS c  ON p.category_id = c.category_id
    WHERE o.order_status = 'Delivered'
    GROUP BY c.category_name
)
SELECT
    category_name,
    ROUND(revenue, 0)                                             AS revenue,
    ROUND(100 * revenue / SUM(revenue) OVER (), 1)                AS share_pct,
    ROUND(100 * SUM(revenue) OVER (ORDER BY revenue DESC)
              / SUM(revenue) OVER (), 1)                          AS cumulative_share_pct
FROM category_revenue
ORDER BY revenue DESC;
-- Result: top 4 categories = ~50% of revenue

-- Q5: Rank stores inside each city (DENSE_RANK + PARTITION BY)
WITH store_revenue AS (
    SELECT s.city, s.store_code, s.area, SUM(oi.quantity * oi.selling_price) AS revenue
    FROM orders AS o
    JOIN dark_stores AS s  ON o.store_id = s.store_id
    JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY s.city, s.store_code, s.area
)
SELECT
    city,
    DENSE_RANK() OVER (PARTITION BY city ORDER BY revenue DESC) AS rank_in_city,
    store_code,
    area,
    ROUND(revenue, 0) AS revenue,
    DENSE_RANK() OVER (ORDER BY revenue DESC) AS overall_rank
FROM store_revenue
ORDER BY city, rank_in_city;
-- Result: best store HSR Layout, Bengaluru (Rs 2.83 lakh); weakest are the 3 Chennai stores (~Rs 0.93 lakh)

-- Q6: Customer spend quintiles (NTILE splits rows into equal groups) - Pareto check
WITH customer_spend AS (
    SELECT o.customer_id, SUM(oi.quantity * oi.selling_price) AS spend
    FROM orders AS o
    JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY o.customer_id
),
quintiles AS (
    SELECT customer_id, spend, NTILE(5) OVER (ORDER BY spend DESC) AS spend_quintile
    FROM customer_spend
)
SELECT
    spend_quintile,
    COUNT(*)                                                     AS customers,
    ROUND(SUM(spend), 0)                                         AS revenue,
    ROUND(100 * SUM(spend) / (SELECT SUM(spend) FROM customer_spend), 1) AS revenue_share_pct
FROM quintiles
GROUP BY spend_quintile
ORDER BY spend_quintile;
-- Result: the top 20% of customers bring 54.5% of revenue; the bottom 20% only 2.8%

-- Q7: Each customer's first order (ROW_NUMBER)
WITH numbered AS (
    SELECT
        customer_id,
        order_id,
        order_datetime,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_datetime) AS order_number
    FROM orders
    WHERE order_status = 'Delivered'
)
SELECT customer_id, order_id AS first_order_id, order_datetime AS first_order_at
FROM numbered
WHERE order_number = 1
ORDER BY first_order_at
LIMIT 20;

-- Q8: Days between a customer's consecutive orders (LAG with PARTITION BY)
WITH gaps AS (
    SELECT
        customer_id,
        order_datetime,
        DATEDIFF(order_datetime,
                 LAG(order_datetime) OVER (PARTITION BY customer_id ORDER BY order_datetime)) AS days_since_last
    FROM orders
    WHERE order_status = 'Delivered'
)
SELECT
    ROUND(AVG(days_since_last), 1) AS avg_days_between_orders
FROM gaps
WHERE days_since_last IS NOT NULL;

-- Q9: 7-day moving average of daily orders (window frame)
WITH daily AS (
    SELECT DATE(order_datetime) AS order_date, COUNT(*) AS orders
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY order_date
)
SELECT
    order_date,
    orders,
    ROUND(AVG(orders) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 1) AS moving_avg_7d
FROM daily
ORDER BY order_date;
