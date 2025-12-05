# VettySQLTest

## 1. Count of purchases per month (excluding refunded purchases)
Approach: I removed all refunded purchases, grouped the valid ones by month, and counted how many successful transactions happened in each month.

#### SQL CODE:
SELECT 
    DATE_FORMAT(purchase_time, '%Y-%m') AS month,
    COUNT(*) AS total_purchases
FROM transactions
WHERE refund_item IS NULL
GROUP BY DATE_FORMAT(purchase_time, '%Y-%m');
<img width="1920" height="1080" alt="Q1" src="https://github.com/user-attachments/assets/6d092864-6814-4d96-bb4d-44bce460712b" />

## 2. Stores receiving at least 5 orders in October 2020
Approach: I filtered the data for October 2020, counted orders for each store, and then selected only those stores that reached 5 or more orders.

#### SQL CODE:
SELECT 
    store_id,
    COUNT(*) AS total_orders
FROM transactions
WHERE purchase_time >= '2020-10-01'
  AND purchase_time < '2020-11-01'
GROUP BY store_id
HAVING COUNT(*) >= 5;

<img width="1920" height="1080" alt="Q2" src="https://github.com/user-attachments/assets/64035ace-29ee-47e7-a8eb-a3d8d4399dd6" />

## 3. Shortest interval (minutes) from purchase to refund per store
Approach:From all refunded transactions, I measured the time difference between purchase and refund, grouped by store, and selected the minimum time interval.

#### SQL CODE:
SELECT
    store_id,
    MIN(TIMESTAMPDIFF(MINUTE, purchase_time, refund_item)) AS shortest_refund_interval
FROM transactions
WHERE refund_item IS NOT NULL
GROUP BY store_id;
<img width="1920" height="1080" alt="Q3" src="https://github.com/user-attachments/assets/ffba2260-f195-4028-a8c0-0b9c724258c5" />

## 4. Gross transaction value of every store’s first order
Approach:

I found each store’s earliest purchase and used it to identify the transaction and its gross value.

#### SQL CODE:
SELECT t.store_id, t.gross_transaction_value
FROM transactions t
JOIN (
    SELECT store_id, MIN(purchase_time) AS first_time
    FROM transactions
    GROUP BY store_id
) x
ON t.store_id = x.store_id
AND t.purchase_time = x.first_time;
<img width="1920" height="1080" alt="Q4" src="https://github.com/user-attachments/assets/1e9442f3-3fce-444d-931c-1c353a8b10a1" />

## 5. Most popular item name in buyers’ first purchase
Approach:

I ranked each buyer’s purchases by time, selected only the first ones, joined them with the item table, and counted which item appeared most frequently.

#### SQL CODE:
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
<img width="1920" height="1080" alt="Q5" src="https://github.com/user-attachments/assets/3eeee057-1113-442c-904c-fb7bdf95c0de" />

## 6. Refund eligibility flag (must happen within 72 hours)
Approach:

I calculated the time difference between purchase and refund.
If it was within 72 hours, I marked it “Refund Processed”; otherwise, “Refund Rejected.”

#### SQL CODE:
SELECT
    *,
    CASE 
        WHEN refund_item IS NULL THEN 'No Refund'
        WHEN TIMESTAMPDIFF(HOUR, purchase_time, refund_item) <= 72 
             THEN 'Refund Processed'
        ELSE 'Refund Rejected'
    END AS refund_flag
FROM transactions;
<img width="1920" height="1080" alt="Q6" src="https://github.com/user-attachments/assets/c5f6f23c-ace0-4dd7-bc41-5b31e9eff72a" />

## 7. Find only the second purchase per buyer (ignore refunds)
Approach:

I ranked each buyer’s valid purchases and selected the rows ranked as the second purchase.

#### SQL CODE:
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
<img width="1920" height="1080" alt="Q7" src="https://github.com/user-attachments/assets/6ec3022b-cea5-4bae-86c8-3706731ab4c6" />

## 8. Find the second transaction time per buyer (don’t use min/max)
Approach:

I used row numbering to order transactions per buyer, then returned only the one that appears second in that order.

#### SQL CODE:
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
<img width="1920" height="1080" alt="Q8" src="https://github.com/user-attachments/assets/6f730ce5-7bbc-4b37-a1e9-25311855031f" />
