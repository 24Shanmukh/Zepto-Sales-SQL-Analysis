-- =============================================
-- File: 08_joins.sql
-- Purpose: Level 7 - INNER JOIN, LEFT JOIN, joining 3-5 tables
-- Revenue = quantity x selling_price on DELIVERED orders
-- Gross profit = quantity x (selling_price - cost_price)
-- =============================================

USE zepto_sales;

-- Q1: Product name and category for each product (2-table INNER JOIN)
SELECT
    p.product_id,
    p.product_name,
    c.category_name,
    p.mrp
FROM products AS p
INNER JOIN categories AS c
    ON p.category_id = c.category_id
ORDER BY c.category_name, p.mrp DESC;

-- Q2: Headline KPIs for the whole business (3-table JOIN)
SELECT
    COUNT(DISTINCT o.order_id)                                   AS delivered_orders,
    COUNT(DISTINCT o.customer_id)                                AS active_customers,
    SUM(oi.quantity)                                             AS units_sold,
    ROUND(SUM(oi.quantity * oi.selling_price), 0)                AS revenue,
    ROUND(SUM(oi.quantity * (oi.selling_price - p.cost_price)), 0) AS gross_profit,
    ROUND(100 * SUM(oi.quantity * (oi.selling_price - p.cost_price))
              / SUM(oi.quantity * oi.selling_price), 1)          AS gross_margin_pct,
    ROUND(SUM(oi.quantity * oi.selling_price) / COUNT(DISTINCT o.order_id), 1) AS avg_order_value
FROM orders AS o
JOIN order_items AS oi ON o.order_id    = oi.order_id
JOIN products    AS p  ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered';
-- Result: 8,990 orders | 1,869 customers | 45,319 units | Rs 42.76 lakh revenue
--         Rs 8.69 lakh gross profit | 20.3% margin | Rs 475.7 average order value

-- Q3: Revenue, profit and margin by category (4-table JOIN)
SELECT
    c.category_name,
    SUM(oi.quantity)                                               AS units_sold,
    ROUND(SUM(oi.quantity * oi.selling_price), 0)                  AS revenue,
    ROUND(SUM(oi.quantity * (oi.selling_price - p.cost_price)), 0) AS gross_profit,
    ROUND(100 * SUM(oi.quantity * (oi.selling_price - p.cost_price))
              / SUM(oi.quantity * oi.selling_price), 1)            AS margin_pct
FROM orders AS o
JOIN order_items AS oi ON o.order_id     = oi.order_id
JOIN products    AS p  ON oi.product_id  = p.product_id
JOIN categories  AS c  ON p.category_id  = c.category_id
WHERE o.order_status = 'Delivered'
GROUP BY c.category_name
ORDER BY revenue DESC;
-- Result: top revenue = Fruits & Vegetables, Atta Rice & Dal, Dairy Bread & Eggs (~13% each)
--         but Atta Rice & Dal earns only 9.4% margin; Personal Care earns 32.8%

-- Q4: Top 10 products by revenue
SELECT
    p.product_name,
    c.category_name,
    SUM(oi.quantity)                              AS units_sold,
    ROUND(SUM(oi.quantity * oi.selling_price), 0) AS revenue
FROM orders AS o
JOIN order_items AS oi ON o.order_id    = oi.order_id
JOIN products    AS p  ON oi.product_id = p.product_id
JOIN categories  AS c  ON p.category_id = c.category_id
WHERE o.order_status = 'Delivered'
GROUP BY p.product_name, c.category_name
ORDER BY revenue DESC
LIMIT 10;
-- Result: #1 Mango Alphonso 6 pcs (Rs 2.78 lakh) - high price x steady demand

-- Q5: Bottom 5 products by revenue
SELECT
    p.product_name,
    SUM(oi.quantity)                              AS units_sold,
    ROUND(SUM(oi.quantity * oi.selling_price), 0) AS revenue
FROM orders AS o
JOIN order_items AS oi ON o.order_id    = oi.order_id
JOIN products    AS p  ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.product_name
ORDER BY revenue ASC
LIMIT 5;
-- Result: Green Chilli, Gillette Guard, Tata Salt, Coriander, Lay's - cheap basket add-ons
--         (they sell many units, so low revenue does not mean they should be removed)

-- Q6: City performance - orders, revenue, revenue per store
SELECT
    s.city,
    COUNT(DISTINCT s.store_id)                    AS stores,
    COUNT(DISTINCT o.order_id)                    AS delivered_orders,
    ROUND(SUM(oi.quantity * oi.selling_price), 0) AS revenue,
    ROUND(SUM(oi.quantity * oi.selling_price) / COUNT(DISTINCT s.store_id), 0) AS revenue_per_store
FROM orders AS o
JOIN dark_stores AS s  ON o.store_id = s.store_id
JOIN order_items AS oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY s.city
ORDER BY revenue DESC;
-- Result: Bengaluru leads (30% of revenue). Chennai stores earn ~Rs 93k each vs ~Rs 258k in Bengaluru.

-- Q7: Delivery speed by city
SELECT
    s.city,
    ROUND(AVG(o.delivery_time_mins), 1)                     AS avg_delivery_mins,
    ROUND(100 * AVG(o.delivery_time_mins <= 10), 1)         AS pct_within_10_mins
FROM orders AS o
JOIN dark_stores AS s ON o.store_id = s.store_id
WHERE o.order_status = 'Delivered'
GROUP BY s.city
ORDER BY avg_delivery_mins;
-- Result: Mumbai (13.7) and Delhi NCR (13.6) are ~2 minutes slower than other cities,
--         and only ~17% of their orders arrive within 10 minutes (vs 34-38% elsewhere)

-- Q8: Customers who signed up but never placed an order (LEFT JOIN + IS NULL)
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    c.signup_date
FROM customers AS c
LEFT JOIN orders AS o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.signup_date DESC;
-- Result: 109 customers never ordered -> a re-activation target list

-- Q9: Count of never-ordered customers by city
SELECT
    c.city,
    COUNT(*) AS never_ordered
FROM customers AS c
LEFT JOIN orders AS o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
GROUP BY c.city
ORDER BY never_ordered DESC;

-- Q10: Top 5 customers by spend (with name and city)
SELECT
    c.customer_name,
    c.city,
    COUNT(DISTINCT o.order_id)                    AS orders,
    ROUND(SUM(oi.quantity * oi.selling_price), 0) AS total_spend
FROM customers AS c
JOIN orders      AS o  ON c.customer_id = o.customer_id
JOIN order_items AS oi ON o.order_id    = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY total_spend DESC
LIMIT 5;

-- Q11: Revenue lost to cancellations and returns
SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id)                    AS orders,
    ROUND(SUM(oi.quantity * oi.selling_price), 0) AS order_value
FROM orders AS o
JOIN order_items AS oi ON o.order_id = oi.order_id
GROUP BY o.order_status
ORDER BY order_value DESC;
-- Result: Rs 2.62 lakh cancelled + Rs 1.06 lakh returned = Rs 3.68 lakh (~7.9% of order value) lost
