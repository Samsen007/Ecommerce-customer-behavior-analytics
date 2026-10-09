-- 01_customer_behavior.sql
-- Builds customer-level engagement and purchase metrics from the Synerise event files.
-- Update the folder path below if your Parquet files are stored elsewhere.
-- Run in DuckDB. This script creates/replaces customer_behavior.

CREATE OR REPLACE TABLE customer_behavior AS
WITH
page AS (
    SELECT
        client_id,
        COUNT(*) AS page_visits,
        COUNT(DISTINCT CAST(timestamp AS DATE)) AS page_active_days,
        MIN(CAST(timestamp AS TIMESTAMP)) AS first_page_visit,
        MAX(CAST(timestamp AS TIMESTAMP)) AS last_page_visit
    FROM read_parquet('C:/Users/shyam/Downloads/synerise_dataset/page_visit.parquet')
    GROUP BY client_id
),
searches AS (
    SELECT
        client_id,
        COUNT(*) AS searches,
        COUNT(DISTINCT CAST(timestamp AS DATE)) AS search_active_days,
        MIN(CAST(timestamp AS TIMESTAMP)) AS first_search,
        MAX(CAST(timestamp AS TIMESTAMP)) AS last_search
    FROM read_parquet('C:/Users/shyam/Downloads/synerise_dataset/search_query.parquet')
    GROUP BY client_id
),
cart_add AS (
    SELECT
        client_id,
        COUNT(*) AS cart_additions,
        COUNT(DISTINCT sku) AS unique_skus_added,
        COUNT(DISTINCT CAST(timestamp AS DATE)) AS cart_add_active_days,
        MIN(CAST(timestamp AS TIMESTAMP)) AS first_cart_add,
        MAX(CAST(timestamp AS TIMESTAMP)) AS last_cart_add
    FROM read_parquet('C:/Users/shyam/Downloads/synerise_dataset/add_to_cart.parquet')
    GROUP BY client_id
),
cart_remove AS (
    SELECT
        client_id,
        COUNT(*) AS cart_removals,
        COUNT(DISTINCT sku) AS unique_skus_removed,
        COUNT(DISTINCT CAST(timestamp AS DATE)) AS cart_remove_active_days,
        MIN(CAST(timestamp AS TIMESTAMP)) AS first_cart_remove,
        MAX(CAST(timestamp AS TIMESTAMP)) AS last_cart_remove
    FROM read_parquet('C:/Users/shyam/Downloads/synerise_dataset/remove_from_cart.parquet')
    GROUP BY client_id
),
purchase AS (
    SELECT
        client_id,
        COUNT(*) AS purchases,
        COUNT(DISTINCT sku) AS unique_skus_purchased,
        COUNT(DISTINCT CAST(timestamp AS DATE)) AS purchase_active_days,
        MIN(CAST(timestamp AS TIMESTAMP)) AS first_purchase,
        MAX(CAST(timestamp AS TIMESTAMP)) AS last_purchase
    FROM read_parquet('C:/Users/shyam/Downloads/synerise_dataset/product_buy.parquet')
    GROUP BY client_id
),
all_activity AS (
    SELECT client_id, CAST(timestamp AS TIMESTAMP) AS event_time
    FROM read_parquet('C:/Users/shyam/Downloads/synerise_dataset/page_visit.parquet')
    UNION ALL
    SELECT client_id, CAST(timestamp AS TIMESTAMP)
    FROM read_parquet('C:/Users/shyam/Downloads/synerise_dataset/search_query.parquet')
    UNION ALL
    SELECT client_id, CAST(timestamp AS TIMESTAMP)
    FROM read_parquet('C:/Users/shyam/Downloads/synerise_dataset/add_to_cart.parquet')
    UNION ALL
    SELECT client_id, CAST(timestamp AS TIMESTAMP)
    FROM read_parquet('C:/Users/shyam/Downloads/synerise_dataset/remove_from_cart.parquet')
    UNION ALL
    SELECT client_id, CAST(timestamp AS TIMESTAMP)
    FROM read_parquet('C:/Users/shyam/Downloads/synerise_dataset/product_buy.parquet')
),
activity AS (
    SELECT
        client_id,
        COUNT(DISTINCT CAST(event_time AS DATE)) AS active_days,
        MIN(event_time) AS first_activity,
        MAX(event_time) AS last_activity
    FROM all_activity
    GROUP BY client_id
)
SELECT
    a.client_id,
    a.active_days,
    a.first_activity,
    a.last_activity,
    COALESCE(p.page_visits, 0) AS page_visits,
    COALESCE(s.searches, 0) AS searches,
    COALESCE(ca.cart_additions, 0) AS cart_additions,
    COALESCE(cr.cart_removals, 0) AS cart_removals,
    COALESCE(ca.unique_skus_added, 0) AS unique_skus_added,
    COALESCE(cr.unique_skus_removed, 0) AS unique_skus_removed,
    COALESCE(pr.purchases, 0) AS purchases,
    COALESCE(pr.unique_skus_purchased, 0) AS unique_skus_purchased,
    pr.first_purchase,
    pr.last_purchase,
    CASE WHEN COALESCE(ca.cart_additions, 0) > 0
        THEN ROUND(COALESCE(cr.cart_removals, 0) * 1.0 / ca.cart_additions, 4)
        ELSE 0 END AS cart_removal_rate,
    CASE WHEN COALESCE(ca.cart_additions, 0) > 0
        THEN ROUND(COALESCE(pr.purchases, 0) * 1.0 / ca.cart_additions, 4)
        ELSE 0 END AS purchase_per_cart_rate,
    CASE WHEN COALESCE(s.searches, 0) > 0
        THEN ROUND(COALESCE(pr.purchases, 0) * 1.0 / s.searches, 4)
        ELSE 0 END AS purchase_per_search_rate,
    CASE WHEN COALESCE(p.page_visits, 0) > 0
        THEN ROUND(COALESCE(pr.purchases, 0) * 1.0 / p.page_visits, 6)
        ELSE 0 END AS purchase_per_page_rate
FROM activity a
LEFT JOIN page p ON a.client_id = p.client_id
LEFT JOIN searches s ON a.client_id = s.client_id
LEFT JOIN cart_add ca ON a.client_id = ca.client_id
LEFT JOIN cart_remove cr ON a.client_id = cr.client_id
LEFT JOIN purchase pr ON a.client_id = pr.client_id;

-- Quick validation summary
SELECT
    COUNT(*) AS customers,
    ROUND(AVG(active_days), 2) AS avg_active_days,
    ROUND(AVG(page_visits), 2) AS avg_page_visits,
    ROUND(AVG(searches), 2) AS avg_searches,
    ROUND(AVG(cart_additions), 2) AS avg_cart_additions,
    ROUND(AVG(cart_removals), 2) AS avg_cart_removals,
    ROUND(AVG(purchases), 2) AS avg_purchases
FROM customer_behavior;

-- Purchaser vs non-purchaser comparison
SELECT
    CASE WHEN purchases > 0 THEN 'Purchaser' ELSE 'Non-Purchaser' END AS customer_type,
    COUNT(*) AS customers,
    ROUND(AVG(active_days), 2) AS avg_active_days,
    ROUND(AVG(page_visits), 2) AS avg_page_visits,
    ROUND(AVG(searches), 2) AS avg_searches,
    ROUND(AVG(cart_additions), 2) AS avg_cart_additions,
    ROUND(AVG(cart_removals), 2) AS avg_cart_removals,
    ROUND(AVG(purchases), 2) AS avg_purchases
FROM customer_behavior
GROUP BY customer_type
ORDER BY customer_type;
