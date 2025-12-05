create database  VettySQLtest ;

-- TABLE 1 TRANSACTIONS

CREATE TABLE transactions (
    buyer_id INT,
    purchase_time DATETIME,
    refund_item DATETIME,
    store_id VARCHAR(5),
    item_id VARCHAR(10),
    gross_transaction_value VARCHAR(20)
);
insert into transactions (buyer_id, purchase_time, refund_item, store_id, item_id, gross_transaction_value)
VALUES(3, '2019-09-19 21:19:06.544', NULL, 'a', 'a1', '$58'),
(12, '2019-12-10 20:10:14.324', '2019-12-15 23:19:06.544', 'b', 'b2', '$475'),
(3, '2020-09-01 23:59:46.561', '2020-09-02 21:22:06.331', 'f', 'f9', '$33'),
(2, '2020-04-30 21:19:06.544', NULL, 'd', 'd3', '$250'),
(1, '2020-10-22 22:20:06.531', NULL, 'f', 'f2', '$91'),
(8, '2020-04-16 21:10:22.214', NULL, 'e', 'e7', '$24'),
(5, '2019-09-23 12:09:35.542', '2019-09-27 02:55:02.114', 'g', 'g6', '$61');

-- TABLE 2 ITEMS 

CREATE TABLE items (
    store_id VARCHAR(5),
    item_id VARCHAR(10),
    item_category VARCHAR(50),
    item_name VARCHAR(100)
);
INSERT INTO items (store_id, item_id, item_category, item_name)
VALUES
('a', 'a1', 'pants', 'denim pants'),
('a', 'a2', 'tops', 'blouse'),
('f', 'f1', 'table', 'coffee table'),
('f', 'f5', 'chair', 'lounge chair'),
('f', 'f6', 'chair', 'armchair'),
('d', 'd2', 'jewelry', 'bracelet'),
('b', 'b4', 'earphone', 'airpods');


-- Count of purchases per month (excluding refunded purchases)

SELECT 
    DATE_FORMAT(purchase_time, '%Y-%m') AS month,
    COUNT(*) AS total_purchases
FROM transactions
WHERE refund_item IS NULL
GROUP BY DATE_FORMAT(purchase_time, '%Y-%m')
ORDER BY month;

-- Stores receiving at least 5 orders in Oct 2020

SELECT 
    store_id,
    COUNT(*) AS total_orders
FROM transactions
WHERE purchase_time >= '2020-10-01'
  AND purchase_time < '2020-11-01'
GROUP BY store_id
HAVING COUNT(*) >= 5;

-- Shortest interval (minutes) from purchase to refund per store
SELECT
    store_id,
    MIN(TIMESTAMPDIFF(MINUTE, purchase_time, refund_item)) AS shortest_refund_interval_minutes
FROM transactions
WHERE refund_item IS NOT NULL
GROUP BY store_id;

-- Gross transaction value of each store’s first order

SELECT t.store_id, t.gross_transaction_value
FROM transactions t
JOIN (
    SELECT store_id, MIN(purchase_time) AS first_order_time
    FROM transactions
    GROUP BY store_id
) x
ON t.store_id = x.store_id
AND t.purchase_time = x.first_order_time;

-- Most popular item name from buyer’s first purchase
WITH first_purchase AS (
    SELECT *
    FROM (
        SELECT 
            t.*, 
            ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
        FROM transactions t
    ) x
    WHERE rn = 1
)
SELECT i.item_name, COUNT(*) AS total_orders
FROM first_purchase fp
JOIN items i USING (store_id, item_id)
GROUP BY i.item_name
ORDER BY total_orders DESC
LIMIT 1;

-- Create refund flag (refundable within 72 hours)
-- refund_item - purchase_time ≤ 72 hours
SELECT
    *,
    CASE 
        WHEN refund_item IS NULL THEN 'No Refund'
        WHEN TIMESTAMPDIFF(HOUR, purchase_time, refund_item) <= 72 
             THEN 'Refund Processed'
        ELSE 'Refund Rejected'
    END AS refund_flag
FROM transactions;

-- Rank transactions per buyer and return only the second purchase

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

-- Find the second transaction time per buyer (no MIN/MAX allowed)
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



