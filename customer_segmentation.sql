
CREATE DATABASE IF NOT EXISTS retail_db;
USE retail_db;


CREATE TABLE retail_raw (
    InvoiceNo   VARCHAR(20),
    StockCode   VARCHAR(20),
    Description VARCHAR(255),
    Quantity    INT,
    InvoiceDate VARCHAR(30),      -- kept as text: the file has 2 date formats
    UnitPrice   DECIMAL(10,2),
    CustomerID  VARCHAR(20),      -- text, because missing IDs are empty
    Country     VARCHAR(60)
);

-- Load the CSV 
-- SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE 'C:/path/to/online_retail.csv'
INTO TABLE retail_raw
CHARACTER SET latin1
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- ========== STEP 2: DATA QUALITY CHECKS ==========
SELECT COUNT(*) AS total_rows FROM retail_raw;

SELECT
    SUM(NULLIF(CustomerID,'') IS NULL)            AS missing_customer,
    SUM(NULLIF(TRIM(Description),'') IS NULL)     AS missing_description,
    SUM(Quantity <= 0)                            AS bad_quantity,
    SUM(UnitPrice <= 0)                           AS bad_price,
    SUM(InvoiceNo LIKE 'C%')                      AS cancelled_invoices
FROM retail_raw;

-- exact duplicate rows
SELECT COUNT(*) - COUNT(DISTINCT InvoiceNo, StockCode, Description, Quantity,
                                 InvoiceDate, UnitPrice, CustomerID, Country) AS duplicate_rows
FROM retail_raw;

-- ========== STEP 3: CLEAN TABLE ==========

CREATE TABLE retail_clean AS
SELECT DISTINCT                                            -- removes duplicates
    InvoiceNo,
    StockCode,
    COALESCE(NULLIF(TRIM(Description),''), 'UNKNOWN')      AS Description,
    Quantity,
    COALESCE(STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i'),   -- '2/17/2011 12:42'
             STR_TO_DATE(InvoiceDate, '%m-%d-%Y'))         AS InvoiceDate,  -- '12-01-2010'
    UnitPrice,
    CAST(CustomerID AS UNSIGNED)                           AS CustomerID,
    Country,
    Quantity * UnitPrice                                   AS TotalPrice
FROM retail_raw
WHERE NULLIF(CustomerID,'') IS NOT NULL                    -- drop missing customers
  AND InvoiceNo NOT LIKE 'C%'                              -- drop cancellations
  AND Quantity > 0
  AND UnitPrice > 0;

SELECT COUNT(*) AS clean_rows, MIN(InvoiceDate) AS first_date, MAX(InvoiceDate) AS last_date
FROM retail_clean;                                          -- expect NO NULL dates

-- ========== STEP 4: SPLIT HISTORY / FUTURE ==========
-- Features use only history; the target (will they buy again?) comes from the last 30 days.
SET @cutoff = (SELECT DATE_SUB(MAX(InvoiceDate), INTERVAL 30 DAY) FROM retail_clean);
SELECT @cutoff;

-- ========== STEP 5: FEATURE ENGINEERING (one row per customer) ==========

CREATE TABLE customer_features AS
SELECT
    CustomerID,
    DATEDIFF(DATE_ADD(@cutoff, INTERVAL 1 DAY), MAX(InvoiceDate))   AS Recency,
    COUNT(DISTINCT InvoiceNo)                                       AS Frequency,
    ROUND(SUM(TotalPrice), 2)                                       AS Monetary,        -- historical CLV
    ROUND(SUM(TotalPrice) / COUNT(DISTINCT InvoiceNo), 2)           AS AOV,
    COUNT(DISTINCT StockCode)                                       AS UniqueProducts,
    ROUND(SUM(Quantity) / COUNT(DISTINCT InvoiceNo), 2)             AS AvgItemsPerOrder,
    DATEDIFF(DATE_ADD(@cutoff, INTERVAL 1 DAY), MIN(InvoiceDate))   AS Tenure
FROM retail_clean
WHERE InvoiceDate <= @cutoff
GROUP BY CustomerID;

-- ========== STEP 6: TARGET VARIABLES ==========

CREATE TABLE customer_model_data AS
SELECT
    f.*,
    COALESCE(t.FutureSpend, 0)           AS FutureSpend,    -- regression target
    (t.CustomerID IS NOT NULL)           AS WillBuy         -- classification target (1/0)
FROM customer_features f
LEFT JOIN (
    SELECT CustomerID, SUM(TotalPrice) AS FutureSpend
    FROM retail_clean
    WHERE InvoiceDate > @cutoff
    GROUP BY CustomerID
) t ON t.CustomerID = f.CustomerID;

-- ========== STEP 7: RULE-BASED RFM SEGMENTATION IN SQL ==========
-- (K-Means itself must be run in Python; this is the SQL equivalent using quartiles)

CREATE TABLE customer_segments_sql AS
WITH scored AS (
    SELECT m.*,
           NTILE(4) OVER (ORDER BY Recency DESC) AS R,   -- 4 = most recent
           NTILE(4) OVER (ORDER BY Frequency)    AS F,   -- 4 = most frequent
           NTILE(4) OVER (ORDER BY Monetary)     AS M    -- 4 = biggest spender
    FROM customer_model_data m
)
SELECT *,
    CASE
        WHEN R >= 3 AND F >= 3 AND M >= 3 THEN 'Champions (high value)'
        WHEN F >= 3                       THEN 'Loyal / frequent'
        WHEN R >= 3                       THEN 'Potential / new'
        ELSE                                   'At-risk / low value'
    END AS Segment
FROM scored;

-- ========== STEP 8: INSIGHTS ==========
SELECT Segment,
       COUNT(*)                        AS Customers,
       ROUND(AVG(Recency), 1)          AS AvgRecency,
       ROUND(AVG(Frequency), 1)        AS AvgFrequency,
       ROUND(AVG(Monetary), 0)         AS AvgMonetary,
       ROUND(AVG(AOV), 0)              AS AvgAOV,
       ROUND(AVG(WillBuy), 2)          AS RepeatRate,
       ROUND(AVG(FutureSpend), 0)      AS AvgFutureSpend,
       ROUND(100 * SUM(Monetary) / SUM(SUM(Monetary)) OVER (), 1) AS PctOfRevenue
FROM customer_segments_sql
GROUP BY Segment
ORDER BY AvgMonetary DESC;

-- Revenue by country and top products (extra context for marketing)
SELECT Country, COUNT(DISTINCT CustomerID) AS Customers, ROUND(SUM(TotalPrice),0) AS Revenue
FROM retail_clean GROUP BY Country ORDER BY Revenue DESC LIMIT 10;

SELECT Description, SUM(Quantity) AS UnitsSold, ROUND(SUM(TotalPrice),0) AS Revenue
FROM retail_clean GROUP BY Description ORDER BY Revenue DESC LIMIT 10;






