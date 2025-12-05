# VettySQLTest

## 1. Count of purchases per month (excluding refunded purchases)
Approach: I removed all refunded purchases, grouped the valid ones by month, and counted how many successful transactions happened in each month.

SQL:
SELECT 
    DATE_FORMAT(purchase_time, '%Y-%m') AS month,
    COUNT(*) AS total_purchases
FROM transactions
WHERE refund_item IS NULL
GROUP BY DATE_FORMAT(purchase_time, '%Y-%m');

## 2. Stores receiving at least 5 orders in October 2020
Approach: I filtered the data for October 2020, counted orders for each store, and then selected only those stores that reached 5 or more orders.

SQL:
SELECT 
    store_id,
    COUNT(*) AS total_orders
FROM transactions
WHERE purchase_time >= '2020-10-01'
  AND purchase_time < '2020-11-01'
GROUP BY store_id
HAVING COUNT(*) >= 5;

## 3. Shortest interval (minutes) from purchase to refund per store
Approach:From all refunded transactions, I measured the time difference between purchase and refund, grouped by store, and selected the minimum time interval.

SQL:
SELECT
    store_id,
    MIN(TIMESTAMPDIFF(MINUTE, purchase_time, refund_item)) AS shortest_refund_interval
FROM transactions
WHERE refund_item IS NOT NULL
GROUP BY store_id;

## 4. Gross transaction value of every store’s first order
Approach:

I found each store’s earliest purchase and used it to identify the transaction and its gross value.

SQL:
SELECT t.store_id, t.gross_transaction_value
FROM transactions t
JOIN (
    SELECT store_id, MIN(purchase_time) AS first_time
    FROM transactions
    GROUP BY store_id
) x
ON t.store_id = x.store_id
AND t.purchase_time = x.first_time;

## 5. Most popular item name in buyers’ first purchase
Approach:

I ranked each buyer’s purchases by time, selected only the first ones, joined them with the item table, and counted which item appeared most frequently.

SQL:
WITH first_purchase AS (
    SELECT *
    FROM (
        SELECT 
            t.*,
            ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
        FROM transactions t
    ) a
    WHERE rn = 1
)
SELECT i.item_name, COUNT(*) AS total_orders
FROM first_purchase fp
JOIN items i USING (store_id, item_id)
GROUP BY i.item_name
ORDER BY total_orders DESC
LIMIT 1;

## 6. Refund eligibility flag (must happen within 72 hours)
Approach:

I calculated the time difference between purchase and refund.
If it was within 72 hours, I marked it “Refund Processed”; otherwise, “Refund Rejected.”

SQL:
SELECT
    *,
    CASE 
        WHEN refund_item IS NULL THEN 'No Refund'
        WHEN TIMESTAMPDIFF(HOUR, purchase_time, refund_item) <= 72 
             THEN 'Refund Processed'
        ELSE 'Refund Rejected'
    END AS refund_flag
FROM transactions;

## 7. Find only the second purchase per buyer (ignore refunds)
Approach:

I ranked each buyer’s valid purchases and selected the rows ranked as the second purchase.

SQL:
WITH ranked AS (
    SELECT 
        t.*,
        ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
    FROM transactions t
    WHERE refund_item IS NULL
)
SELECT *
FROM ranked
WHERE rn = 2;

## 8. Find the second transaction time per buyer (don’t use min/max)
Approach:

I used row numbering to order transactions per buyer, then returned only the one that appears second in that order.

SQL:
WITH ranked AS (
    SELECT 
        buyer_id,
        purchase_time,
        ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
    FROM transactions
)
SELECT buyer_id, purchase_time
FROM ranked
WHERE rn = 2;
