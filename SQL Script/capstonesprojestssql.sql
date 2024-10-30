
USE cryptopunk;
#That data set is a sales data set of one of the most famous NFT projects, 
#Cryptopunks. Meaning each row of the data set represents a sale of an NFT. 
#The data includes sales from January 1st, 2018 to December 31st, 2021. 
#The table has several columns including the buyer address, the ETH price, 
#the price in U.S. dollars, the seller’s address, the date, the time, the NFT ID, 
#the transaction hash, and the NFT name.
#You might not understand all the jargon around the NFT space,
 #but you should be able to infer enough to answer the following prompts.

#1)How many sales occurred during this time period? 
SELECT COUNT(*) AS total_sales
FROM cryptopunkdata
WHERE day BETWEEN '01/01/2018' AND '31/12/2021';


#2)Return the top 5 most expensive transactions (by USD price) for this data set.
# Return the name, ETH price, and USD price, as well as the date.

SELECT name, eth_price, usd_price, day
FROM cryptopunkdata
ORDER BY usd_price DESC
LIMIT 5;
    
#3)Return a table with a row for each transaction with an event column, a USD price column, 
#and a moving average of USD price that averages the last 50 transactions.
  
    
    select * from cryptopunkdata;
    SELECT *,'transaction' AS event,
    usd_price,
    AVG(usd_price) OVER (ORDER BY day ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) AS moving_avg_usd_price
    FROM 
    cryptopunkdata
	ORDER BY 
    day;


#4)Return all the NFT names and their average sale price in USD. 
#Sort descending. Name the average column as average_price.

SELECT name AS NFT_NAMES,
    AVG(usd_price) AS Average_Sale_Price
FROM 
    cryptopunkdata
GROUP BY 
    name
ORDER BY 
    Average_Sale_Price DESC;
    
    
#5)Return each day of the week and the number of sales that occurred on that day of the week, 
#as well as the average price in ETH. Order by the count of transactions in ascending order. 
SELECT 
    DAYNAME(day) AS Day_Of_Week,
    COUNT(*) AS Num_Of_Sales,
    AVG(eth_price) AS Avg_Price_Eth
FROM 
    cryptopunkdata
GROUP BY 
    Day_of_week
ORDER BY 
    Num_Of_Sales ASC;


#6 Construct a column that describes each sale and is called summary. 
#The sentence should include who sold the NFT name, who bought the NFT, who sold the NFT, the date, and what price
# it was sold for in USD rounded to the nearest thousandth.
#Here’s an example summary:
# “CryptoPunk #1139 was sold for $194000 to 0x91338ccfb8c0adb7756034a82008531d7713009d from 
 #0x1593110441ab4c5f2c133f21b0743b2b43e297cb on 2022-01-14”

SELECT 
    CONCAT(
        'cryptopunk#', token_id,
        ' was sold for $', ROUND(usd_price, 3),
        ' to ', ï»¿buyer_address,
        ' from ', seller_address,
        ' on ', day
    ) AS summary
FROM 
    cryptopunkdata;


#7)Create a view called “1919_purchases” 
#and contains any sales where “0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685” was the buyer.

CREATE VIEW 1919_purchases AS
SELECT * FROM cryptopunkdata
WHERE ï»¿buyer_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685';

#To see that view
SELECT * FROM 1919_purchases;


#8)Create a histogram of ETH price ranges. Round to the nearest hundred value. 
SELECT ROUND(eth_price, -2) AS bucket, 
COUNT(*) AS count,
RPAD('', COUNT(*), '*') AS bar 
FROM cryptopunkdata
GROUP BY bucket
ORDER BY bucket;

#8)Create a histogram of ETH price ranges. Round to the nearest hundred value. 
SELECT ROUND(eth_price, -2) AS eth_price_range,
COUNT(*) AS frequency,
RPAD('', COUNT(*), '*') AS bar
FROM cryptopunkdata
GROUP BY ROUND(eth_price, -2)

ORDER BY eth_price_range;


#9)Return a unioned query that contains the highest price each NFT was 
#bought for and a new column called status saying “highest” with a query that has the lowest price each
# NFT was bought for and the status column saying “lowest”. The table should have a name column,
# a price column called price, and a status column.
# Order the result set by the name of the NFT, and the status, in ascending order. 
-- Query to retrieve the highest price for each NFT
    SELECT name, MAX(eth_price) AS price, 'Highest' as Status
    FROM cryptopunkdata
    GROUP BY name
    UNION
	SELECT name, MIN(eth_price) AS price, 'Lowest' as status
    FROM cryptopunkdata
    GROUP BY name
    ORDER BY name;
    

#10)What NFT sold the most each month / year combination? Also, 
#what was the name and the price in USD? Order in chronological format. 

SELECT year, month, name, price_in_usd
FROM (
    SELECT 
        YEAR(day) AS year,
        MONTH(day) AS month,
        name,
        usd_price AS price_in_usd,
        ROW_NUMBER() OVER (PARTITION BY YEAR(day), MONTH(day) ORDER BY usd_price DESC) AS rn
    FROM 
        cryptopunkdata

WHERE
        day IS NOT NULL
        )
AS ranked
WHERE 
    rn = 1
ORDER BY 
    year ASC, month ASC;

#11)Return the total volume (sum of all sales), round to the nearest hundred on a monthly basis (month/year).
SELECT 
    YEAR(day) AS year,
    MONTH(day) AS month,
    ROUND(SUM(usd_price), -2) AS total_volume
FROM 
    cryptopunkdata
GROUP BY 
    YEAR(day), MONTH(day);




#12)Count how many transactions the wallet "0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685"had over this time period.

SELECT 
    COUNT(*) AS Total_num_transactions
FROM 
    cryptopunkdata
WHERE 
    ï»¿buyer_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685' 
    OR seller_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685';

#13Create an “estimated average value calculator” that has a representative price of the collection 
#every day based off of these criteria:
#- Exclude all daily outlier sales where the purchase price is below 10% of the daily average price

#a) First create a query that will be used as a subquery. Select the event date, the USD price, 
#and the average USD price for each day using a window function. 
#Save it as a temporary table.

CREATE TEMPORARY TABLE temp_daily_avg_price AS
SELECT
    day AS event_date,
    usd_price,
    AVG(usd_price) OVER (PARTITION BY day) AS avg_usd_price
FROM
    cryptopunkdata;



#b) b) Use the table you created in Part A to filter out rows where the 
#USD prices is below 10% of the daily average and return a new estimated 
#value which is just the daily average of the filtered data.
#Now using that temporary table
SELECT event_date,
    AVG(usd_price) AS estimated_value
FROM
    temp_daily_avg_price
WHERE
    usd_price >= 0.1 * avg_usd_price
GROUP BY
    event_date;





