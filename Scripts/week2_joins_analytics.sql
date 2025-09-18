-- SAVE RESULTS FOR LATER USE (Views for Week 2)

-- Create view for monthly revenue
CREATE VIEW IF NOT EXISTS monthly_revenue AS
SELECT 
    strftime('%Y-%m', o.created_at) as revenue_month,
    ROUND(SUM(oi.sale_price), 2) as monthly_revenue,
    COUNT(DISTINCT o.id) as order_count
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY revenue_month;

-- Create view for user demographics
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