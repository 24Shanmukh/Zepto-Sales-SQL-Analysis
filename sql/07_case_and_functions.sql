-- =============================================
-- File: 07_case_and_functions.sql
-- Purpose: Level 6 - CASE WHEN, ROUND, CONCAT, UPPER, COALESCE, date functions
-- =============================================

USE zepto_sales;

-- Q1: Put every product into a price band (CASE = IF/ELSE inside SQL)
SELECT
    product_name,
    mrp,
    CASE
        WHEN mrp < 50  THEN 'Low (< Rs 50)'
        WHEN mrp < 150 THEN 'Medium (Rs 50-149)'
        ELSE                'Premium (Rs 150+)'
    END AS price_band
FROM products
ORDER BY mrp;

-- Q2: How many products fall in each price band
SELECT
    CASE
        WHEN mrp < 50  THEN 'Low (< Rs 50)'
        WHEN mrp < 150 THEN 'Medium (Rs 50-149)'
        ELSE                'Premium (Rs 150+)'
    END AS price_band,
    COUNT(*) AS products
FROM products
GROUP BY price_band
ORDER BY MIN(mrp);

-- Q3: Delivery speed bands for delivered orders
SELECT
    CASE
        WHEN delivery_time_mins IS NULL THEN 'Not recorded'
        WHEN delivery_time_mins <= 10   THEN '10 min or less'
        WHEN delivery_time_mins <= 15   THEN '11-15 min'
        WHEN delivery_time_mins <= 20   THEN '16-20 min'
        ELSE                                 'Over 20 min'
    END AS delivery_band,
    COUNT(*) AS orders,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM orders WHERE order_status = 'Delivered'), 1) AS pct_of_orders
FROM orders
WHERE order_status = 'Delivered'
GROUP BY delivery_band
ORDER BY MIN(COALESCE(delivery_time_mins, 999));

-- Q4: Count statuses side by side in one row (conditional aggregation)
SELECT
    COUNT(*)                                                AS total_orders,
    SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END) AS delivered,
    SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
    SUM(CASE WHEN order_status = 'Returned'  THEN 1 ELSE 0 END) AS returned,
    ROUND(100 * SUM(CASE WHEN order_status <> 'Delivered' THEN 1 ELSE 0 END) / COUNT(*), 1) AS failed_pct
FROM orders;
-- Result: 7.5% of orders were cancelled or returned

-- Q5: Text functions - store label and upper-case city
SELECT
    store_code,
    CONCAT(area, ', ', city) AS store_location,
    UPPER(city)              AS city_upper,
    LENGTH(area)             AS area_name_length
FROM dark_stores;

-- Q6: COALESCE - replace NULL with a readable value
SELECT
    customer_id,
    customer_name,
    COALESCE(email, 'Not provided') AS email,
    COALESCE(phone, 'Not provided') AS phone
FROM customers
WHERE email IS NULL OR phone IS NULL
LIMIT 10;

-- Q7: Date functions - break the order timestamp into parts
SELECT
    order_id,
    order_datetime,
    DATE(order_datetime)                AS order_date,
    MONTHNAME(order_datetime)           AS month_name,
    DAYNAME(order_datetime)             AS day_name,
    HOUR(order_datetime)                AS order_hour,
    DATE_FORMAT(order_datetime, '%Y-%m') AS order_month
FROM orders
LIMIT 10;

-- Q8: Orders per hour of day with a time-slot label
SELECT
    HOUR(order_datetime) AS order_hour,
    CASE
        WHEN HOUR(order_datetime) BETWEEN 6  AND 10 THEN 'Morning'
        WHEN HOUR(order_datetime) BETWEEN 11 AND 16 THEN 'Afternoon'
        WHEN HOUR(order_datetime) BETWEEN 17 AND 22 THEN 'Evening'
        ELSE 'Late night'
    END AS time_slot,
    COUNT(*) AS orders,
    ROUND(AVG(delivery_time_mins), 1) AS avg_delivery_mins
FROM orders
WHERE order_status = 'Delivered'
GROUP BY order_hour, time_slot
ORDER BY order_hour;
-- Result: two peaks - 8-9 AM and 7-9 PM (7 PM is the busiest hour with 901 orders).
--         Delivery time rises from ~11.5 to ~14.5 minutes in these peak hours.

-- Q9: Weekday vs weekend - average orders per day
SELECT
    CASE WHEN DAYOFWEEK(order_datetime) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(*)                                  AS orders,
    COUNT(DISTINCT DATE(order_datetime))      AS days,
    ROUND(COUNT(*) / COUNT(DISTINCT DATE(order_datetime)), 1) AS orders_per_day
FROM orders
GROUP BY day_type;
-- Result: weekend 63.4 orders/day vs weekday 49.8 -> ~27% busier on weekends

-- Q10: Discount bands - do bigger discounts make people buy more units?
SELECT
    CASE
        WHEN discount_percent = 0   THEN '0%'
        WHEN discount_percent <= 10 THEN '1-10%'
        WHEN discount_percent <= 20 THEN '11-20%'
        ELSE                             '21%+'
    END AS discount_band,
    COUNT(*)                 AS order_lines,
    ROUND(AVG(quantity), 2)  AS avg_units_per_line
FROM order_items
GROUP BY discount_band
ORDER BY MIN(discount_percent);
-- Result: about 1.43 units per line in every band -> deeper discounts do NOT increase quantity bought
