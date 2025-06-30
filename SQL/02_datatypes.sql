/*
===========================================================
02_datatypes.sql
Purpose: Standardise column data types in OnlineRetail_Clean
Output: Updates the table with appropriate numeric formats
===========================================================
*/

-- Step 1: Inspect current data types
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'OnlineRetail_Clean';

-- Step 2: Check for non-numeric values before conversion
-- Ensures type conversion won't fail
SELECT * 
FROM OnlineRetail_Clean 
WHERE ISNUMERIC(InvoiceNo) = 0;

SELECT * 
FROM OnlineRetail_Clean 
WHERE ISNUMERIC(Quantity) = 0;

SELECT * 
FROM OnlineRetail_Clean
WHERE ISNUMERIC(CustomerID) = 0;

-- Step 3: Alter column types
-- Convert key columns to appropriate numeric types
ALTER TABLE OnlineRetail_Clean 
ALTER COLUMN InvoiceNo INT;

ALTER TABLE OnlineRetail_Clean 
ALTER COLUMN Quantity INT;

ALTER TABLE OnlineRetail_Clean 
ALTER COLUMN UnitPrice DECIMAL(10, 2);

ALTER TABLE OnlineRetail_Clean 
ALTER COLUMN CustomerID INT;

-- Step 4: Confirm updated data types
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'OnlineRetail_Clean';
