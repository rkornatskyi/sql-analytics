
-- ========================================
-- Customer Lifetime Revenue
-- ========================================

SELECT
	c.id AS customer_id,
	CONCAT(c.first_name, " ", c.last_name) AS customer_name,
	COUNT(DISTINCT o.id) AS total_orders,
	MIN(o.order_date) AS first_order_date,
	MAX(o.order_date) AS last_order_date,
	SUM(oi.quantity * p.price) AS lifetime_revenue
FROM customers c
JOIN orders o ON o.customer_id = c.id
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON p.id = oi.product_id
GROUP BY c.id
ORDER BY lifetime_revenue DESC;

-- ========================================
-- Top 10 Customers by Average Order Value
-- ========================================

SELECT
	o.customer_id,
	COUNT(DISTINCT o.id) AS total_orders,
	SUM(oi.quantity * p.price) AS total_revenue,
	ROUND(
		SUM(oi.quantity * p.price) / COUNT(DISTINCT o.id),	
		2
	) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
GROUP BY o.customer_id
ORDER BY avg_order_value DESC
LIMIT 10;

-- ========================================
-- Repeat Customer Rate
-- ========================================

WITH customer_orders AS (
	SELECT
		customer_id,
		COUNT(*) AS order_count
	FROM orders
	GROUP BY customer_id
)

SELECT	
	SUM(CASE WHEN order_count = 1 THEN 1 ELSE 0 END) AS one_time_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
	ROUND (
		SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(*) * 100,
		2
	) AS repeat_customers
FROM customer_orders;

-- ========================================
-- Days Between First and Second Purchase
-- ========================================

WITH customer_purchase_date_rn AS (
	SELECT
		customer_id,
		order_date AS first_purchase_date,
		LEAD(order_date) OVER(PARTITION BY customer_id ORDER BY order_date) AS next_purchase_date,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date ) AS rn
	FROM orders
)

SELECT
	*,
	DATEDIFF(next_purchase_date, first_purchase_date) AS date_diff
FROM customer_purchase_date_rn
WHERE rn = 1
ORDER BY customer_id;
