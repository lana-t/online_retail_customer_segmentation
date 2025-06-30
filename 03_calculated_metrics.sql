/*
=================================================================
03_calculated_metrics.sql
Purpose:
  Add useful transaction-level and customer-level metrics 
  for analysis and segmentation.

Outputs:
  - OnlineRetail_Transactions: adds TotalSpend, InvoiceYearMonth
  - Customer_RFM: Recency, Frequency, and Monetary per customer
=================================================================
*/

-- Step 1: Add transaction-level metrics
SELECT
    *,
    Quantity * UnitPrice AS TotalSpend,
    FORMAT(InvoiceDate, 'yyyy-MM') AS InvoiceYearMonth
INTO OnlineRetail_Transactions
FROM OnlineRetail_Clean;

-- Step 2: Calculate customer-level RFM metrics

-- Get most recent invoice date
WITH latest AS (
    SELECT MAX(InvoiceDate) AS latest_date
    FROM OnlineRetail_Clean
)

-- Compute Recency, Frequency, Monetary per customer
SELECT
    CustomerID,
    DATEDIFF(DAY, MAX(InvoiceDate), (SELECT latest_date FROM latest)) AS Recency,
    COUNT(DISTINCT InvoiceNo) AS Frequency,
    SUM(Quantity * UnitPrice) AS Monetary
INTO Customer_RFM
FROM OnlineRetail_Clean
GROUP BY CustomerID;