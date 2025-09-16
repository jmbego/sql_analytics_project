-- Week 1: Basic Queries for E-commerce Analytics
-- Date: September 2025
-- Database: SQLite (ecommerce.db)

-- 1. EXPLORATORY DATA ANALYSIS

-- 1.1 Checking table structures
SELECT name FROM sqlite_master WHERE type='table';

-- 1.2 Count records in each table
SELECT 'users' as table_name, COUNT(*) as record_count FROM users
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'events', COUNT(*) FROM events
UNION ALL SELECT 'inventory_items', COUNT(*) FROM inventory_items
UNION ALL SELECT 'distribution_centers', COUNT(*) FROM distribution_centers;

-- 2. Primary USER ANALYSIS

-- 2.1 Count users by gender
SELECT 
    gender,
    COUNT(*) as user_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM users), 2) as percentage
FROM users 
GROUP BY gender 
ORDER BY user_count DESC;

-- 2.2 User signups by month
SELECT 
    strftime('%Y-%m', created_at) as signup_month,
    COUNT(*) as new_users
FROM users 
GROUP BY signup_month 
ORDER BY signup_month;

-- 2.3 User age distribution
SELECT 
    CASE 
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        WHEN age >= 50 THEN '50+'
    END as age_group,
    COUNT(*) as user_count
FROM users 
GROUP BY age_group 
ORDER BY MIN(age);

-- 3. PRODUCT ANALYSIS

-- 3.1 Products by category
SELECT 
    category,
    COUNT(*) as product_count,
    ROUND(AVG(retail_price), 2) as avg_price
FROM products 
GROUP BY category 
ORDER BY product_count DESC;

-- 3.2 Most expensive products
SELECT 
    name,
    category,
    retail_price
FROM products 
ORDER BY retail_price DESC 
LIMIT 10;

-- 3.3 Price distribution by category
SELECT 
    category,
    MIN(retail_price) as min_price,
    MAX(retail_price) as max_price,
    ROUND(AVG(retail_price), 2) as avg_price
FROM products 
GROUP BY category 
ORDER BY avg_price DESC;

-- 4. ORDER ANALYSIS

-- 4.1 Order status distribution
SELECT 
    status,
    COUNT(*) as order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) as percentage
FROM orders 
GROUP BY status 
ORDER BY order_count DESC;

-- 4.2 Orders by month
SELECT 
    strftime('%Y-%m', created_at) as order_month,
    COUNT(*) as order_count
FROM orders 
GROUP BY order_month 
ORDER BY order_month;

-- 4.3 Average order value by status (debug error in this)
SELECT 
    status,
    COUNT(*) as order_count,
    ROUND(AVG(order_total), 2) as avg_order_value
FROM orders 
GROUP BY status 
ORDER BY avg_order_value DESC;

-- 5. INVENTORY ANALYSIS

-- 5.1 Inventory by product category
SELECT 
    p.category,
    COUNT(DISTINCT i.product_id) as unique_products,
    SUM(i.cost) as total_inventory_value
FROM inventory_items i
JOIN products p ON i.product_id = p.id
GROUP BY p.category
ORDER BY total_inventory_value DESC;

-- 5.2 Inventory distribution across centers
SELECT 
    d.name as distribution_center,
    COUNT(i.id) as inventory_items,
    SUM(i.cost) as total_value
FROM inventory_items i
JOIN distribution_centers d ON i.product_distribution_center_id = d.id
GROUP BY d.name
ORDER BY total_value DESC;

-- 6. BASIC SALES METRICS

-- 6.1 Total sales revenue (debug querie)
SELECT 
    ROUND(SUM(oi.sale_price), 2) as total_revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.id
WHERE o.status NOT IN ('Cancelled', 'Returned');

-- 6.2 Monthly revenue trend
SELECT 
    strftime('%Y-%m', o.created_at) as revenue_month,
    ROUND(SUM(oi.sale_price), 2) as monthly_revenue,
    COUNT(DISTINCT o.id) as order_count
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY revenue_month
ORDER BY revenue_month;

-- 7. USER ENGAGEMENT (EVENTS)

-- 7.1 Event types distribution
SELECT 
    event_type,
    COUNT(*) as event_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM events), 2) as percentage
FROM events 
GROUP BY event_type 
ORDER BY event_count DESC;

-- 7.2 Most active users
SELECT 
    u.id,
    u.first_name || ' ' || u.last_name as user_name,
    COUNT(e.id) as event_count
FROM events e
JOIN users u ON e.user_id = u.id
GROUP BY u.id, user_name
ORDER BY event_count DESC
LIMIT 5;

-- 8. DATA QUALITY CHECKS

-- 8.1 Check for missing values in key columns
SELECT 
    'users' as table_name,
    SUM(CASE WHEN first_name IS NULL OR first_name = '' THEN 1 ELSE 0 END) as missing_first_names,
    SUM(CASE WHEN email IS NULL OR email = '' THEN 1 ELSE 0 END) as missing_emails
FROM users
UNION ALL
SELECT 
    'products',
    SUM(CASE WHEN name IS NULL OR name = '' THEN 1 ELSE 0 END),
    SUM(CASE WHEN category IS NULL OR category = '' THEN 1 ELSE 0 END)
FROM products
UNION ALL
SELECT 
    'orders',
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN status IS NULL OR status = '' THEN 1 ELSE 0 END)
FROM orders;

-- 8.2 Check for duplicate users (same email)
SELECT 
    email,
    COUNT(*) as duplicate_count
FROM users
GROUP BY email
HAVING COUNT(*) > 1;

-- 9. SUMMARY STATISTICS

-- 9.1 Key business metrics
SELECT 
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM products) as total_products,
    (SELECT COUNT(*) FROM orders WHERE status NOT IN ('Cancelled', 'Returned')) as completed_orders,
    (SELECT ROUND(SUM(oi.sale_price), 2) 
     FROM order_items oi 
     JOIN orders o ON oi.order_id = o.id 
     WHERE o.status NOT IN ('Cancelled', 'Returned')) as total_revenue,
    (SELECT COUNT(*) FROM events) as total_events;

-- 10. SAVE RESULTS FOR LATER USE (Views for Week 2)

-- 10.1 Create view for monthly revenue
CREATE VIEW IF NOT EXISTS monthly_revenue AS
SELECT 
    strftime('%Y-%m', o.created_at) as revenue_month,
    ROUND(SUM(oi.sale_price), 2) as monthly_revenue,
    COUNT(DISTINCT o.id) as order_count
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY revenue_month;

-- 10.2 Create view for user demographics
CREATE VIEW IF NOT EXISTS user_demographics AS
SELECT 
    gender,
    CASE 
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        WHEN age >= 50 THEN '50+'
    END as age_group,
    COUNT(*) as user_count
FROM users 
GROUP BY gender, age_group;
