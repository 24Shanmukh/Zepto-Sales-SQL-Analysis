-- =============================================
-- File: 03_basics.sql
-- Purpose: Level 2 - SELECT, WHERE, ORDER BY, LIMIT, DISTINCT
-- =============================================

USE zepto_sales;

-- Q1: Show all categories
SELECT *
FROM categories;

-- Q2: Show all Amul products with their MRP
SELECT product_name, mrp
FROM products
WHERE brand = 'Amul';
-- Before cleaning this returns 5 rows - 2 Amul products have a missing brand (see 04 and 05)

-- Q3: Show the 10 cheapest products
SELECT product_name, mrp
FROM products
ORDER BY mrp ASC
LIMIT 10;

-- Q4: List all distinct order statuses
SELECT DISTINCT order_status
FROM orders;

-- Q5: Orders that took more than 20 minutes to deliver, slowest first
SELECT order_id, order_datetime, delivery_time_mins
FROM orders
WHERE delivery_time_mins > 20
ORDER BY delivery_time_mins DESC;
-- Result: 101 orders (~1%), mostly during the 8-10 AM and 7-9 PM peaks

-- Q6: Britannia products, highest MRP first
SELECT product_name, brand, mrp
FROM products
WHERE brand = 'Britannia'
ORDER BY mrp DESC;

-- Q7: Distinct cities with dark stores
SELECT DISTINCT city
FROM dark_stores;
