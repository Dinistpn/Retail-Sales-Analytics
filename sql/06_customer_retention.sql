--Repeat customers
SELECT
    COUNT(*) AS customers
FROM (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS orders
    FROM retail.sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
) customer_orders
WHERE orders > 1;

--One-time customers
SELECT
    COUNT(*) AS one_time_customers
FROM (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS orders
    FROM retail.sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
) customer_orders
WHERE orders = 1;

--Repeat customer percentage
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS orders
    FROM retail.sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    COUNT(*) FILTER (WHERE orders > 1)
        * 100.0 / COUNT(*) AS repeat_customer_percentage
FROM customer_orders;

--Monthly customer revenue
SELECT
    DATE_TRUNC('month', invoice_date) AS month,
    customer_id,
    SUM(quantity * unit_price) AS revenue
FROM retail.sales
WHERE customer_id IS NOT NULL
GROUP BY
    DATE_TRUNC('month', invoice_date),
    customer_id
ORDER BY
    month,
    customer_id;

--Customer's current month comparation with their previous month
WITH monthly_customer_revenue AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', invoice_date) AS month,
        SUM(quantity * unit_price) AS revenue
    FROM retail.sales
    WHERE customer_id IS NOT NULL
    GROUP BY
        customer_id,
        DATE_TRUNC('month', invoice_date)
)
SELECT
    customer_id,
    month,
    revenue,
    LAG(revenue) OVER (
        PARTITION BY customer_id
        ORDER BY month
    ) AS previous_month_revenue
FROM monthly_customer_revenue
ORDER BY customer_id, month;

--Revenue change
WITH monthly_customer_revenue AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', invoice_date) AS month,
        SUM(quantity * unit_price) AS revenue
    FROM retail.sales
    WHERE customer_id IS NOT NULL
    GROUP BY
        customer_id,
        DATE_TRUNC('month', invoice_date)
),
customer_trends AS (
    SELECT
        customer_id,
        month,
        revenue,
        LAG(revenue) OVER (
            PARTITION BY customer_id
            ORDER BY month
        ) AS previous_month_revenue
    FROM monthly_customer_revenue
)
SELECT
    customer_id,
    month,
    revenue,
    previous_month_revenue,
    revenue - previous_month_revenue AS revenue_change
FROM customer_trends
ORDER BY customer_id, month;

