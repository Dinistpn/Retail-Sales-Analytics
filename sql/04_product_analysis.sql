--units sold
SELECT
    stock_code,
    description,
    SUM(quantity) AS units_sold
FROM retail.sales
GROUP BY
    stock_code,
    description
ORDER BY units_sold DESC
LIMIT 20;

--revenue
SELECT
    stock_code,
    description,
    SUM(quantity * unit_price) AS revenue
FROM retail.sales
GROUP BY
    stock_code,
    description
ORDER BY revenue DESC
LIMIT 20;
