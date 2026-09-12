
-- ========================================
--  Monthly order performance + MoM growth
-- ========================================

WITH monthly_order_metrics AS (
	SELECT
		DATE_FORMAT(o.order_date, "%Y-%m-01") AS order_period,
		COUNT(DISTINCT o.id) AS orders,
		SUM(oi.quantity) AS units_sold,
		SUM(p.price * oi.quantity) AS revenue
	FROM orders o
	JOIN order_items oi ON o.id = oi.order_id
	JOIN products p ON oi.product_id = p.id
	GROUP BY DATE_FORMAT(o.order_date, "%Y-%m-01")
),
monthly_comparison AS (
    SELECT
        *,
        LAG(orders) OVER (ORDER BY order_period) AS prev_month_orders,
        LAG(revenue) OVER (ORDER BY order_period) AS prev_month_revenue
    FROM monthly_order_metrics
)

SELECT
    order_period,
    orders,
    units_sold,
    revenue,
    prev_month_orders,
    prev_month_revenue,
    ROUND(
        (orders - prev_month_orders)
        / NULLIF(prev_month_orders, 0) * 100,
        2
    ) AS mom_order_growth,
    ROUND(
        (revenue - prev_month_revenue)
        / NULLIF(prev_month_revenue, 0) * 100,
        2
    ) AS mom_revenue_growth,
    ROUND(
        revenue / NULLIF(orders, 0),
        2
    ) AS avg_order_value

FROM monthly_comparison
ORDER BY order_period;
	
-- ========================================
-- Order value segmentation
-- ========================================

WITH product_metrics AS (
	SELECT
		p.id AS product_id,
		p.name AS product_name,
		SUM(oi.quantity) AS units_sold,
		COUNT(DISTINCT oi.order_id) AS total_orders,
		SUM(p.price * oi.quantity) AS revenue
	FROM products p
	JOIN order_items oi ON p.id = oi.product_id
	GROUP BY p.id, p.name
),
total_revenue AS (
	SELECT
		SUM(revenue) AS total
	FROM product_metrics
),
revenue_share AS (
	SELECT
		pm.*,
		ROUND(
			pm.revenue / tr.total * 100,
			2
		) AS revenue_share
	FROM product_metrics pm
	CROSS JOIN total_revenue tr
),
product_segmentation AS (
	SELECT 
		*,
		NTILE(3) OVER(ORDER BY revenue ASC) AS rev_segment
	FROM revenue_share
)

SELECT
	*,
	CASE
		WHEN rev_segment = 1 THEN 'Low'
		WHEN rev_segment = 2 THEN 'Medium'
		WHEN rev_segment = 3 THEN 'High'
	END AS segment
FROM product_segmentation
ORDER BY revenue DESC;

-- ========================================
-- Patero analysis for customers
-- ========================================

WITH customer_metrics AS (
	SELECT
		c.id AS customer_id,
		CONCAT(c.first_name, ' ', c.last_name) AS customer,
		SUM(p.price * oi.quantity) AS revenue
	FROM order_items oi 
	JOIN orders o ON oi.order_id = o.id
	JOIN customers c ON o.customer_id = c.id
	JOIN products p ON oi.product_id = p.id
	GROUP BY c.id
),
pareto_metrics AS (
	SELECT
		*,
		SUM(revenue) OVER(ORDER BY revenue DESC) AS cumulative_revenue,
		SUM(revenue) OVER () AS total_revenue
	FROM customer_metrics
)

SELECT
	*,
	ROUND(
        cumulative_revenue / NULLIF(total_revenue, 0) * 100,
        2
    ) AS cumulative_revenue_share,
    CASE
        WHEN cumulative_revenue / NULLIF(total_revenue, 0) <= 0.80
            THEN 'Top 80% revenue'
        ELSE 'Remaining 20% revenue'
    END AS pareto_segment
FROM pareto_metrics 
ORDER BY revenue DESC;

