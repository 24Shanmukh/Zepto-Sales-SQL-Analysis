-- =============================================
-- File: 06_aggregation.sql
-- Purpose: Level 5 - COUNT, SUM, AVG, MIN, MAX, GROUP BY, HAVING
-- Business rule used in all analysis files:
--   Revenue = quantity x selling_price, counted for DELIVERED orders only
--   (cancelled and returned orders did not earn money)
-- =============================================

USE zepto_sales;

-- Q1: Orders by status
SELECT order_status, COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;
-- Result: Delivered 8,990 | Cancelled 506 | Returned 227

-- Q2: Overall delivery time statistics (delivered orders)
SELECT
    COUNT(*)                         AS delivered_orders,
    COUNT(delivery_time_mins)        AS orders_with_time,   -- COUNT(column) skips NULLs
    ROUND(AVG(delivery_time_mins),1) AS avg_delivery_mins,
    MIN(delivery_time_mins)          AS fastest_mins,
    MAX(delivery_time_mins)          AS slowest_mins
FROM orders
WHERE order_status = 'Delivered';
-- Result: average 12.6 minutes. COUNT(*) vs COUNT(column) shows the 96 missing values.

-- Q3: Orders and share by payment method
SELECT
    payment_method,
    COUNT(*) AS total_orders,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM orders), 1) AS pct_of_orders
FROM orders
GROUP BY payment_method
ORDER BY total_orders DESC;
-- Result: UPI 61.6% | Credit Card 12.0% | COD 11.1% | Debit Card 8.9% | Wallet 6.4%

-- Q4: Value of each order (one row per order) - first 10
SELECT
    order_id,
    COUNT(*)                         AS product_lines,
    SUM(quantity)                    AS units,
    ROUND(SUM(quantity * selling_price), 2) AS order_value
FROM order_items
GROUP BY order_id
ORDER BY order_id
LIMIT 10;

-- Q5: Units sold and revenue per product (all statuses) - top 10 by units
SELECT
    product_id,
    SUM(quantity)                             AS units_sold,
    ROUND(SUM(quantity * selling_price), 0)   AS gross_sales
FROM order_items
GROUP BY product_id
ORDER BY units_sold DESC
LIMIT 10;

-- Q6: Total discount given away (difference between MRP and selling price)
SELECT
    ROUND(SUM(quantity * mrp), 0)                   AS value_at_mrp,
    ROUND(SUM(quantity * selling_price), 0)         AS value_after_discount,
    ROUND(SUM(quantity * (mrp - selling_price)), 0) AS total_discount_given
FROM order_items;

-- Q7: Stores with more than 500 orders (HAVING filters groups, WHERE filters rows)
SELECT store_id, COUNT(*) AS total_orders
FROM orders
WHERE order_status = 'Delivered'
GROUP BY store_id
HAVING COUNT(*) > 500
ORDER BY total_orders DESC;

-- Q8: Products whose average discount is above 20%
SELECT
    product_id,
    ROUND(AVG(discount_percent), 1) AS avg_discount_pct,
    COUNT(*)                        AS times_sold
FROM order_items
GROUP BY product_id
HAVING AVG(discount_percent) > 20
ORDER BY avg_discount_pct DESC;
-- Result: mostly Personal Care and Home & Cleaning products

-- Q9: Average basket - product lines and units per order
SELECT
    ROUND(AVG(product_lines), 2) AS avg_lines_per_order,
    ROUND(AVG(units), 2)         AS avg_units_per_order
FROM (
    SELECT order_id, COUNT(*) AS product_lines, SUM(quantity) AS units
    FROM order_items
    GROUP BY order_id
) AS order_summary;
-- Result: 3.54 different products and 5.06 units per order

-- Q10: Customers by city (after cleaning)
SELECT city, COUNT(*) AS customers
FROM customers
GROUP BY city
ORDER BY customers DESC;
-- Result: Bengaluru 602 | Mumbai 481 | Delhi NCR 396 | Hyderabad 232 | Pune 157 | Chennai 132
