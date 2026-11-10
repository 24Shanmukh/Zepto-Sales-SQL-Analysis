-- =============================================
-- File: 10_ctes.sql
-- Purpose: Level 9 - Common Table Expressions (WITH ... AS)
-- A CTE is a named temporary result you can use like a table in the next query.
-- =============================================

USE zepto_sales;

-- Q1: Customers who spend above average - Q8 from 09_subqueries.sql rewritten with a CTE
WITH customer_spend AS (
    SELECT o.customer_id, SUM(oi.quantity * oi.selling_price) AS total_spend
    FROM orders AS o
    JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY o.customer_id
)
SELECT customer_id, ROUND(total_spend, 0) AS total_spend
FROM customer_spend
WHERE total_spend > (SELECT AVG(total_spend) FROM customer_spend)
ORDER BY total_spend DESC;

-- Q2: Monthly KPIs - orders, revenue, average order value
WITH monthly AS (
    SELECT
        DATE_FORMAT(o.order_datetime, '%Y-%m')  AS sales_month,
        COUNT(DISTINCT o.order_id)              AS orders,
        SUM(oi.quantity * oi.selling_price)     AS revenue
    FROM orders AS o
    JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY sales_month
)
SELECT
    sales_month,
    orders,
    ROUND(revenue, 0)          AS revenue,
    ROUND(revenue / orders, 1) AS avg_order_value
FROM monthly
ORDER BY sales_month;
-- Result: revenue grew every month, Rs 5.35 lakh (Jan) -> Rs 8.76 lakh (Jun), +64%.
--         Order value stayed flat (~Rs 465-483), so growth came from MORE orders, not bigger baskets.

-- Q3: Customer segments by number of orders
WITH customer_orders AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id)          AS orders,
        SUM(oi.quantity * oi.selling_price) AS spend
    FROM orders AS o
    JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY o.customer_id
),
segmented AS (
    SELECT
        customer_id,
        spend,
        CASE
            WHEN orders = 1   THEN '1. One-time (1 order)'
            WHEN orders <= 5  THEN '2. Occasional (2-5)'
            WHEN orders <= 15 THEN '3. Regular (6-15)'
            ELSE                   '4. Loyal (16+)'
        END AS segment
    FROM customer_orders
)
SELECT
    segment,
    COUNT(*)            AS customers,
    ROUND(SUM(spend),0) AS revenue,
    ROUND(100 * SUM(spend) / (SELECT SUM(spend) FROM customer_orders), 1) AS revenue_share_pct
FROM segmented
GROUP BY segment
ORDER BY segment;
-- Result: only 66 Loyal customers (3.5% of buyers) bring 19.8% of revenue.
--         83% of buyers ordered more than once.

-- Q4: Repeat purchase rate
WITH customer_orders AS (
    SELECT customer_id, COUNT(*) AS orders
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
)
SELECT
    COUNT(*)                          AS buying_customers,
    SUM(orders > 1)                   AS repeat_customers,
    ROUND(100 * AVG(orders > 1), 1)   AS repeat_rate_pct,
    ROUND(AVG(orders), 1)             AS avg_orders_per_customer
FROM customer_orders;
-- Result: 82.9% repeat rate, 4.8 orders per customer over 6 months

-- Q5: Seasonality - units sold per month for summer categories vs the rest
WITH monthly_units AS (
    SELECT
        DATE_FORMAT(o.order_datetime, '%Y-%m') AS sales_month,
        c.category_name,
        SUM(oi.quantity) AS units
    FROM orders AS o
    JOIN order_items AS oi ON o.order_id    = oi.order_id
    JOIN products    AS p  ON oi.product_id = p.product_id
    JOIN categories  AS c  ON p.category_id = c.category_id
    WHERE o.order_status = 'Delivered'
    GROUP BY sales_month, c.category_name
)
SELECT
    sales_month,
    SUM(CASE WHEN category_name = 'Ice Creams & Frozen'  THEN units ELSE 0 END) AS ice_cream_units,
    SUM(CASE WHEN category_name = 'Cold Drinks & Juices' THEN units ELSE 0 END) AS cold_drink_units,
    SUM(CASE WHEN category_name NOT IN ('Ice Creams & Frozen', 'Cold Drinks & Juices')
             THEN units ELSE 0 END)                                         AS other_units
FROM monthly_units
GROUP BY sales_month
ORDER BY sales_month;
-- Result: ice cream units x3.6 and cold drinks x2.6 from Jan to May (summer),
--         while other categories grew ~1.3x in line with overall growth

-- Q6: City scorecard - combine two CTEs (sales + delivery)
WITH city_sales AS (
    SELECT s.city, SUM(oi.quantity * oi.selling_price) AS revenue, COUNT(DISTINCT o.order_id) AS orders
    FROM orders AS o
    JOIN dark_stores AS s  ON o.store_id = s.store_id
    JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY s.city
),
city_delivery AS (
    SELECT s.city, AVG(o.delivery_time_mins) AS avg_delivery_mins
    FROM orders AS o
    JOIN dark_stores AS s ON o.store_id = s.store_id
    WHERE o.order_status = 'Delivered'
    GROUP BY s.city
)
SELECT
    cs.city,
    cs.orders,
    ROUND(cs.revenue, 0)              AS revenue,
    ROUND(cd.avg_delivery_mins, 1)    AS avg_delivery_mins
FROM city_sales    AS cs
JOIN city_delivery AS cd ON cs.city = cd.city
ORDER BY revenue DESC;
