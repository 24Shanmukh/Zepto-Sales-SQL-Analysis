-- =============================================
-- File: 05_cleaning.sql
-- Purpose: Level 4 - Find and fix data quality problems
--          UPDATE, DELETE, ALTER TABLE, TRIM, duplicates
-- Run this file ONCE, top to bottom, before the analysis files.
-- =============================================

USE zepto_sales;

-- MySQL Workbench blocks UPDATE/DELETE without a key in WHERE ("safe update mode").
-- Turn it off for this session; it is switched back on at the end of the file.
SET SQL_SAFE_UPDATES = 0;


-- =============================================
-- PROBLEM 1: Inconsistent city names in customers
-- =============================================

-- Q1: See every spelling exactly as stored (BINARY makes the comparison case-sensitive)
SELECT BINARY city AS city_as_stored, COUNT(*) AS customers
FROM customers
GROUP BY BINARY city
ORDER BY city_as_stored;
-- Found: 16 spellings for 6 cities, e.g. 'Bangalore', 'bengaluru', 'BENGALURU ' (trailing space),
--        'Bombay', 'Delhi', 'delhi ncr', 'PUNE'

-- Fix 1a: remove leading/trailing spaces
UPDATE customers
SET city = TRIM(city);

-- Fix 1b: map old names to the standard names used in dark_stores
UPDATE customers SET city = 'Bengaluru' WHERE city IN ('Bangalore', 'bengaluru', 'BENGALURU');
UPDATE customers SET city = 'Mumbai'    WHERE city IN ('Bombay', 'mumbai');
UPDATE customers SET city = 'Delhi NCR' WHERE city IN ('Delhi', 'delhi ncr');
UPDATE customers SET city = 'Hyderabad' WHERE city = 'hyderabad';
UPDATE customers SET city = 'Pune'      WHERE city = 'PUNE';
UPDATE customers SET city = 'Chennai'   WHERE city = 'chennai';

-- Check: should now show exactly 6 cities
SELECT BINARY city AS city, COUNT(*) AS customers
FROM customers
GROUP BY BINARY city
ORDER BY customers DESC;


-- =============================================
-- PROBLEM 2: Duplicate customers
-- =============================================

-- Q2: Find customer_ids that appear more than once
SELECT customer_id, COUNT(*) AS times_repeated
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;
-- Found: 8 customers stored twice (identical rows)

-- Fix: rebuild the table with only distinct rows, then add a primary key
CREATE TABLE customers_clean AS
SELECT DISTINCT *
FROM customers;

DROP TABLE customers;
RENAME TABLE customers_clean TO customers;
ALTER TABLE customers ADD PRIMARY KEY (customer_id);

-- Check: 2,000 customers, no duplicates
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT customer_id) AS unique_customers
FROM customers;


-- =============================================
-- PROBLEM 3: Products with a missing brand
-- =============================================

-- Q3: Find them
SELECT product_id, product_name, brand
FROM products
WHERE brand IS NULL;
-- Found: 3 products. The brand is clear from the product name.

-- Fix: fill the brand from the product name
UPDATE products SET brand = 'Amul'     WHERE brand IS NULL AND product_name LIKE 'Amul%';
UPDATE products SET brand = 'Too Yumm' WHERE brand IS NULL AND product_name LIKE 'Too Yumm%';

-- Check: should return 0 rows
SELECT * FROM products WHERE brand IS NULL;


-- =============================================
-- PROBLEM 4: Duplicate order lines in order_items
-- =============================================

-- Q4: The same product appearing twice in the same order
SELECT order_id, product_id, COUNT(*) AS times_repeated
FROM order_items
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;
-- Found: 15 duplicated lines (same order, product, quantity and price - only order_item_id differs)

-- Fix: keep the first copy (lowest order_item_id), delete the later copy
DELETE oi_later
FROM order_items AS oi_later
JOIN order_items AS oi_first
  ON  oi_later.order_id      = oi_first.order_id
  AND oi_later.product_id    = oi_first.product_id
  AND oi_later.order_item_id > oi_first.order_item_id;

-- Check: should return 0 rows
SELECT order_id, product_id, COUNT(*)
FROM order_items
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;


-- =============================================
-- PROBLEM 5: Invalid quantities (zero or negative)
-- =============================================

-- Q5: Find them
SELECT *
FROM order_items
WHERE quantity <= 0;
-- Found: 6 lines with quantity 0 or -1 - impossible for a sale, so they are data-entry errors

-- Fix: delete them
DELETE FROM order_items
WHERE quantity <= 0;


-- =============================================
-- PROBLEM 6: Missing delivery times (investigate, do NOT delete)
-- =============================================

-- Q6: Missing delivery time split by order status
SELECT order_status, COUNT(*) AS orders_missing_time
FROM orders
WHERE delivery_time_mins IS NULL
GROUP BY order_status;
-- Found: 506 cancelled + 96 delivered orders have no delivery time.
-- Cancelled orders were never delivered, so a blank is correct.
-- The 96 delivered orders (~1%) are genuinely missing the value.
-- Decision: keep these orders. They still count for revenue; AVG() ignores NULLs automatically.


-- =============================================
-- PROBLEM 7: Missing customer contact details (document only)
-- =============================================

-- Q7: How many customers have no email / phone?
SELECT
    SUM(email IS NULL) AS missing_email,
    SUM(phone IS NULL) AS missing_phone
FROM customers;
-- Not needed for sales analysis, so no fix - noted as a data limitation.


-- =============================================
-- FINAL CHECK: row counts after cleaning
-- =============================================
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'products',    COUNT(*) FROM products
UNION ALL SELECT 'orders',      COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items;
-- Expected: customers 2,000 | products 106 | orders 9,723 | order_items 34,423

SET SQL_SAFE_UPDATES = 1;
