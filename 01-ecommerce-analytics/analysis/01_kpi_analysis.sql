USE sql_analytics;

-- ========================================
-- Overall Order Performance
-- ========================================

SELECT
	COUNT(DISTINCT o.id) AS total_orders,
	SUM(oi.quantity) AS units_sold,
	SUM(p.price * oi.quantity) AS total_revenue,
	ROUND(
		SUM(p.price * oi.quantity) / COUNT(DISTINCT o.id),
		2
	) AS avg_order_value
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON oi.product_id = p.id;

-- ========================================
-- New Customers by Month
-- ========================================

SELECT
	DATE_FORMAT(registration_date, '%Y-%m-01') AS registration_month,
	COUNT(id) AS new_customers
FROM customers
GROUP BY registration_month
ORDER BY registration_month;

-- ========================================
-- Average Revenue Per Category
-- ========================================

SELECT 
	c.name AS category,
	SUM(oi.quantity) AS units_sold,
	SUM(oi.quantity * p.price) AS total_revenue,
	ROUND(SUM(oi.quantity * p.price) / SUM(oi.quantity), 2) AS avg_revenue_per_unit
FROM order_items oi
JOIN products p ON oi.product_id = p.id
JOIN categories c ON p.category_id = c.id
GROUP BY c.id, c.name
ORDER BY total_revenue DESC;

-- ========================================
-- MOM Revenue Growth
-- ========================================

WITH month_revenue AS (
	SELECT
		SUM(oi.quantity * p.price) AS revenue,
		YEAR(o.order_date) AS order_year,
		MONTH(o.order_date) AS order_month
	FROM orders o
	JOIN order_items oi ON o.id = oi.order_id
	JOIN products p ON oi.product_id = p.id
	GROUP BY YEAR(o.order_date), MONTH(o.order_date)
),
revenue_comparison AS (
	SELECT
		revenue,
		order_year,
		order_month,
		LAG(revenue) OVER(PARTITION BY order_year ORDER BY order_month) AS previous_month_revenue
	FROM month_revenue
)

SELECT
	order_year,
	order_month,
	revenue,
	previous_month_revenue,
	ROUND(
			(revenue - previous_month_revenue) / NULLIF(previous_month_revenue, 0)  * 100 , 
			2
		) AS mom_revenue_growth
FROM revenue_comparison
ORDER BY order_year, order_month;

-- ========================================
-- Customer Revenue Contribution by Country
-- ========================================

WITH customers_metrics AS (
	SELECT
		c.id AS country_id,
		c.name AS country,
		cst.id AS customer_id,
		CONCAT(cst.last_name, ' ', cst.first_name) AS customer,
		COUNT(DISTINCT o.id) AS orders,
		SUM(p.price * oi.quantity) AS customer_revenue,
		ROUND(
			SUM(p.price * oi.quantity) / NULLIF(COUNT(DISTINCT o.id), 0),
			2
		) AS avg_order_value
	FROM customers cst
	JOIN countries c ON cst.country_id = c.id
	JOIN orders o ON o.customer_id = cst.id
	JOIN order_items oi ON o.id = oi.order_id
	JOIN products p ON oi.product_id = p.id
	GROUP BY c.id, c.name, cst.id
),
country_metrics AS (
	SELECT 
		*,
		SUM(customer_revenue) OVER (PARTITION BY country_id) AS country_revenue
	FROM customers_metrics
)

SELECT
	*,
	ROUND(
		customer_revenue / customer_revenue * 100,
		2
	) AS customer_revenue_share
FROM country_metrics 
ORDER BY country, customer_revenue_share DESC;

-- ========================================
-- TOP 10 Products By Revenue
-- ========================================

WITH product_metrics AS (
	SELECT
		p.id AS product_id,
		p.name AS product_name,
		SUM(oi.quantity) AS units_sold,
		COUNT(DISTINCT oi.order_id) AS total_orders,
		SUM(p.price * oi.quantity) AS product_revenue
	FROM order_items oi
	JOIN products p ON p.id = oi.product_id
	GROUP BY p.id, p.name
)

SELECT
	*,
	ROUND(
		product_revenue / SUM(product_revenue) OVER() * 100,
		2
	) AS product_share
FROM product_metrics
ORDER BY product_revenue
LIMIT 10;

-- ========================================
-- Product Revenue Rank Within Each Category
-- ========================================

WITH product_revenue AS (
	SELECT
		p.id AS product_id,
		p.name AS product_name,
		p.category_id,
		SUM(p.price * oi.quantity) AS revenue
	FROM order_items oi
	JOIN products p ON p.id = oi.product_id
	GROUP BY p.id, p.name, p.category_id
)

SELECT 
	c.name AS category_name,
	pr.product_name,
	pr.revenue,
	RANK() OVER (PARTITION BY c.id ORDER BY pr.revenue DESC) AS revenue_rank
FROM product_revenue pr
JOIN categories c ON pr.category_id = c.id
ORDER BY c.name, revenue_rank ASC;

-- ========================================
-- Cumulative Revenue by 3 Month
-- ========================================

WITH monthly_revenue AS (
	SELECT
		YEAR(o.order_date) AS order_year,
		MONTH(o.order_date) AS order_month,
		SUM(p.price * oi.quantity) AS revenue
	FROM order_items oi
	JOIN products p ON oi.product_id = p.id
	JOIN orders o ON oi.order_id = o.id
	GROUP BY YEAR(o.order_date), MONTH(o.order_date)
)

SELECT
	order_year,
	order_month,
	revenue,
	ROUND(
		AVG(revenue) OVER(
			ORDER BY order_year, order_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
		), 2
	) AS rolling_avg_revenue
FROM monthly_revenue
ORDER BY order_year, order_month;










