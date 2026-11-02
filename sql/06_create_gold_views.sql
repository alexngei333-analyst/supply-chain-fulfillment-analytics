-- ===============================================================================
-- Script Name: 06_create_gold_views.sql
-- Description: Creates business-facing Gold Layer analytical views for 
--              reporting and Power BI dashboard consumption.
-- Layer:       Gold (Analytics Mart)
-- Database:    SupplyChainDW
-- ===============================================================================

USE SupplyChainDW;
GO

-- -------------------------------------------------------------------------------
-- 0. Ensure Gold Schema Exists
-- -------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
    EXEC('CREATE SCHEMA gold;');
GO

-- ===============================================================================
-- VIEW 1: gold.vw_OrderFulfillment_Analytics
-- Description: Comprehensive order-line item view joining Facts and Dimensions
--              with pre-calculated operational fulfillment and financial KPIs.
-- ===============================================================================
CREATE OR ALTER VIEW gold.vw_OrderFulfillment_Analytics AS
SELECT 
    -- Transaction Identifiers
    f.Order_Item_Id,
    f.Order_Id,
    f.Order_Date,
    f.Shipping_Date,
    
    -- Date Attributes (Order Date)
    d_order.Year                      AS Order_Year,
    d_order.Quarter_Name              AS Order_Quarter,
    d_order.Month_Name                AS Order_Month,
    d_order.Day_Name                  AS Order_Day_Of_Week,
    d_order.Is_Weekend                AS Order_Is_Weekend,

    -- Customer Attributes
    c.Customer_Id,
    c.Full_Name                       AS Customer_Name,
    c.Customer_Segment,
    c.City                            AS Customer_City,
    c.State                           AS Customer_State,
    c.Country                         AS Customer_Country,

    -- Product Attributes
    p.Product_Card_Id                 AS Product_Id,
    p.Product_Name,
    p.Category_Name,
    p.Department_Name,
    p.Product_Price                   AS Catalog_Unit_Price,

    -- Destination Geography
    l.Order_City,
    l.Order_State,
    l.Order_Country,
    l.Order_Region,
    l.Market,

    -- Operational & Delivery Attributes
    f.Type                            AS Payment_Type,
    f.Order_Status,
    f.Delivery_Status,
    f.Shipping_Mode,
    f.Days_For_Shipping_Real,
    f.Days_For_Shipment_Scheduled,
    f.Late_Delivery_Risk,

    -- Pre-calculated Delivery SLA Indicator
    CASE 
        WHEN f.Days_For_Shipping_Real <= f.Days_For_Shipment_Scheduled THEN 'On-Time'
        ELSE 'Late'
    END AS Delivery_SLA_Performance,

    -- Financial Measures
    f.Order_Item_Quantity             AS Quantity_Ordered,
    f.Order_Item_Product_Price        AS Unit_Price,
    f.Sales                           AS Gross_Sales,
    f.Order_Item_Discount             AS Discount_Amount,
    f.Order_Item_Discount_Rate        AS Discount_Rate,
    f.Order_Item_Total                AS Net_Revenue,
    f.Order_Profit_Per_Order          AS Order_Profit,
    f.Benefit_Per_Order               AS Benefit_Amount,

    -- Pre-calculated Financial Indicators
    CASE 
        WHEN f.Sales > 0 THEN CAST((f.Order_Profit_Per_Order / f.Sales) * 100 AS DECIMAL(18,2))
        ELSE 0 
    END AS Profit_Margin_Percentage,

    CASE 
        WHEN f.Order_Profit_Per_Order < 0 THEN 1 
        ELSE 0 
    END AS Is_Loss_Making_Order

FROM silver.FactOrderItems f
LEFT JOIN silver.DimCustomer c     ON f.Customer_Key     = c.Customer_Key
LEFT JOIN silver.DimProduct p      ON f.Product_Key      = p.Product_Key
LEFT JOIN silver.DimLocation l     ON f.Location_Key     = l.Location_Key
LEFT JOIN silver.DimDate d_order   ON f.Order_Date_Key   = d_order.Date_Key
LEFT JOIN silver.DimDate d_ship    ON f.Shipping_Date_Key = d_ship.Date_Key;
GO


-- ===============================================================================
-- VIEW 2: gold.vw_Executive_KPI_Summary
-- Description: Pre-aggregated monthly executive summary for rapid high-level
--              revenue, profit margin, and late risk reporting.
-- ===============================================================================
CREATE OR ALTER VIEW gold.vw_Executive_KPI_Summary AS
SELECT 
    d.Year,
    d.Month,
    d.Month_Name,
    l.Market,
    p.Category_Name,
    COUNT(DISTINCT f.Order_Id)                        AS Total_Orders,
    COUNT(f.Order_Item_Id)                            AS Total_Line_Items,
    SUM(f.Sales)                                      AS Total_Gross_Sales,
    SUM(f.Order_Item_Total)                           AS Total_Net_Revenue,
    SUM(f.Order_Profit_Per_Order)                     AS Total_Profit,
    CAST(AVG(f.Order_Item_Discount_Rate) * 100 AS DECIMAL(18,2)) AS Avg_Discount_Rate_Pct,
    SUM(f.Late_Delivery_Risk)                         AS Total_Late_Deliveries,
    CAST((SUM(CAST(f.Late_Delivery_Risk AS FLOAT)) / COUNT(*)) * 100 AS DECIMAL(18,2)) AS Late_Delivery_Rate_Pct
FROM silver.FactOrderItems f
LEFT JOIN silver.DimProduct p  ON f.Product_Key    = p.Product_Key
LEFT JOIN silver.DimLocation l ON f.Location_Key   = l.Location_Key
LEFT JOIN silver.DimDate d     ON f.Order_Date_Key = d.Date_Key
GROUP BY 
    d.Year,
    d.Month,
    d.Month_Name,
    l.Market,
    p.Category_Name;
GO

PRINT 'Gold Layer views created successfully!';
GO