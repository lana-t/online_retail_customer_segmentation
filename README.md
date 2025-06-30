# Online Retail RFM Segmentation & Sales Analysis

> This is a project summary and walkthrough. For the full analysis and business recommendations, see the [Final Report](Documentation/Final_Report.pdf).
<br/>

## Business Question
**How can a retail business use transaction history to better understand its customer base and allocate marketing efforts effectively?**

This project uses real-world transactional data to segment customers, identify revenue drivers, and uncover churn risks, helping businesses optimise marketing and retention strategies.

<br/>

## Project Overview

This case study uses the [Online Retail dataset](https://archive.ics.uci.edu/dataset/352/online+retail) and follows a complete end-to-end data analytics pipeline:

### Objectives:
- **Clean and prepare** transaction data using SQL
- **Create customer segments** using RFM (Recency, Frequency, Monetary) analysis
- Analyse **revenue concentration** and **churn risk**
- Identify **high-value customers** and **product performance trends**
- Visualise insights in a dynamic **Power BI dashboard**

<br/>

## Tools Used
- **SQL Server** – Data cleaning, transformation, and RFM calculations  
- **Power BI** – Data visualisation and interactive dashboards  
- **Microsoft Word** – Documentation and reporting

<br/>

## Folder Structure

- online_retail_customer_segmentation/

  - Data/
    - OnlineRetail.xlsx

  - SQL/
    - 01_clean.sql
    - 02_datatypes.sql
    - 03_calculated_metrics.sql
    - 04_customer_segments.sql
      
  - PowerBI/
    - OnlineRetail_Dashboard.pbix
    - OnlineRetail_Dashboard.pdf (static export)

  - Documentation/
    - SQL_Data_Cleaning_Documentation.pdf
    - Final_Report.pdf

  - README.md

<br/>

## Business Impact

This project demonstrates how RFM segmentation and transaction data can:
- Improve **customer retention**
- Enable **targeted marketing**
- Highlight **revenue concentration**
- Inform **promotional strategies**

<br/>


## Power BI Dashboard

A fully interactive dashboard includes:
- **Customer segmentation overview**
- **Revenue trends over time**
- **Churn risk highlights**
- **Top products and customer insights**

<br/>

## Key Insights

- **Champions (11.3%)** generate **50%+ of total revenue**  
- **Top 20 customers** contribute **~24% of total revenue**  
- **At Risk** customers make up 15% of the base and have not purchased in over 50 days  
- Revenue dips in summer and peaks in November, indicating seasonal trends  
- Most top-performing products are **low-cost, high-volume** items  
- Product demand is **diverse**, suggesting value in personalised marketing

<br/>

## Recommendations

- Focus retention strategies on Champions and Loyal Customers with **loyalty programme**
- Re-engage At Risk customers with **time-sensitive promotions**
- Introduce **account managers or VIP support** for top 20 high-value customers
- Personalise campaigns based on **previous product preferences**
- Align major marketing pushes with the **Autumn to early Winter peak**

<br/>

## Contact

Lana Trimmer<br/>
[LinkedIn](https://www.linkedin.com/in/lana-t-861549342/) • [Portfolio](#) • [Email](lana.trimmer32@gmail.com)



