SELECT
    customer_id,
    COUNT(DISTINCT invoice_no) AS number_of_orders,
    SUM(quantity * unit_price) AS revenue
FROM retail.sales
WHERE customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY revenue DESC;
