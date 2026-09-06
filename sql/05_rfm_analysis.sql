-- 1. Find the latest transaction date
-- ============================================================

SELECT
    MAX(invoice_date) AS latest_transaction_date
FROM retail.sales;


-- ============================================================
-- 2. Calculate customer RFM metrics
-- ============================================================

SELECT
    customer_id,

    -- Last purchase date
    MAX(invoice_date) AS last_purchase_date,

    -- Frequency: number of unique invoices
    COUNT(DISTINCT invoice_no) AS frequency,

    -- Monetary: total amount spent
    SUM(quantity * unit_price) AS monetary

FROM retail.sales

WHERE customer_id IS NOT NULL
  AND invoice_no IS NOT NULL
  AND invoice_date IS NOT NULL
  AND quantity > 0
  AND unit_price > 0

GROUP BY customer_id
ORDER BY monetary DESC;


-- ============================================================
-- 3. Calculate actual Recency
-- ============================================================

WITH customer_metrics AS (
    SELECT
        customer_id,
        MAX(invoice_date::DATE) AS last_purchase_date,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(quantity * unit_price) AS monetary

    FROM retail.sales

    WHERE customer_id IS NOT NULL
      AND invoice_no IS NOT NULL
      AND invoice_date IS NOT NULL
      AND quantity > 0
      AND unit_price > 0

    GROUP BY customer_id
),

reference_date AS (
    SELECT
        MAX(invoice_date::DATE) AS max_date
    FROM retail.sales
)

SELECT
    c.customer_id,
    r.max_date - c.last_purchase_date AS recency,
    c.frequency,
    ROUND(c.monetary, 2) AS monetary

FROM customer_metrics c
CROSS JOIN reference_date r

ORDER BY recency;


-- ============================================================
-- 4. Calculate RFM scores
-- ============================================================

WITH customer_metrics AS (
    SELECT
        customer_id,
        MAX(invoice_date::DATE) AS last_purchase_date,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(quantity * unit_price) AS monetary

    FROM retail.sales

    WHERE customer_id IS NOT NULL
      AND invoice_no IS NOT NULL
      AND invoice_date IS NOT NULL
      AND quantity > 0
      AND unit_price > 0

    GROUP BY customer_id
),

reference_date AS (
    SELECT
        MAX(invoice_date::DATE) AS max_date
    FROM retail.sales
),

rfm AS (
    SELECT
        c.customer_id,

        -- Recency: fewer days = better
        r.max_date - c.last_purchase_date AS recency,

        -- Frequency: more purchases = better
        c.frequency,

        -- Monetary: higher spending = better
        c.monetary

    FROM customer_metrics c
    CROSS JOIN reference_date r
)

SELECT
    customer_id,
    recency,
    frequency,
    ROUND(monetary, 2) AS monetary,

    -- Recency: lower number of days gets higher score
    NTILE(5) OVER (
        ORDER BY recency DESC
    ) AS recency_score,

    -- Frequency: higher frequency gets higher score
    NTILE(5) OVER (
        ORDER BY frequency ASC
    ) AS frequency_score,

    -- Monetary: higher monetary value gets higher score
    NTILE(5) OVER (
        ORDER BY monetary ASC
    ) AS monetary_score

FROM rfm;


-- ============================================================
-- 5. Save the final RFM results
-- ============================================================

-- Remove the old table if it already exists
DROP TABLE IF EXISTS retail.customer_rfm;


CREATE TABLE retail.customer_rfm AS

WITH customer_metrics AS (
    SELECT
        customer_id,

        MAX(invoice_date::DATE) AS last_purchase_date,

        COUNT(DISTINCT invoice_no) AS frequency,

        SUM(quantity * unit_price) AS monetary

    FROM retail.sales

    WHERE customer_id IS NOT NULL
      AND invoice_no IS NOT NULL
      AND invoice_date IS NOT NULL
      AND quantity > 0
      AND unit_price > 0

    GROUP BY customer_id
),

reference_date AS (
    SELECT
        MAX(invoice_date::DATE) AS max_date
    FROM retail.sales
),

rfm AS (
    SELECT
        c.customer_id,

        -- Recency in days
        r.max_date - c.last_purchase_date AS recency,

        c.frequency,

        c.monetary

    FROM customer_metrics c
    CROSS JOIN reference_date r
),

rfm_scores AS (
    SELECT
        customer_id,
        recency,
        frequency,
        monetary,

        NTILE(5) OVER (
            ORDER BY recency DESC
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY monetary ASC
        ) AS monetary_score

    FROM rfm
)

SELECT
    customer_id,
    recency,
    frequency,
    ROUND(monetary, 2) AS monetary,

    recency_score,
    frequency_score,
    monetary_score,

    -- Total RFM score: 3 to 15
    recency_score
        + frequency_score
        + monetary_score AS rfm_score,

    -- Customer segmentation
    CASE
        WHEN recency_score
             + frequency_score
             + monetary_score >= 13
            THEN 'Champions'

        WHEN recency_score
             + frequency_score
             + monetary_score >= 10
            THEN 'Loyal Customers'

        WHEN recency_score
             + frequency_score
             + monetary_score >= 7
            THEN 'Potential Loyalists'

        WHEN recency_score
             + frequency_score
             + monetary_score >= 5
            THEN 'At Risk'

        ELSE 'Lost Customers'
    END AS customer_segment

FROM rfm_scores;


-- ============================================================
-- 6. Check the saved RFM table
-- ============================================================

SELECT *
FROM retail.customer_rfm
ORDER BY rfm_score DESC;


-- ============================================================
-- 7. Analyze customer segments
-- ============================================================

SELECT
    customer_segment,
    COUNT(*) AS customers,
    SUM(monetary) AS revenue,
    ROUND(AVG(monetary), 2) AS average_customer_value

FROM retail.customer_rfm

GROUP BY customer_segment

ORDER BY revenue DESC;


-- ============================================================
-- 8. Analyze customers by segment
-- ============================================================

SELECT
    customer_segment,

    ROUND(AVG(recency), 2) AS avg_recency,

    ROUND(AVG(frequency), 2) AS avg_frequency,

    ROUND(AVG(monetary), 2) AS avg_monetary

FROM retail.customer_rfm

GROUP BY customer_segment

ORDER BY avg_monetary DESC;



