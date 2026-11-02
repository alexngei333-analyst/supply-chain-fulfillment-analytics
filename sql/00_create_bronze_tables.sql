IF OBJECT_ID ('bronze.DataCoSupplyChainRaw', 'U') IS NOT NULL
    DROP TABLE bronze.DataCoSupplyChainRaw;
GO

CREATE TABLE bronze.DataCoSupplyChainRaw (
    Type VARCHAR(MAX),
    Days_for_shipping_real      VARCHAR(MAX),
    Days_for_shipment_scheduled VARCHAR(MAX),
    Benefit_per_order           VARCHAR(MAX),
    Sales_per_customer          VARCHAR(MAX),
    Delivery_Status             VARCHAR(MAX),
    Late_delivery_risk          VARCHAR(MAX),
    Category_Id                 VARCHAR(MAX),
    Category_Name               VARCHAR(MAX),
    Customer_City               VARCHAR(MAX),
    Customer_Country            VARCHAR(MAX),
    Customer_Email              VARCHAR(MAX),
    Customer_Fname              VARCHAR(MAX),
    Customer_Id                 VARCHAR(MAX),
    Customer_Lname              VARCHAR(MAX),
    Customer_Password           VARCHAR(MAX),
    Customer_Segment            VARCHAR(MAX),
    Customer_State              VARCHAR(MAX),
    Customer_Street             VARCHAR(MAX),
    Customer_Zipcode            VARCHAR(MAX),
    Department_Id               VARCHAR(MAX),
    Department_Name             VARCHAR(MAX),
    Latitude                    VARCHAR(MAX),
    Longitude                   VARCHAR(MAX),
    Market                      VARCHAR(MAX),
    Order_City                  VARCHAR(MAX),
    Order_Country               VARCHAR(MAX),
    Order_Customer_Id           VARCHAR(MAX),
    order_date_DateOrders       VARCHAR(MAX),
    Order_Id                    VARCHAR(MAX),
    Order_Item_Cardprod_Id      VARCHAR(MAX),
    Order_Item_Discount         VARCHAR(MAX),
    Order_Item_Discount_Rate    VARCHAR(MAX),
    Order_Item_Id               VARCHAR(MAX),
    Order_Item_Product_Price    VARCHAR(MAX),
    Order_Item_Profit_Ratio     VARCHAR(MAX),
    Order_Item_Quantity         VARCHAR(MAX),
    Sales                       VARCHAR(MAX),
    Order_Item_Total            VARCHAR(MAX),
    Order_Profit_Per_Order      VARCHAR(MAX),
    Order_Region                VARCHAR(MAX),
    Order_State                 VARCHAR(MAX),
    Order_Status                VARCHAR(MAX),
    Order_Zipcode               VARCHAR(MAX),
    Product_Card_Id             VARCHAR(MAX),
    Product_Category_Id         VARCHAR(MAX),
    Product_Description         VARCHAR(MAX),
    Product_Image               VARCHAR(MAX),
    Product_Name                VARCHAR(MAX),
    Product_Price               VARCHAR(MAX),
    Product_Status              VARCHAR(MAX),
    shipping_date_DateOrders    VARCHAR(MAX),
    Shipping_Mode               VARCHAR(MAX),
    -- Metadata columns for tracking
    Ingestion_Timestamp     DATETIME DEFAULT GETDATE(),
    Source_File_Name        VARCHAR(255)
);

IF OBJECT_ID ('bronze.DataCoDescriptionRaw', 'U') IS NOT NULL
    DROP TABLE bronze.DataCoDescriptionRaw;
GO

CREATE TABLE bronze.DataCoDescriptionRaw (
    FIELDS          VARCHAR(MAX),
    DESCRIPTION     VARCHAR(MAX),
    -- Metadata columns for audit & lineage
    Ingestion_Timestamp     DATETIME DEFAULT GETDATE(),
    Source_File_Name        VARCHAR(255)
);
GO

IF OBJECT_ID ('bronze.DataCoTokenRaw', 'U') IS NOT NULL
    DROP TABLE bronze.DataCoTokenRaw;
GO

CREATE TABLE bronze.DataCoTokenRaw (
    Product     VARCHAR(MAX),
    Category    VARCHAR(MAX),
    Date        VARCHAR(MAX),
    Month       VARCHAR(MAX),
    Hour        VARCHAR(MAX),
    Department  VARCHAR(MAX),
    ip          VARCHAR(MAX),
    url         VARCHAR(MAX),
    -- Audit metadata columns
    Ingestion_Timestamp     DATETIME DEFAULT GETDATE(),
    Source_File_Name        VARCHAR(255)
);
GO