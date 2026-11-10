-- =============================================
-- File: 04_filtering.sql
-- Purpose: Level 3 - AND, OR, IN, BETWEEN, LIKE, IS NULL, NOT
-- =============================================

USE zepto_sales;

-- Q1: How many UPI orders were cancelled? (AND = both conditions true)
SELECT COUNT(*) AS upi_cancelled_orders
FROM orders
WHERE payment_method = 'UPI'
  AND order_status = 'Cancelled';
-- Result: 332

-- Q2: How many orders were paid digitally (UPI or Wallet)? (OR = either condition true)
SELECT COUNT(*) AS digital_orders
FROM orders
WHERE payment_method = 'UPI'
   OR payment_method = 'Wallet';
-- Result: 6,607 of 9,723 orders (~68%)

-- Q3: Dark stores in Pune and Chennai (IN = shortcut for many ORs)
SELECT store_id, store_code, city, area
FROM dark_stores
WHERE city IN ('Pune', 'Chennai');
-- Result: 3 stores in each city - the two smallest markets

-- Q4: Products priced between Rs 100 and Rs 150 (BETWEEN includes both ends)
SELECT product_name, mrp
FROM products
WHERE mrp BETWEEN 100 AND 150
ORDER BY mrp;
-- Result: 15 products in the mid-price band

-- Q5: Orders placed in March 2025
-- Note: order_datetime has a time part, so the end date must include 23:59:59
SELECT COUNT(*) AS march_orders
FROM orders
WHERE order_datetime BETWEEN '2025-03-01 00:00:00' AND '2025-03-31 23:59:59';
-- Result: 1,569

-- Q6: All Amul products, including ones with a missing brand (LIKE = text pattern)
SELECT product_id, product_name, brand, mrp
FROM products
WHERE product_name LIKE 'Amul%';
-- Result: 7 products. WHERE brand = 'Amul' finds only 5, because 2 have brand = NULL

-- Q7: Products with a missing brand (IS NULL - never use = NULL)
SELECT product_id, product_name, brand
FROM products
WHERE brand IS NULL;
-- Result: 3 products -> fixed in 05_cleaning.sql

-- Q8: Delivered or returned orders with no delivery time recorded
SELECT COUNT(*) AS missing_delivery_time
FROM orders
WHERE delivery_time_mins IS NULL
  AND order_status <> 'Cancelled';
-- Result: 96 (cancelled orders have no delivery time by design, so they are excluded)

-- Q9: Orders that were NOT delivered (<> = not equal)
SELECT COUNT(*) AS not_delivered
FROM orders
WHERE order_status <> 'Delivered';
-- Result: 733 (~7.5% of all orders)

-- Q10: Mixing AND with OR - always use brackets
-- UPI orders that were cancelled OR returned
SELECT COUNT(*) AS upi_failed_orders
FROM orders
WHERE payment_method = 'UPI'
  AND (order_status = 'Cancelled' OR order_status = 'Returned');

-- Q11: Cash on Delivery orders that were returned
SELECT COUNT(*) AS cod_returned
FROM orders
WHERE payment_method = 'Cash on Delivery'
  AND order_status = 'Returned';

-- Q12: Dark stores in Bengaluru or Mumbai
SELECT store_code, city, area
FROM dark_stores
WHERE city IN ('Bengaluru', 'Mumbai')
ORDER BY city, area;

-- Q13: Customers with no email recorded
SELECT COUNT(*) AS customers_without_email
FROM customers
WHERE email IS NULL;

-- Q14: Delivered orders placed in January 2025
SELECT COUNT(*) AS jan_delivered
FROM orders
WHERE order_datetime BETWEEN '2025-01-01 00:00:00' AND '2025-01-31 23:59:59'
  AND order_status = 'Delivered';

-- Q15: Products that are NOT in the Rs 20 - Rs 200 range (NOT BETWEEN)
SELECT product_name, mrp
FROM products
WHERE mrp NOT BETWEEN 20 AND 200
ORDER BY mrp;
