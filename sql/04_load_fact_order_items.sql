-- ===============================================================================
-- Script Name: 04_load_fact_order_items.sql
-- Description: Standalone ETL Stored Procedure for silver.FactOrderItems.
--              Performs surrogate key resolution joins against Silver dimensions.
-- Layer:       Silver
-- Database:    SupplyChainDW
-- ===============================================================================

USE SupplyChainDW;
GO

CREATE OR ALTER PROCEDURE silver.usp_Load_FactOrderItems
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        PRINT '---------------------------------------------------';
        PRINT 'Starting execution: silver.usp_Load_FactOrderItems';
        PRINT '---------------------------------------------------';

        TRUNCATE TABLE silver.FactOrderItems;

        INSERT INTO silver.FactOrderItems (
            Order_Item_Id,
            Order_Id,
            Customer_Key,
            Product_Key,
            Location_Key,
            Order_Date_Key,
            Shipping_Date_Key,
            Customer_Id,
            Product_Card_Id,
            Order_Date,
            Shipping_Date,
            Type,
            Delivery_Status,
            Order_Status,
            Shipping_Mode,
            Days_For_Shipping_Real,
            Days_For_Shipment_Scheduled,
            Late_Delivery_Risk,
            Sales,
            Sales_Per_Customer,
            Order_Item_Quantity,
            Order_Item_Product_Price,
            Order_Item_Discount,
            Order_Item_Discount_Rate,
            Order_Item_Total,
            Order_Profit_Per_Order,
            Benefit_Per_Order,
            Order_Item_Profit_Ratio
        )
        SELECT 
            -- Natural Primary Keys
            TRY_CAST(TRIM(b.Order_Item_Id) AS INT) AS Order_Item_Id,
            TRY_CAST(TRIM(b.Order_Id) AS INT) AS Order_Id,

            -- Dimension Foreign Keys (Surrogate Key Lookups)
            c.Customer_Key,
            p.Product_Key,
            l.Location_Key,

            -- Date Foreign Keys (YYYYMMDD Integer Format)
            CAST(CONVERT(VARCHAR(8), TRY_CAST(TRIM(b.order_date_DateOrders) AS DATETIME2), 112) AS INT) AS Order_Date_Key,
            CAST(CONVERT(VARCHAR(8), TRY_CAST(TRIM(b.shipping_date_DateOrders) AS DATETIME2), 112) AS INT) AS Shipping_Date_Key,

            -- Business Natural Keys
            TRY_CAST(TRIM(b.Customer_Id) AS INT) AS Customer_Id,
            TRY_CAST(TRIM(b.Product_Card_Id) AS INT) AS Product_Card_Id,

            -- Order Timestamps
            TRY_CAST(TRIM(b.order_date_DateOrders) AS DATETIME2) AS Order_Date,
            TRY_CAST(TRIM(b.shipping_date_DateOrders) AS DATETIME2) AS Shipping_Date,

            -- Attributes
            NULLIF(TRIM(b.Type), '') AS Type,
            NULLIF(TRIM(b.Delivery_Status), '') AS Delivery_Status,
            NULLIF(TRIM(b.Order_Status), '') AS Order_Status,
            NULLIF(TRIM(b.Shipping_Mode), '') AS Shipping_Mode,
            TRY_CAST(TRIM(b.Days_for_shipping_real) AS INT) AS Days_For_Shipping_Real,
            TRY_CAST(TRIM(b.Days_for_shipment_scheduled) AS INT) AS Days_For_Shipment_Scheduled,
            TRY_CAST(TRIM(b.Late_delivery_risk) AS INT) AS Late_Delivery_Risk,

            -- Financial Metrics
            TRY_CAST(TRIM(b.Sales) AS DECIMAL(18,2)) AS Sales,
            TRY_CAST(TRIM(b.Sales_per_customer) AS DECIMAL(18,2)) AS Sales_Per_Customer,
            TRY_CAST(TRIM(b.Order_Item_Quantity) AS INT) AS Order_Item_Quantity,
            TRY_CAST(TRIM(b.Order_Item_Product_Price) AS DECIMAL(18,2)) AS Order_Item_Product_Price,
            TRY_CAST(TRIM(b.Order_Item_Discount) AS DECIMAL(18,2)) AS Order_Item_Discount,
            TRY_CAST(TRIM(b.Order_Item_Discount_Rate) AS DECIMAL(18,4)) AS Order_Item_Discount_Rate,
            TRY_CAST(TRIM(b.Order_Item_Total) AS DECIMAL(18,2)) AS Order_Item_Total,
            TRY_CAST(TRIM(b.Order_Profit_Per_Order) AS DECIMAL(18,2)) AS Order_Profit_Per_Order,
            TRY_CAST(TRIM(b.Benefit_per_order) AS DECIMAL(18,2)) AS Benefit_Per_Order,
            TRY_CAST(TRIM(b.Order_Item_Profit_Ratio) AS DECIMAL(18,4)) AS Order_Item_Profit_Ratio

        FROM bronze.DataCoSupplyChainRaw b

        -- 1. Customer Key Lookup
        LEFT JOIN silver.DimCustomer c 
            ON TRY_CAST(TRIM(b.Customer_Id) AS INT) = c.Customer_Id

        -- 2. Product Key Lookup
        LEFT JOIN silver.DimProduct p 
            ON TRY_CAST(TRIM(b.Product_Card_Id) AS INT) = p.Product_Card_Id

        -- 3. Location Key Lookup (Multi-column join with NULL safety)
        LEFT JOIN silver.DimLocation l 
            ON ISNULL(NULLIF(TRIM(b.Order_City), ''), '')    = ISNULL(l.Order_City, '')
           AND ISNULL(NULLIF(TRIM(b.Order_State), ''), '')   = ISNULL(l.Order_State, '')
           AND ISNULL(NULLIF(TRIM(b.Order_Country), ''), '') = ISNULL(l.Order_Country, '')
           AND ISNULL(NULLIF(TRIM(b.Order_Region), ''), '')  = ISNULL(l.Order_Region, '')
           AND ISNULL(NULLIF(TRIM(b.Market), ''), '')        = ISNULL(l.Market, '')

        WHERE b.Order_Item_Id IS NOT NULL 
          AND TRY_CAST(TRIM(b.Order_Item_Id) AS INT) IS NOT NULL;

        PRINT 'SUCCESS: silver.FactOrderItems populated with ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows.';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR in silver.usp_Load_FactOrderItems: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO