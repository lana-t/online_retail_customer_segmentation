/*
===========================================================
01_clean.sql

Purpose:
Clean and prepare the OnlineRetail dataset for analysis. 
This script:
- Handles missing values
- Standardises textual fields
- Validates key columns
- Removes non-product entries
- Aggregates repeated transactions
- Produces a cleaned table ready for analysis

Output:
Creates: 
- OnlineRetail_No_Nulls
- OnlineRetail_Description_Cleaned
- OnlineRetail_Aggregated
- OnlineRetail_Clean (final)
===========================================================
*/

-- =========================================================
-- Step 0: Create a backup of the original data
-- =========================================================

SELECT *
INTO OnlineRetail_Backup
FROM OnlineRetail;

-- =========================================================
-- Step 1: Identify exact duplicate rows
-- =========================================================

SELECT *, COUNT(*) AS Count
FROM OnlineRetail
GROUP BY InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country
HAVING COUNT(*) > 1;

-- Remove exact duplicates using ROW_NUMBER()
WITH Deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country ORDER BY (SELECT NULL)) AS rn
    FROM OnlineRetail
)
DELETE FROM Deduped WHERE rn > 1;

-- ===============================================
-- Step 2: Investigate NULLs in key columns
-- ===============================================

-- Check for NULL Invoice Numbers
SELECT * FROM OnlineRetail WHERE InvoiceNo IS NULL;

-- Check for NULL Customer IDs
SELECT * FROM OnlineRetail WHERE CustomerID IS NULL;

-- Check for NULL Descriptions
SELECT * FROM OnlineRetail WHERE Description IS NULL;

-- ===========================================================================
-- Step 3: Fill missing Descriptions based on most common value per StockCode
-- ===========================================================================

-- Rank descriptions by frequency for each StockCode
WITH DescriptionRanked AS (
    SELECT StockCode, Description, COUNT(*) AS Count,
           ROW_NUMBER() OVER (PARTITION BY StockCode ORDER BY COUNT(*) DESC) AS rn
    FROM OnlineRetail
    WHERE Description IS NOT NULL
    GROUP BY StockCode, Description
),
MostFrequentDescriptions AS (
    SELECT StockCode, Description
    FROM DescriptionRanked
    WHERE rn = 1
),

-- Replace NULL Descriptions with most frequent per StockCode
FilledDescription AS (
    SELECT 
        O.InvoiceNo, O.StockCode,
        COALESCE(O.Description, MF.Description) AS Description,
        O.Quantity, O.InvoiceDate, O.UnitPrice, O.CustomerID, O.Country
    FROM OnlineRetail AS O
    LEFT JOIN MostFrequentDescriptions AS MF
        ON O.StockCode = MF.StockCode
),

-- ===============================================
-- Step 4: Remove remaining NULLs
-- ===============================================

-- Remove rows where InvoiceNo, CustomerID, or Description are still NULL
NullsChecked AS (
    SELECT *
    FROM FilledDescription
    WHERE InvoiceNo IS NOT NULL 
		AND CustomerID IS NOT NULL 
		AND Description IS NOT NULL
)

-- ===============================================
-- Step 5: Save intermediate cleaned table
-- ===============================================
SELECT *
INTO OnlineRetail_No_Nulls
FROM NullsChecked;

-- ===============================================
-- Step 6: Column consistency checks
-- ===============================================

-- InvoiceNo: Confirm consistent formatting
SELECT DISTINCT LEN(InvoiceNo) AS len_InvoiceNo 
FROM OnlineRetail_No_Nulls;

-- StockCode: Check for anomalies in length and format
SELECT DISTINCT LEN(StockCode) AS len_StockCode 
FROM OnlineRetail_No_Nulls;

SELECT DISTINCT StockCode, Description 
FROM OnlineRetail_No_Nulls 
WHERE LEN(StockCode) NOT IN (5, 6);

SELECT * 
FROM OnlineRetail_No_Nulls 
WHERE StockCode LIKE '15056%';

-- Identify and filter out non-product entries
SELECT * 
FROM OnlineRetail_No_Nulls 
WHERE StockCode NOT IN ('C2', 'POST', 'DOT', 'M', 'BANK CHARGES');

-- ==============================================================================
-- Step 7: Standardise Description formatting and filter out non-product entries
-- ==============================================================================

-- Check and resolve inconsistencies in Description formatting
SELECT StockCode, Description, COUNT(*) AS Count
FROM OnlineRetail_No_Nulls
WHERE StockCode IN (
    SELECT StockCode 
	FROM OnlineRetail_No_Nulls 
	GROUP BY StockCode 
	HAVING COUNT(DISTINCT Description) > 1
)
GROUP BY StockCode, Description ORDER BY StockCode, Count DESC;

-- Use most frequent cleaned Description for each StockCode
WITH DescriptionRanked AS (
    SELECT StockCode, Description, COUNT(*) AS Count,
           ROW_NUMBER() OVER (PARTITION BY StockCode ORDER BY COUNT(*) DESC) AS rn
    FROM OnlineRetail_No_Nulls
    GROUP BY StockCode, Description
),
TopRank AS (
    SELECT StockCode, Description 
	FROM DescriptionRanked 
	WHERE rn = 1
),
-- Standardise comma spacing and remove double spaces
standardised AS (
    SELECT StockCode,
           LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(Description, ' , ', ','), ',', ', '), '  ', ' '))) AS CleanedDescription
    FROM TopRank
),
-- Join with table and remove non-product entries
FullTableDescription AS (
    SELECT 
        nn.InvoiceNo, 
		nn.StockCode, 
		s.CleanedDescription AS Description,
        nn.Quantity, 
		nn.InvoiceDate, 
		nn.UnitPrice, 
		nn.CustomerID, 
		nn.Country
    FROM OnlineRetail_No_Nulls AS nn
    LEFT JOIN standardised AS s 
		ON nn.StockCode = s.StockCode
    WHERE nn.StockCode NOT IN ('C2', 'POST', 'DOT', 'M', 'BANK CHARGES')
)
-- ============================================================
-- Step 8: Save result after cleaning and unifying Description
-- ============================================================

SELECT *
INTO OnlineRetail_Description_Cleaned
FROM FullTableDescription;

-- Remove duplicates introduced by cleaning
WITH Deduped AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country
        ORDER BY (SELECT NULL)) AS rn
    FROM OnlineRetail_Description_Cleaned
)
DELETE FROM Deduped WHERE rn > 1;

-- =================================================
-- Step 9: Continue column consistency checks
-- =================================================

-- InvoiceDate: Verify date range
SELECT 
	MIN(InvoiceDate) AS first_order, 
	MAX(InvoiceDate) AS last_order
FROM OnlineRetail_Description_Cleaned;

-- UnitPrice: Identify outliers
SELECT 
	MIN(UnitPrice) AS cheapest, 
	MAX(UnitPrice) AS most_expensive
FROM OnlineRetail_Description_Cleaned;

-- View most expensive transactions
SELECT *
FROM OnlineRetail_Description_Cleaned
ORDER BY UnitPrice DESC;

-- CustomerID: Ensure consistent format
SELECT DISTINCT LEN(CustomerID)
FROM OnlineRetail_Description_Cleaned;

-- Country: Inspect distinct values
SELECT DISTINCT Country
FROM OnlineRetail_Description_Cleaned;

-- Identify rows with unspecified country
SELECT *
FROM OnlineRetail_Description_Cleaned
WHERE Country = 'Unspecified';

-- ======================================
-- Step 10: Investigate Near-Duplicates
-- ======================================

-- Identify duplicate rows differing only by InvoiceNo
WITH DuplicateKeys AS (
    SELECT 
		--InvoiceNo,
		StockCode, 
		Description, 
		InvoiceDate, 
		Quantity, 
		CustomerID, 
		Country, 
		UnitPrice
    FROM OnlineRetail_Description_Cleaned
    GROUP BY StockCode, Description, InvoiceDate, Quantity, CustomerID, Country, UnitPrice
    HAVING COUNT(*) > 1
)

SELECT c.*
FROM OnlineRetail_Description_Cleaned c
JOIN DuplicateKeys d
  ON c.StockCode = d.StockCode
 AND c.Description = d.Description
 AND c.InvoiceDate = d.InvoiceDate
 AND c.Quantity = d.Quantity
 AND c.CustomerID = d.CustomerID
 AND c.Country = d.Country
 AND c.UnitPrice = d.UnitPrice
ORDER BY c.StockCode;

-- Check first instance of duplicate to check if I should remove them
SELECT *
FROM OnlineRetail_Description_Cleaned
WHERE InvoiceNo = '558776'
	OR InvoiceNo = '558775'
ORDER BY StockCode, InvoiceNo
-- Not all Quantites are identical. This rules out possibility of a duplicate order 

-- Identify duplicate rows differing only by Quantity 
WITH DuplicateKeys AS (
    SELECT 
		InvoiceNo, 
		StockCode, 
		Description, 
		InvoiceDate, 
		--Quantity,
		CustomerID, 
		Country, 
		UnitPrice
    FROM OnlineRetail_Description_Cleaned
    GROUP BY InvoiceNo, StockCode, Description, InvoiceDate, CustomerID, Country, UnitPrice
    HAVING COUNT(*) > 1
)

SELECT c.*
FROM OnlineRetail_Description_Cleaned c
JOIN DuplicateKeys d
  ON c.InvoiceNo = d.InvoiceNo
 AND c.StockCode = d.StockCode
 AND c.Description = d.Description
 AND c.InvoiceDate = d.InvoiceDate
-- AND c.Quantity = d.Quantity
 AND c.CustomerID = d.CustomerID
 AND c.Country = d.Country
 AND c.UnitPrice = d.UnitPrice
ORDER BY c.InvoiceNo, c.StockCode, c.UnitPrice;

-- Save results after aggregating Quantities
SELECT
    InvoiceNo,
    StockCode,
    Description,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country,
    SUM(Quantity) AS Quantity
INTO OnlineRetail_Aggregated
FROM OnlineRetail_Description_Cleaned
GROUP BY
    InvoiceNo,
    StockCode,
    Description,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country;

-- Identify duplicate rows differing only by InvoiceDates
WITH DuplicateKeys AS (
    SELECT 
		InvoiceNo, 
		StockCode, 
		Description, 
		--InvoiceDate,
		Quantity, 
		CustomerID, 
		Country, 
		UnitPrice
    FROM OnlineRetail_Aggregated
    GROUP BY InvoiceNo, StockCode, Description, Quantity, CustomerID, Country, UnitPrice
    HAVING COUNT(*) > 1
)
SELECT a.*
FROM OnlineRetail_Aggregated a
JOIN DuplicateKeys d
  ON a.InvoiceNo = d.InvoiceNo
 AND a.StockCode = d.StockCode
 AND a.Description = d.Description
 --AND c.InvoiceDate = d.InvoiceDate
 AND a.Quantity = d.Quantity
 AND a.CustomerID = d.CustomerID
 AND a.Country = d.Country
 AND a.UnitPrice = d.UnitPrice
ORDER BY a.InvoiceNo, a.StockCode, a.UnitPrice;

-- Check first instance of duplicate to check if I should remove them
SELECT *
FROM OnlineRetail_Description_Cleaned
WHERE InvoiceNo = '567183'
ORDER BY StockCode
-- Whole order has InvoiceDate spanning 2 minutes. 
-- Will not treat these as duplicates

-- Identify duplicate rows differing only by UnitPrice
WITH DuplicateKeys AS (
    SELECT 
		InvoiceNo, 
		StockCode, 
		Description, 
		InvoiceDate, 
		Quantity, 
		CustomerID, 
		Country
		--, UnitPrice
    FROM OnlineRetail_Aggregated
    GROUP BY InvoiceNo, StockCode, Description, InvoiceDate, Quantity, CustomerID, Country
    HAVING COUNT(*) > 1
)
SELECT a.*
FROM OnlineRetail_Aggregated a
JOIN DuplicateKeys d
  ON a.InvoiceNo = d.InvoiceNo
 AND a.StockCode = d.StockCode
 AND a.Description = d.Description
 AND a.InvoiceDate = d.InvoiceDate
 AND a.Quantity = d.Quantity
 AND a.CustomerID = d.CustomerID
 AND a.Country = d.Country
 -- AND a.UnitPrice = d.UnitPrice
ORDER BY a.InvoiceNo, a.StockCode, a.UnitPrice;
-- Unit prices are different but most probably to discounts

-- Identify duplicate rows differing only by StockCodes
WITH DuplicateKeys AS (
    SELECT 
		InvoiceNo, 
		--StockCode,
		Description, 
		InvoiceDate, 
		Quantity, 
		CustomerID, 
		Country, 
		UnitPrice
    FROM OnlineRetail_Aggregated
    GROUP BY InvoiceNo, Description, InvoiceDate, Quantity, CustomerID, Country, UnitPrice
    HAVING COUNT(*) > 1
)
SELECT a.*
FROM OnlineRetail_Aggregated a
JOIN DuplicateKeys d
  ON a.InvoiceNo = d.InvoiceNo
 -- AND a.StockCode = d.StockCode
 AND a.Description = d.Description
 AND a.InvoiceDate = d.InvoiceDate
 AND a.Quantity = d.Quantity
 AND a.CustomerID = d.CustomerID
 AND a.Country = d.Country
 AND a.UnitPrice = d.UnitPrice
ORDER BY a.InvoiceNo, a.StockCode, a.UnitPrice;
-- Different StockCode items can have the same description

-- ===============================================
-- Step 11: Confirm uniqueness of key columns
-- ===============================================

-- Validate that each order line is uniquely identified by InvoiceNo, StockCode, and UnitPrice
WITH Combinations AS (
    SELECT 
		InvoiceNo, 
		StockCode, 
		UnitPrice, 
		COUNT(*) AS CountDuplicates
    FROM OnlineRetail_Aggregated
    GROUP BY InvoiceNo, StockCode, UnitPrice
    HAVING COUNT(*) > 1
)
SELECT a.*
FROM OnlineRetail_Aggregated a
JOIN Combinations d
   ON a.InvoiceNo = d.InvoiceNo
  AND a.StockCode = d.StockCode
  AND a.UnitPrice = d.UnitPrice
ORDER BY a.InvoiceNo, a.StockCode, a.UnitPrice;
-- Some identical orders have timestamps within 1 minute. 

-- Grouping Quantity again but by InvoiceNo and StockCode only.
SELECT 
    InvoiceNo,
    StockCode,
    MIN(InvoiceDate) AS InvoiceDate,
    Description,
    SUM(Quantity) AS Quantity,
    UnitPrice,
    CustomerID,
    Country
INTO OnlineRetail_Clean
FROM OnlineRetail_Aggregated
GROUP BY 
    InvoiceNo, 
    StockCode,
    Description,
    UnitPrice,
    CustomerID,
    Country;

-- =====================================================================
-- Step 12: Final validation. Confirm uniqueness of primary identifiers
-- =====================================================================

WITH Combinations AS (
    SELECT InvoiceNo, StockCode, UnitPrice, COUNT(*) AS CountDuplicates
    FROM OnlineRetail_Clean
    GROUP BY InvoiceNo, StockCode, UnitPrice
    HAVING COUNT(*) > 1
)
SELECT c.*
FROM OnlineRetail_Clean c
JOIN Combinations d
   ON c.InvoiceNo = d.InvoiceNo
  AND c.StockCode = d.StockCode
  AND c.UnitPrice = d.UnitPrice
ORDER BY c.InvoiceNo, c.StockCode, c.UnitPrice;

-- A return of 0 rows indicates a successful clean, with uniquely identified records.
