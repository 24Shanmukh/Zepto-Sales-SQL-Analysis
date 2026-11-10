-- =============================================
-- File: 12_views_and_report.sql
-- Purpose: Level 11 - CREATE VIEW and final reporting queries
-- A view is a saved query that behaves like a table. Build once, reuse everywhere.
-- =============================================

USE zepto_sales;

-- View 1: one clean row per delivered order line, with every attribute attached
CREATE OR REPLACE VIEW vw_sales AS
SELECT
    o.order_id,
    o.order_datetime,
    DATE(o.order_datetime)                 AS order_date,
    DATE_FORMAT(o.order_datetime, '%Y-%m') AS sales_month,
    HOUR(o.order_datetime)                 AS order_hour,
    o.customer_id,
    o.payment_method,
    o.delivery_time_mins,
    s.store_code,
    s.city,
    s.area,
    p.product_id,
    p.product_name,
    p.brand,
    c.category_name,
    oi.quantity,
    oi.mrp,
    oi.discount_percent,
    oi.selling_price,
    p.cost_price,
    oi.quantity * oi.selling_price                  AS revenue,
    oi.quantity * (oi.selling_price - p.cost_price) AS gross_profit,
    oi.quantity * (oi.mrp - oi.selling_price)       AS discount_amount
FROM orders AS o
JOIN order_items AS oi ON o.order_id     = oi.order_id
JOIN products    AS p  ON oi.product_id  = p.product_id
JOIN categories  AS c  ON p.category_id  = c.category_id
JOIN dark_stores AS s  ON o.store_id     = s.store_id
WHERE o.order_status = 'Delivered';

-- Now complex questions become short:
SELECT category_name, ROUND(SUM(revenue), 0) AS revenue
FROM vw_sales
GROUP BY category_name
ORDER BY revenue DESC;

-- View 2: monthly KPI table
CREATE OR REPLACE VIEW vw_monthly_kpis AS
SELECT
    sales_month,
    COUNT(DISTINCT order_id)                       AS orders,
    COUNT(DISTINCT customer_id)                    AS active_customers,
    ROUND(SUM(revenue), 0)                         AS revenue,
    ROUND(SUM(gross_profit), 0)                    AS gross_profit,
    ROUND(100 * SUM(gross_profit) / SUM(revenue), 1) AS margin_pct,
    ROUND(SUM(revenue) / COUNT(DISTINCT order_id), 1) AS avg_order_value
FROM vw_sales
GROUP BY sales_month;

SELECT * FROM vw_monthly_kpis ORDER BY sales_month;

-- View 3: category performance table
CREATE OR REPLACE VIEW vw_category_performance AS
SELECT
    category_name,
    SUM(quantity)                                    AS units_sold,
    ROUND(SUM(revenue), 0)                           AS revenue,
    ROUND(SUM(gross_profit), 0)                      AS gross_profit,
    ROUND(100 * SUM(gross_profit) / SUM(revenue), 1) AS margin_pct,
    ROUND(AVG(discount_percent), 1)                  AS avg_discount_pct
FROM vw_sales
GROUP BY category_name;

SELECT * FROM vw_category_performance ORDER BY revenue DESC;

-- View 4: city performance table
CREATE OR REPLACE VIEW vw_city_performance AS
SELECT
    city,
    COUNT(DISTINCT store_code)                       AS stores,
    COUNT(DISTINCT order_id)                         AS orders,
    ROUND(SUM(revenue), 0)                           AS revenue,
    ROUND(SUM(revenue) / COUNT(DISTINCT store_code), 0) AS revenue_per_store
FROM vw_sales
GROUP BY city;

SELECT * FROM vw_city_performance ORDER BY revenue DESC;

-- =============================================
-- FINAL REPORT: one-row executive summary (Jan-Jun 2025)
-- =============================================
SELECT
    (SELECT COUNT(*) FROM orders)                                        AS total_orders_placed,
    COUNT(DISTINCT order_id)                                             AS delivered_orders,
    (SELECT ROUND(100 * AVG(order_status <> 'Delivered'), 1) FROM orders) AS failed_order_pct,
    COUNT(DISTINCT customer_id)                                          AS active_customers,
    SUM(quantity)                                                        AS units_sold,
    ROUND(SUM(revenue), 0)                                               AS revenue,
    ROUND(SUM(gross_profit), 0)                                          AS gross_profit,
    ROUND(100 * SUM(gross_profit) / SUM(revenue), 1)                     AS gross_margin_pct,
    ROUND(SUM(discount_amount), 0)                                       AS discounts_given,
    ROUND(SUM(revenue) / COUNT(DISTINCT order_id), 1)                    AS avg_order_value,
    ROUND(AVG(delivery_time_mins), 1)                                    AS avg_delivery_mins_per_line
FROM vw_sales;
-- Note: avg delivery here is weighted by order lines; use the orders table for a per-order average (12.6 min).

-- Check which views exist
SHOW FULL TABLES WHERE Table_type = 'VIEW';
