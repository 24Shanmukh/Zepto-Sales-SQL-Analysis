-- =============================================
-- File: 02_explore.sql
-- Purpose: Level 1 - First look at the Zepto sales tables
-- =============================================

USE zepto_sales;

-- Q1: Preview order line items
SELECT *
FROM order_items
LIMIT 3;

-- Q2: Preview orders
SELECT *
FROM orders
LIMIT 3;

-- Q3: Preview products
SELECT *
FROM products
LIMIT 3;

-- Q4: Check the structure of the orders table
DESCRIBE orders;

-- Q5: Row count of every table
SELECT 'categories' AS table_name, COUNT(*) AS row_count FROM categories
UNION ALL SELECT 'products',    COUNT(*) FROM products
UNION ALL SELECT 'dark_stores', COUNT(*) FROM dark_stores
UNION ALL SELECT 'customers',   COUNT(*) FROM customers
UNION ALL SELECT 'orders',      COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items;
