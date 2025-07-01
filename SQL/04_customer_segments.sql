/*
===========================================================
04_customer_segments.sql

Purpose:
Segment customers based on Recency, Frequency, and Monetary scores

Output:
Customer_Segments table with RFM scores and segment labels
===========================================================
*/

-- Step 1: Generate quartile-based R, F, M scores (1 = lowest, 4 = highest)
WITH RFM_Scored AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY Recency DESC) AS R_Score,  
        NTILE(4) OVER (ORDER BY Frequency) AS F_Score,
        NTILE(4) OVER (ORDER BY Monetary) AS M_Score
    FROM Customer_RFM
),

-- Step 2: Assign descriptive segment labels
Segmented AS (
    SELECT *,
        CASE
            WHEN R_Score = 4 AND F_Score = 4 AND M_Score = 4 THEN 'Champions'
            WHEN R_Score >= 3 AND F_Score >= 3 THEN 'Loyal Customers'
			WHEN R_Score >= 2 AND F_Score >= 2 AND M_Score = 4 THEN 'Big Spenders'
            WHEN R_Score <= 2 AND F_Score >= 2 THEN 'At Risk'
            WHEN R_Score = 1 AND F_Score = 1 AND M_Score = 1 THEN 'Lost'
            WHEN R_Score <= 2 AND F_Score <= 2 AND M_Score <= 2 THEN 'Needs Attention'
            ELSE 'Others'
        END AS Segment
    FROM RFM_Scored
)

-- Step 3: Save final segmentation
SELECT *
INTO Customer_Segments
FROM Segmented
