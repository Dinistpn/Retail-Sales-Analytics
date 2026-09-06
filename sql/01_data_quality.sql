-- Total rows
SELECT COUNT(*) AS total_rows
FROM retail.sales;


-- Preview records
SELECT *
FROM retail.sales
LIMIT 10;


-- Missing customer IDs
SELECT COUNT(*) AS missing_customer_ids
FROM retail.sales
WHERE customer_id IS NULL;


-- Negative quantities
SELECT COUNT(*) AS negative_quantity_rows
FROM retail.sales
WHERE quantity < 0;
