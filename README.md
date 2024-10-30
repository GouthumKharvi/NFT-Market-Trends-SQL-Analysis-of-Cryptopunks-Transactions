# NFT-Market-Trends-SQL-Analysis-of-Cryptopunks-Transactions
This project analyzes Cryptopunks NFT sales from January 2018 to December 2021 using SQL. We explore total sales, top transactions, average prices, and daily trends, including buyer-specific insights and price distributions. The goal is to uncover valuable insights into the NFT market dynamics.



## Cryptopunk Sales Data Analysis

This dataset contains sales data for the Cryptopunks NFT project from January 1st, 2018, to December 31st, 2021. Each row represents a sale of an NFT, including details such as buyer and seller addresses, ETH price, USD price, transaction date, and NFT ID.

### SQL Queries

```sql
-- Use the Cryptopunk database
USE cryptopunk;

-- 1) How many sales occurred during this time period?
SELECT COUNT(*) AS total_sales
FROM cryptopunkdata
WHERE day BETWEEN '2018-01-01' AND '2021-12-31';

-- 2) Return the top 5 most expensive transactions (by USD price)
SELECT name, eth_price, usd_price, day
FROM cryptopunkdata
ORDER BY usd_price DESC
LIMIT 5;

-- 3) Return a table with a moving average of USD price for the last 50 transactions
SELECT *,
    'transaction' AS event,
    usd_price,
    AVG(usd_price) OVER (ORDER BY day ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) AS moving_avg_usd_price
FROM cryptopunkdata
ORDER BY day;

-- 4) Return all the NFT names and their average sale price in USD
SELECT name AS NFT_NAMES,
    AVG(usd_price) AS average_price
FROM cryptopunkdata
GROUP BY name
ORDER BY average_price DESC;

-- 5) Return each day of the week and the number of sales that occurred on that day, 
-- as well as the average price in ETH.
SELECT 
    DAYNAME(day) AS Day_Of_Week,
    COUNT(*) AS Num_Of_Sales,
    AVG(eth_price) AS Avg_Price_Eth
FROM cryptopunkdata
GROUP BY Day_Of_Week
ORDER BY Num_Of_Sales ASC;

-- 6) Construct a summary column for each sale
SELECT 
    CONCAT(
        'CryptoPunk #', token_id,
        ' was sold for $', ROUND(usd_price, 3),
        ' to ', buyer_address,
        ' from ', seller_address,
        ' on ', day
    ) AS summary
FROM cryptopunkdata;

-- 7) Create a view called “1919_purchases” for a specific buyer
CREATE VIEW 1919_purchases AS
SELECT * FROM cryptopunkdata
WHERE buyer_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685';

-- To see that view
SELECT * FROM 1919_purchases;

-- 8) Create a histogram of ETH price ranges, rounded to the nearest hundred value
SELECT ROUND(eth_price, -2) AS eth_price_range, 
    COUNT(*) AS frequency,
    RPAD('', COUNT(*), '*') AS bar
FROM cryptopunkdata
GROUP BY eth_price_range
ORDER BY eth_price_range;

-- 9) Union query for highest and lowest prices per NFT
SELECT name, MAX(eth_price) AS price, 'Highest' AS Status
FROM cryptopunkdata
GROUP BY name
UNION
SELECT name, MIN(eth_price) AS price, 'Lowest' AS Status
FROM cryptopunkdata
GROUP BY name
ORDER BY name, Status;

-- 10) What NFT sold the most each month/year combination?
SELECT year, month, name, price_in_usd
FROM (
    SELECT 
        YEAR(day) AS year,
        MONTH(day) AS month,
        name,
        usd_price AS price_in_usd,
        ROW_NUMBER() OVER (PARTITION BY YEAR(day), MONTH(day) ORDER BY usd_price DESC) AS rn
    FROM cryptopunkdata
    WHERE day IS NOT NULL
) AS ranked
WHERE rn = 1
ORDER BY year ASC, month ASC;

-- 11) Return the total volume of sales, rounded to the nearest hundred on a monthly basis
SELECT 
    YEAR(day) AS year,
    MONTH(day) AS month,
    ROUND(SUM(usd_price), -2) AS total_volume
FROM cryptopunkdata
GROUP BY YEAR(day), MONTH(day);

-- 12) Count transactions for a specific wallet address
SELECT 
    COUNT(*) AS Total_num_transactions
FROM cryptopunkdata
WHERE buyer_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685' 
   OR seller_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685';

-- 13) Create an estimated average value calculator, excluding outliers
CREATE TEMPORARY TABLE temp_daily_avg_price AS
SELECT
    day AS event_date,
    usd_price,
    AVG(usd_price) OVER (PARTITION BY day) AS avg_usd_price
FROM cryptopunkdata;

SELECT event_date,
    AVG(usd_price) AS estimated_value
FROM temp_daily_avg_price
WHERE usd_price >= 0.1 * avg_usd_price
GROUP BY event_date;

