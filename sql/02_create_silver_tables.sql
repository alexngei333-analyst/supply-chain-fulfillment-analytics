
/*
===============================================================================
Script Name: ddl_silver.sql
Description: Consolidated DDL script for all Silver Layer Star Schema tables.
Layer:       Silver (Cleansed & Modeled Data)
Database:    SupplyChainDW
===============================================================================
*/
USE SupplyChainDW;
GO

-- -------------------------------------------------------------------------------
-- 0. Ensure Schema Exists
-- -------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
    EXEC('CREATE SCHEMA silver;');
GO

-- -------------------------------------------------------------------------------
-- 1. Drop Tables in Correct Dependency Order (Fact Table First, then Dimensions)
-- -------------------------------------------------------------------------------
IF OBJECT_ID('silver.FactOrderItems', 'U') IS NOT NULL DROP TABLE silver.FactOrderItems;
IF OBJECT_ID('silver.DimCustomer', 'U')    IS NOT NULL DROP TABLE silver.DimCustomer;
IF OBJECT_ID('silver.DimProduct', 'U')     IS NOT NULL DROP TABLE silver.DimProduct;
IF OBJECT_ID('silver.DimLocation', 'U')    IS NOT NULL DROP TABLE silver.DimLocation;
IF OBJECT_ID('silver.DimDate', 'U')        IS NOT NULL DROP TABLE silver.DimDate;
GO

PRINT 'Existing Silver tables safely dropped. Creating new schema definitions...';
GO


-- ===============================================================================
-- DIMENSION TABLES
-- ===============================================================================

-- -------------------------------------------------------------------------------
-- Table 1: silver.DimCustomer
-- Description: Customer profile details, segments, and personal addresses.
-- -------------------------------------------------------------------------------
CREATE TABLE silver.DimCustomer (
    Customer_Key      INT IDENTITY(1,1) PRIMARY KEY, -- Surrogate Key
    Customer_Id       INT NOT NULL,                  -- Business Key
    First_Name        NVARCHAR(100),
    Last_Name         NVARCHAR(100),
    Full_Name         NVARCHAR(200),
    Customer_Segment  NVARCHAR(50),
    City              NVARCHAR(100),
    State             NVARCHAR(50),
    Country           NVARCHAR(100),
    Zipcode           NVARCHAR(20),
    Street            NVARCHAR(255),
    Created_Timestamp DATETIME2 DEFAULT GETDATE()
);
GO


-- -------------------------------------------------------------------------------
-- Table 2: silver.DimProduct
-- Description: Product catalog, category hierarchies, departments, and list prices.
-- -------------------------------------------------------------------------------
CREATE TABLE silver.DimProduct (
    Product_Key      INT IDENTITY(1,1) PRIMARY KEY, -- Surrogate Key
    Product_Card_Id  INT NOT NULL,                  -- Business Key
    Product_Name     NVARCHAR(255),
    Product_Price    DECIMAL(18,2),
    Product_Image    NVARCHAR(500),
    Category_Id      INT,
    Category_Name    NVARCHAR(100),
    Department_Id    INT,
    Department_Name  NVARCHAR(100),
    Created_Timestamp DATETIME2 DEFAULT GETDATE()
);
GO


-- -------------------------------------------------------------------------------
-- Table 3: silver.DimLocation
-- Description: Unique order destination geography hierarchy (City, State, Market).
-- -------------------------------------------------------------------------------
CREATE TABLE silver.DimLocation (
    Location_Key      INT IDENTITY(1,1) PRIMARY KEY, -- Surrogate Key
    Order_City        NVARCHAR(100),
    Order_State       NVARCHAR(100),
    Order_Country     NVARCHAR(100),
    Order_Region      NVARCHAR(100),
    Market            NVARCHAR(100),
    Created_Timestamp DATETIME2 DEFAULT GETDATE()
);
GO


-- -------------------------------------------------------------------------------
-- Table 4: silver.DimDate
-- Description: Calendar date dimension supporting flexible time intelligence.
-- -------------------------------------------------------------------------------
CREATE TABLE silver.DimDate (
    Date_Key      INT PRIMARY KEY, -- YYYYMMDD Format (e.g., 20180131)
    Full_Date     DATE NOT NULL,
    Year          INT NOT NULL,
    Quarter       INT NOT NULL,
    Quarter_Name  VARCHAR(2) NOT NULL,
    Month         INT NOT NULL,
    Month_Name    VARCHAR(20) NOT NULL,
    Day_Of_Month  INT NOT NULL,
    Day_Of_Week   INT NOT NULL,
    Day_Name      VARCHAR(20) NOT NULL,
    Is_Weekend    BIT NOT NULL
);
GO


-- ===============================================================================
-- FACT TABLE
-- ===============================================================================

-- -------------------------------------------------------------------------------
-- Table 5: silver.FactOrderItems
-- Description: Transactional fact table containing individual line items,
--              financial performance metrics, and fulfillment SLA indicators.
-- -------------------------------------------------------------------------------
CREATE TABLE silver.FactOrderItems (
    Order_Item_Key               INT IDENTITY(1,1) PRIMARY KEY, -- Surrogate Key
    Order_Item_Id                INT NOT NULL,                  -- Natural Primary Key
    Order_Id                     INT NOT NULL,                  -- Natural Order ID
    
    -- Dimension Foreign Keys (Surrogate Links)
    Customer_Key                 INT NULL,
    Product_Key                  INT NULL,
    Location_Key                 INT NULL,
    Order_Date_Key               INT NULL,
    Shipping_Date_Key            INT NULL,

    -- Business Natural Keys (Backup / Lineage)
    Customer_Id                  INT NOT NULL,
    Product_Card_Id              INT NOT NULL,
    
    -- Order Timestamps
    Order_Date                   DATETIME2,
    Shipping_Date                DATETIME2,

    -- Order & Delivery Attributes
    Type                         NVARCHAR(50),
    Delivery_Status              NVARCHAR(100),
    Order_Status                 NVARCHAR(50),
    Shipping_Mode                NVARCHAR(50),
    Days_For_Shipping_Real       INT,
    Days_For_Shipment_Scheduled  INT,
    Late_Delivery_Risk           INT,

    -- Financial Measures & KPIs
    Sales                        DECIMAL(18,2),
    Sales_Per_Customer           DECIMAL(18,2),
    Order_Item_Quantity          INT,
    Order_Item_Product_Price     DECIMAL(18,2),
    Order_Item_Discount          DECIMAL(18,2),
    Order_Item_Discount_Rate     DECIMAL(18,4),
    Order_Item_Total             DECIMAL(18,2),
    Order_Profit_Per_Order       DECIMAL(18,2),
    Benefit_Per_Order            DECIMAL(18,2),
    Order_Item_Profit_Ratio      DECIMAL(18,4),

    -- Audit Column
    Created_Timestamp            DATETIME2 DEFAULT GETDATE()
);
GO

PRINT 'All Silver Layer tables created successfully!';
GO