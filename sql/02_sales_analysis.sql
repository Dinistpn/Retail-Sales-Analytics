SELECT
    SUM(quantity * unit_price) AS total_revenue
FROM retail.sales;

-- Monthly revenue

SELECT
    DATE_TRUNC('month', invoice_date) AS month,
    SUM(quantity * unit_price) AS revenue
FROM retail.sales
GROUP BY 1
ORDER BY 1;

-- Revenue by country

SELECT
    country,
    SUM(quantity * unit_price) AS revenue
FROM retail.sales
GROUP BY country
ORDER BY revenue DESC;
