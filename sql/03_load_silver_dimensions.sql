-- ===============================================================================
-- Script Name: 03_load_silver_dimensions.sql
-- Description: ETL Stored Procedures to cleanse, standardize, and populate
--              all Silver Layer Dimension tables from raw Bronze staging.
-- Layer:       Silver
-- Database:    SupplyChainDW
-- ===============================================================================

USE SupplyChainDW;
GO

-- ===============================================================================
-- 1. PROCEDURE: silver.usp_Load_DimCustomer
-- Description: Cleanses customer names, segments, and address attributes.
--              Deduplicates customer records by Customer_Id.
-- ===============================================================================
CREATE OR ALTER PROCEDURE silver.usp_Load_DimCustomer
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        PRINT '---------------------------------------------------';
        PRINT 'Starting execution: silver.usp_Load_DimCustomer';
        PRINT '---------------------------------------------------';

        TRUNCATE TABLE silver.DimCustomer;

        WITH CleanedCustomers AS (
            SELECT 
                TRY_CAST(TRIM(Customer_Id) AS INT) AS Customer_Id,
                NULLIF(TRIM(Customer_Fname), '') AS First_Name,
                NULLIF(TRIM(Customer_Lname), '') AS Last_Name,
                CONCAT_WS(' ', NULLIF(TRIM(Customer_Fname), ''), NULLIF(TRIM(Customer_Lname), '')) AS Full_Name,
                NULLIF(TRIM(Customer_Segment), '') AS Customer_Segment,
                NULLIF(TRIM(Customer_City), '') AS City,
                NULLIF(TRIM(Customer_State), '') AS State,
                NULLIF(TRIM(Customer_Country), '') AS Country,
                NULLIF(TRIM(Customer_Zipcode), '') AS Zipcode,
                NULLIF(TRIM(Customer_Street), '') AS Street,
                ROW_NUMBER() OVER (
                    PARTITION BY TRY_CAST(TRIM(Customer_Id) AS INT) 
                    ORDER BY Ingestion_Timestamp DESC
                ) AS RowNum
            FROM bronze.DataCoSupplyChainRaw
            WHERE Customer_Id IS NOT NULL 
              AND TRY_CAST(TRIM(Customer_Id) AS INT) IS NOT NULL
        )
        INSERT INTO silver.DimCustomer (
            Customer_Id,
            First_Name,
            Last_Name,
            Full_Name,
            Customer_Segment,
            City,
            State,
            Country,
            Zipcode,
            Street
        )
        SELECT 
            Customer_Id,
            First_Name,
            Last_Name,
            Full_Name,
            Customer_Segment,
            City,
            State,
            Country,
            Zipcode,
            Street
        FROM CleanedCustomers
        WHERE RowNum = 1;

        PRINT 'SUCCESS: silver.DimCustomer populated with ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows.';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR in silver.usp_Load_DimCustomer: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO


-- ===============================================================================
-- 2. PROCEDURE: silver.usp_Load_DimProduct
-- Description: Extracts product catalog details, category hierarchies, and pricing.
--              Deduplicates products by Product_Card_Id.
-- ===============================================================================
CREATE OR ALTER PROCEDURE silver.usp_Load_DimProduct
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        PRINT '---------------------------------------------------';
        PRINT 'Starting execution: silver.usp_Load_DimProduct';
        PRINT '---------------------------------------------------';

        TRUNCATE TABLE silver.DimProduct;

        WITH CleanedProducts AS (
            SELECT 
                TRY_CAST(TRIM(Product_Card_Id) AS INT) AS Product_Card_Id,
                NULLIF(TRIM(Product_Name), '') AS Product_Name,
                TRY_CAST(TRIM(Product_Price) AS DECIMAL(18,2)) AS Product_Price,
                NULLIF(TRIM(Product_Image), '') AS Product_Image,
                TRY_CAST(TRIM(Category_Id) AS INT) AS Category_Id,
                NULLIF(TRIM(Category_Name), '') AS Category_Name,
                TRY_CAST(TRIM(Department_Id) AS INT) AS Department_Id,
                NULLIF(TRIM(Department_Name), '') AS Department_Name,
                ROW_NUMBER() OVER (
                    PARTITION BY TRY_CAST(TRIM(Product_Card_Id) AS INT) 
                    ORDER BY Ingestion_Timestamp DESC
                ) AS RowNum
            FROM bronze.DataCoSupplyChainRaw
            WHERE Product_Card_Id IS NOT NULL 
              AND TRY_CAST(TRIM(Product_Card_Id) AS INT) IS NOT NULL
        )
        INSERT INTO silver.DimProduct (
            Product_Card_Id,
            Product_Name,
            Product_Price,
            Product_Image,
            Category_Id,
            Category_Name,
            Department_Id,
            Department_Name
        )
        SELECT 
            Product_Card_Id,
            Product_Name,
            Product_Price,
            Product_Image,
            Category_Id,
            Category_Name,
            Department_Id,
            Department_Name
        FROM CleanedProducts
        WHERE RowNum = 1;

        PRINT 'SUCCESS: silver.DimProduct populated with ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows.';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR in silver.usp_Load_DimProduct: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO


-- ===============================================================================
-- 3. PROCEDURE: silver.usp_Load_DimLocation
-- Description: Extracts unique order destination geographic combinations
--              (City, State, Country, Region, Market) from raw orders.
-- ===============================================================================
CREATE OR ALTER PROCEDURE silver.usp_Load_DimLocation
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        PRINT '---------------------------------------------------';
        PRINT 'Starting execution: silver.usp_Load_DimLocation';
        PRINT '---------------------------------------------------';

        TRUNCATE TABLE silver.DimLocation;

        WITH CleanedLocations AS (
            SELECT 
                NULLIF(TRIM(Order_City), '') AS Order_City,
                NULLIF(TRIM(Order_State), '') AS Order_State,
                NULLIF(TRIM(Order_Country), '') AS Order_Country,
                NULLIF(TRIM(Order_Region), '') AS Order_Region,
                NULLIF(TRIM(Market), '') AS Market,
                ROW_NUMBER() OVER (
                    PARTITION BY 
                        NULLIF(TRIM(Order_City), ''),
                        NULLIF(TRIM(Order_State), ''),
                        NULLIF(TRIM(Order_Country), ''),
                        NULLIF(TRIM(Order_Region), ''),
                        NULLIF(TRIM(Market), '')
                    ORDER BY Ingestion_Timestamp DESC
                ) AS RowNum
            FROM bronze.DataCoSupplyChainRaw
            WHERE Order_City IS NOT NULL OR Order_Country IS NOT NULL
        )
        INSERT INTO silver.DimLocation (
            Order_City,
            Order_State,
            Order_Country,
            Order_Region,
            Market
        )
        SELECT 
            Order_City,
            Order_State,
            Order_Country,
            Order_Region,
            Market
        FROM CleanedLocations
        WHERE RowNum = 1;

        PRINT 'SUCCESS: silver.DimLocation populated with ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows.';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR in silver.usp_Load_DimLocation: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO


-- ===============================================================================
-- 4. PROCEDURE: silver.usp_Load_DimDate
-- Description: Generates a calendar dimension table covering 2015 to 2022.
--              Calculates Year, Quarter, Month, Day, and Weekend flags.
-- ===============================================================================
CREATE OR ALTER PROCEDURE silver.usp_Load_DimDate
    @StartDate DATE = '2015-01-01',
    @EndDate   DATE = '2022-12-31'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        PRINT '---------------------------------------------------';
        PRINT 'Starting execution: silver.usp_Load_DimDate';
        PRINT '---------------------------------------------------';

        TRUNCATE TABLE silver.DimDate;

        WITH DateSequence AS (
            SELECT @StartDate AS CalendarDate
            UNION ALL
            SELECT DATEADD(DAY, 1, CalendarDate)
            FROM DateSequence
            WHERE CalendarDate < @EndDate
        )
        INSERT INTO silver.DimDate (
            Date_Key,
            Full_Date,
            Year,
            Quarter,
            Quarter_Name,
            Month,
            Month_Name,
            Day_Of_Month,
            Day_Of_Week,
            Day_Name,
            Is_Weekend
        )
        SELECT 
            CAST(CONVERT(VARCHAR(8), CalendarDate, 112) AS INT) AS Date_Key,
            CalendarDate AS Full_Date,
            DATEPART(YEAR, CalendarDate) AS Year,
            DATEPART(QUARTER, CalendarDate) AS Quarter,
            'Q' + CAST(DATEPART(QUARTER, CalendarDate) AS VARCHAR(1)) AS Quarter_Name,
            DATEPART(MONTH, CalendarDate) AS Month,
            DATENAME(MONTH, CalendarDate) AS Month_Name,
            DATEPART(DAY, CalendarDate) AS Day_Of_Month,
            DATEPART(WEEKDAY, CalendarDate) AS Day_Of_Week,
            DATENAME(WEEKDAY, CalendarDate) AS Day_Name,
            CASE WHEN DATEPART(WEEKDAY, CalendarDate) IN (1, 7) THEN 1 ELSE 0 END AS Is_Weekend
        FROM DateSequence
        OPTION (MAXRECURSION 10000);

        PRINT 'SUCCESS: silver.DimDate populated with ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows.';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR in silver.usp_Load_DimDate: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO