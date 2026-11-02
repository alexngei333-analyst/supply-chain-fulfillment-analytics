-- ===============================================================================
-- Script Name: 05_master_silver_pipeline.sql
-- Description: Master Orchestration Stored Procedure for the Silver Layer.
--              Executes all Dimension and Fact ETL procedures in strict dependency order.
-- Layer:       Silver
-- Database:    SupplyChainDW
-- ===============================================================================

USE SupplyChainDW;
GO

CREATE OR ALTER PROCEDURE silver.usp_Load_All_Silver_Tables
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PipelineStartTime DATETIME2 = GETDATE();
    DECLARE @PipelineEndTime   DATETIME2;
    DECLARE @TotalSeconds       INT;

    BEGIN TRY
        PRINT '===================================================================';
        PRINT '        STARTING SILVER LAYER MASTER PIPELINE                      ';
        PRINT '        Start Time: ' + CONVERT(VARCHAR(30), @PipelineStartTime, 120);
        PRINT '===================================================================';

        -- -------------------------------------------------------------------
        -- STAGE 1: Load Dimension Tables (Master Lookups)
        -- -------------------------------------------------------------------
        PRINT '>>> [1/5] Executing silver.usp_Load_DimCustomer...';
        EXEC silver.usp_Load_DimCustomer;

        PRINT '>>> [2/5] Executing silver.usp_Load_DimProduct...';
        EXEC silver.usp_Load_DimProduct;

        PRINT '>>> [3/5] Executing silver.usp_Load_DimLocation...';
        EXEC silver.usp_Load_DimLocation;

        PRINT '>>> [4/5] Executing silver.usp_Load_DimDate...';
        EXEC silver.usp_Load_DimDate @StartDate = '2015-01-01', @EndDate = '2022-12-31';

        -- -------------------------------------------------------------------
        -- STAGE 2: Load Fact Table (Requires all Dimensions to exist first)
        -- -------------------------------------------------------------------
        PRINT '>>> [5/5] Executing silver.usp_Load_FactOrderItems...';
        EXEC silver.usp_Load_FactOrderItems;

        -- -------------------------------------------------------------------
        -- Pipeline Summary & Execution Timing
        -- -------------------------------------------------------------------
        SET @PipelineEndTime = GETDATE();
        SET @TotalSeconds = DATEDIFF(SECOND, @PipelineStartTime, @PipelineEndTime);

        PRINT '===================================================================';
        PRINT '        SILVER LAYER PIPELINE COMPLETED SUCCESSFULLY!              ';
        PRINT '        End Time:       ' + CONVERT(VARCHAR(30), @PipelineEndTime, 120);
        PRINT '        Total Duration: ' + CAST(@TotalSeconds AS VARCHAR(10)) + ' second(s)';
        PRINT '===================================================================';

    END TRY
    BEGIN CATCH
        SET @PipelineEndTime = GETDATE();
        PRINT '===================================================================';
        PRINT '        CRITICAL ERROR: SILVER LAYER PIPELINE FAILED!             ';
        PRINT '        Failed Procedure: ' + ISNULL(ERROR_PROCEDURE(), 'Master Script');
        PRINT '        Error Line:       ' + CAST(ERROR_LINE() AS VARCHAR(10));
        PRINT '        Error Message:    ' + ERROR_MESSAGE();
        PRINT '===================================================================';
        
        THROW;
    END CATCH
END;
GO