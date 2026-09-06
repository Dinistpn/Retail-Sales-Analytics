-- Find the latest transaction date
SELECT
    MAX(invoice_date) AS latest_transaction_date
FROM retail.sales;

--Calculate customer RFM metrics
SELECT
    customer_id,
    -- Recency
    MAX(invoice_date) AS last_purchase_date,
    -- Frequency
    COUNT(DISTINCT invoice_no) AS frequency,
    -- Monetary
    SUM(quantity * unit_price) AS monetary
FROM retail.sales
WHERE customer_id IS NOT NULL
GROUP BY customer_id;

--Calculate actual Recency

WITH customer_metrics AS (
    SELECT
        customer_id,
        MAX(invoice_date) AS last_purchase_date,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(quantity * unit_price) AS monetary
    FROM retail.sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),
reference_date AS (
    SELECT MAX(invoice_date) AS max_date
    FROM retail.sales
)
SELECT
    c.customer_id,
    r.max_date - c.last_purchase_date AS recency,
    c.frequency,
    c.monetary
FROM customer_metrics c
CROSS JOIN reference_date r;

--RFM scores
WITH customer_metrics AS (
    SELECT
        customer_id,
        MAX(invoice_date) AS last_purchase_date,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(quantity * unit_price) AS monetary
    FROM retail.sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),
reference_date AS (
    SELECT MAX(invoice_date) AS max_date
    FROM retail.sales
),
rfm AS (
    SELECT
        c.customer_id,
        r.max_date - c.last_purchase_date AS recency,
        c.frequency,
        c.monetary
    FROM customer_metrics c
    CROSS JOIN reference_date r
)
SELECT
    customer_id,
    recency,
    frequency,
    monetary,
    NTILE(5) OVER (
        ORDER BY recency DESC
    ) AS recency_score,
    NTILE(5) OVER (
        ORDER BY frequency
    ) AS frequency_score,
    NTILE(5) OVER (
        ORDER BY monetary
    ) AS monetary_score
FROM rfm;

--RFM score
WITH rfm_scores AS (
    WITH customer_metrics AS (
    SELECT
        customer_id,
        MAX(invoice_date) AS last_purchase_date,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(quantity * unit_price) AS monetary
    FROM retail.sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),
reference_date AS (
    SELECT MAX(invoice_date) AS max_date
    FROM retail.sales
),
rfm AS (
    SELECT
        c.customer_id,
        r.max_date - c.last_purchase_date AS recency,
        c.frequency,
        c.monetary
    FROM customer_metrics c
    CROSS JOIN reference_date r
)
SELECT
    customer_id,
    recency,
    frequency,
    monetary,
    NTILE(5) OVER (
        ORDER BY recency DESC
    ) AS recency_score,
    NTILE(5) OVER (
        ORDER BY frequency
    ) AS frequency_score,
    NTILE(5) OVER (
        ORDER BY monetary
    ) AS monetary_score
FROM rfm
)
SELECT
    customer_id,
    recency,
    frequency,
    monetary,
    recency_score,
    frequency_score,
    monetary_score,
    recency_score
        + frequency_score
        + monetary_score AS rfm_score,
		--customer segments
	CASE
	    WHEN rfm_score >= 13 THEN 'Champions'
	    WHEN rfm_score >= 10 THEN 'Loyal Customers'
	    WHEN rfm_score >= 7 THEN 'Potential Loyalists'
	    WHEN rfm_score >= 5 THEN 'At Risk'
	    ELSE 'Lost Customers'
	END AS customer_segment
FROM rfm_scores;


--Save the RFM results
CREATE TABLE retail.customer_rfm AS
WITH customer_metrics AS (
    SELECT
        customer_id,

        -- Recency: days since the customer's most recent purchase
        CURRENT_DATE - MAX(invoice_date::DATE) AS recency,

        -- Frequency: number of unique invoices
        COUNT(DISTINCT invoice_no) AS frequency,

        -- Monetary: total customer spending
        SUM(quantity * unit_price) AS monetary

    FROM retail.sales

    WHERE customer_id IS NOT NULL
      AND invoice_no IS NOT NULL
      AND invoice_date IS NOT NULL
      AND quantity > 0
      AND unit_price > 0

    GROUP BY customer_id
),

rfm_scores AS (
    SELECT
        customer_id,
        recency,
        frequency,
        monetary,

        -- Recency score: lower recency = better score
        NTILE(5) OVER (
            ORDER BY recency DESC
        ) AS r_score,

        -- Frequency score: higher frequency = better score
        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS f_score,

        -- Monetary score: higher spending = better score
        NTILE(5) OVER (
            ORDER BY monetary ASC
        ) AS m_score

    FROM customer_metrics
)

SELECT
    customer_id,
    recency,
    frequency,
    ROUND(monetary, 2) AS monetary,
    r_score,
    f_score,
    m_score,

    -- Combined RFM score
    CONCAT(r_score, f_score, m_score) AS rfm_score

FROM rfm_scores;

--Analyze customer segments
SELECT
    customer_segment,
    COUNT(*) AS customers,
    SUM(monetary) AS revenue,
    AVG(monetary) AS average_customer_value
FROM retail.customer_rfm
GROUP BY customer_segment
ORDER BY revenue DESC;

--Analyze customers by segment
SELECT
    customer_segment,
    AVG(recency) AS avg_recency,
    AVG(frequency) AS avg_frequency,
    AVG(monetary) AS avg_monetary
FROM retail.customer_rfm
GROUP BY customer_segment
ORDER BY avg_monetary DESC;




