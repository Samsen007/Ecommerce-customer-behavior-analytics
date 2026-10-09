-- 02_customer_segmentation.sql
-- Builds purchase-active-day metrics, segmentation metrics, and customer segments.
-- Prerequisite: run 01_customer_behavior.sql first.
-- Uses the maximum activity date in the dataset as the reference date.

CREATE OR REPLACE TABLE purchase_active_days AS
SELECT
    client_id,
    COUNT(DISTINCT CAST(timestamp AS DATE)) AS purchase_active_days
FROM read_parquet('C:/Users/shyam/Downloads/synerise_dataset/product_buy.parquet')
GROUP BY client_id;

CREATE OR REPLACE TABLE customer_segmentation_metrics AS
WITH reference AS (
    SELECT CAST(MAX(last_activity) AS DATE) AS reference_date
    FROM customer_behavior
)
SELECT
    cb.client_id,
    cb.active_days,
    cb.first_activity,
    cb.last_activity,
    cb.page_visits,
    cb.searches,
    cb.cart_additions,
    cb.cart_removals,
    cb.unique_skus_added,
    cb.unique_skus_removed,
    cb.purchases,
    cb.unique_skus_purchased,
    cb.first_purchase,
    cb.last_purchase,
    COALESCE(pad.purchase_active_days, 0) AS purchase_active_days,
    DATE_DIFF('day', CAST(cb.last_activity AS DATE), reference.reference_date)
        AS days_since_last_activity,
    CASE WHEN cb.last_purchase IS NOT NULL
        THEN DATE_DIFF('day', CAST(cb.last_purchase AS DATE), reference.reference_date)
        ELSE NULL END AS days_since_last_purchase,
    ROUND(cb.page_visits::DOUBLE / NULLIF(cb.active_days, 0), 2)
        AS page_visits_per_active_day,
    ROUND(cb.searches::DOUBLE / NULLIF(cb.active_days, 0), 2)
        AS searches_per_active_day,
    ROUND(cb.cart_additions::DOUBLE / NULLIF(cb.active_days, 0), 2)
        AS cart_additions_per_active_day,
    ROUND(cb.purchases::DOUBLE / NULLIF(cb.active_days, 0), 2)
        AS purchases_per_active_day,
    ROUND(cb.purchases::DOUBLE / NULLIF(cb.cart_additions, 0), 4)
        AS purchase_to_cart_ratio,
    ROUND(cb.purchases::DOUBLE / NULLIF(cb.searches, 0), 4)
        AS purchase_to_search_ratio,
    (cb.page_visits + cb.searches + cb.cart_additions + cb.cart_removals + cb.purchases)
        AS total_interactions
FROM customer_behavior cb
CROSS JOIN reference
LEFT JOIN purchase_active_days pad ON cb.client_id = pad.client_id;

CREATE OR REPLACE TABLE customer_segmentation AS
WITH purchaser_thresholds AS (
    SELECT
        quantile_cont(active_days, 0.75) AS purchaser_active_days_p75,
        quantile_cont(purchases, 0.75) AS purchaser_purchases_p75,
        quantile_cont(days_since_last_activity, 0.75) AS purchaser_recency_p75
    FROM customer_segmentation_metrics
    WHERE purchases > 0
)
SELECT
    csm.*,
    CASE
        WHEN purchases > 0
            AND active_days >= pt.purchaser_active_days_p75
            AND purchases >= pt.purchaser_purchases_p75
            AND days_since_last_activity < pt.purchaser_recency_p75
            THEN 'High-Engagement Purchaser'
        WHEN purchases > 0
            AND days_since_last_activity >= pt.purchaser_recency_p75
            THEN 'At-Risk Purchaser'
        WHEN purchases > 0 AND purchase_active_days >= 2
            THEN 'Repeat Buyer'
        WHEN purchases = 0 AND cart_additions >= 3
            THEN 'Cart-Heavy Non-Purchaser'
        WHEN purchases = 0 AND searches >= 3
            THEN 'Search-Heavy Non-Purchaser'
        WHEN purchases = 0 AND days_since_last_activity <= 30
            AND total_interactions > 0
            THEN 'Recently Active Non-Purchaser'
        WHEN purchases = 0 AND total_interactions <= 2
            THEN 'Low-Engagement Non-Purchaser'
        WHEN purchases > 0
            THEN 'Other Purchaser'
        ELSE 'Other Non-Purchaser'
    END AS customer_segment
FROM customer_segmentation_metrics csm
CROSS JOIN purchaser_thresholds pt;

-- Segment profile summary
SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS customer_percentage,
    ROUND(AVG(active_days), 2) AS avg_active_days,
    ROUND(AVG(page_visits), 2) AS avg_page_visits,
    ROUND(AVG(searches), 2) AS avg_searches,
    ROUND(AVG(cart_additions), 2) AS avg_cart_additions,
    ROUND(AVG(purchases), 2) AS avg_purchases,
    ROUND(AVG(unique_skus_purchased), 2) AS avg_unique_skus_purchased,
    ROUND(AVG(days_since_last_activity), 2) AS avg_days_since_last_activity
FROM customer_segmentation
GROUP BY customer_segment
ORDER BY customers DESC;

-- Non-purchaser opportunity segments
SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_non_purchasers,
    ROUND(AVG(page_visits), 2) AS avg_page_visits,
    ROUND(AVG(searches), 2) AS avg_searches,
    ROUND(AVG(cart_additions), 2) AS avg_cart_additions,
    ROUND(AVG(total_interactions), 2) AS avg_total_interactions,
    ROUND(AVG(days_since_last_activity), 2) AS avg_days_since_last_activity
FROM customer_segmentation
WHERE purchases = 0
GROUP BY customer_segment
ORDER BY customers DESC;
