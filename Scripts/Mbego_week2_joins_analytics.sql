-- Q 1.1: Customer Value by Demographic
SELECT 
    u.gender,
    CASE 
        WHEN u.age < 25 THEN '18-24'
        WHEN u.age BETWEEN 25 AND 34 THEN '25-34'
        WHEN u.age BETWEEN 35 AND 44 THEN '35-44'
        WHEN u.age >= 45 THEN '45+'
    END as age_group,
    COUNT(DISTINCT o.user_id) as total_customers,
    COUNT(DISTINCT o.order_id) as total_orders,
    ROUND(SUM(oi.sale_price), 2) as total_revenue,
    ROUND(SUM(oi.sale_price) / COUNT(DISTINCT o.user_id), 2) as avg_customer_value
FROM users u
JOIN orders o ON u.id = o.user_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY u.gender, age_group
ORDER BY total_revenue DESC;

-- Q 1.2: Geographic Customer Value
SELECT 
    u.state,
    u.country,
    COUNT(DISTINCT o.user_id) as total_customers,
    ROUND(SUM(oi.sale_price), 2) as total_revenue,
    ROUND(SUM(oi.sale_price) / COUNT(DISTINCT o.user_id), 2) as avg_customer_value
FROM users u
JOIN orders o ON u.id = o.user_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY u.state, u.country
ORDER BY total_revenue DESC
LIMIT 15;

-- Q 2.1 Product Category Performance
SELECT 
    p.category,
    p.department,
    COUNT(DISTINCT oi.order_id) as total_orders,
    SUM(oi.sale_price) as total_revenue,
    COUNT(DISTINCT ii.id) as inventory_count,
    ROUND(SUM(oi.sale_price) / COUNT(DISTINCT ii.id), 2) as revenue_per_inventory_item
FROM products p
JOIN order_items oi ON p.id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN inventory_items ii ON p.id = ii.product_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY p.category, p.department
ORDER BY total_revenue DESC;

-- Q 2.2 Top Performing Products
SELECT 
    p.name,
    p.category,
    p.brand,
    COUNT(DISTINCT oi.order_id) as times_ordered,
    SUM(oi.sale_price) as total_revenue,
    ROUND(AVG(oi.sale_price), 2) as avg_sale_price
FROM products p
JOIN order_items oi ON p.id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY p.id, p.name, p.category, p.brand
HAVING times_ordered > 5
ORDER BY total_revenue DESC
LIMIT 20;


-- Q 3.1 Traffic Source Performance
SELECT 
    u.traffic_source,
    COUNT(DISTINCT o.user_id) as total_customers,
    COUNT(DISTINCT o.order_id) as total_orders,
    ROUND(SUM(oi.sale_price), 2) as total_revenue,
    ROUND(SUM(oi.sale_price) / COUNT(DISTINCT o.user_id), 2) as avg_customer_value
FROM users u
JOIN orders o ON u.id = o.user_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY u.traffic_source
ORDER BY total_revenue DESC;

-- Q 3.2: Regional Sales Performance
SELECT 
    dc.name as distribution_center,
    dc.latitude,
    dc.longitude,
    COUNT(DISTINCT o.order_id) as orders_fulfilled,
    ROUND(SUM(oi.sale_price), 2) as total_revenue,
    COUNT(DISTINCT p.id) as unique_products
FROM distribution_centers dc
JOIN products p ON dc.id = p.distribution_center_id
JOIN order_items oi ON p.id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY dc.id, dc.name, dc.latitude, dc.longitude
ORDER BY total_revenue DESC;

-- Query 4.1: Customer Engagement vs Purchasing
SELECT 
    engagement_level,
    COUNT(user_id) as customer_count,
    ROUND(AVG(order_count), 2) as avg_orders,
    ROUND(AVG(total_revenue), 2) as avg_revenue
FROM (
    SELECT 
        u.id as user_id,
        COUNT(DISTINCT e.id) as event_count,
        COUNT(DISTINCT o.order_id) as order_count,
        SUM(oi.sale_price) as total_revenue,
        CASE 
            WHEN COUNT(DISTINCT e.id) > 20 THEN 'High Engagement'
            WHEN COUNT(DISTINCT e.id) BETWEEN 6 AND 20 THEN 'Medium Engagement'
            ELSE 'Low Engagement'
        END as engagement_level
    FROM users u
    LEFT JOIN events e ON u.id = e.user_id
    LEFT JOIN orders o ON u.id = o.user_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY u.id
) user_engagement
GROUP BY engagement_level
ORDER BY avg_revenue DESC;

-- Query 4.2: Repeat Customer Analysis
SELECT 
    repeat_customer,
    COUNT(user_id) as customer_count,
    ROUND(AVG(total_revenue), 2) as avg_revenue,
    ROUND(AVG(order_count), 2) as avg_orders
FROM (
    SELECT 
        u.id as user_id,
        COUNT(DISTINCT o.order_id) as order_count,
        SUM(oi.sale_price) as total_revenue,
        CASE 
            WHEN COUNT(DISTINCT o.order_id) > 1 THEN 'Repeat Customer'
            ELSE 'One-Time Customer'
        END as repeat_customer
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('Cancelled', 'Returned') OR o.status IS NULL
    GROUP BY u.id
) customer_type
GROUP BY repeat_customer;

---------------------------------Time-Based Sales Analysis-------------------------------

-- Q 5.1 Monthly Sales Trends with YoY Growth
SELECT 
    sales_year,
    sales_month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY sales_year, sales_month) as prev_month_revenue,
    ROUND((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY sales_year, sales_month)) / 
          LAG(monthly_revenue) OVER (ORDER BY sales_year, sales_month) * 100, 2) as growth_rate
FROM (
    SELECT 
        strftime('%Y', o.created_at) as sales_year,
        strftime('%m', o.created_at) as sales_month,
        ROUND(SUM(oi.sale_price), 2) as monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('Cancelled', 'Returned')
    GROUP BY sales_year, sales_month
) monthly_sales
ORDER BY sales_year, sales_month;

-- Q 5.2 Day of Week Sales Patterns
SELECT 
    CASE strftime('%w', o.created_at)
        WHEN '0' THEN 'Sunday'
        WHEN '1' THEN 'Monday'
        WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday'
        WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'
        WHEN '6' THEN 'Saturday'
    END as day_of_week,
    COUNT(DISTINCT o.order_id) as total_orders,
    ROUND(SUM(oi.sale_price), 2) as total_revenue,
    ROUND(SUM(oi.sale_price) / COUNT(DISTINCT o.order_id), 2) as avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY day_of_week
ORDER BY total_revenue DESC;