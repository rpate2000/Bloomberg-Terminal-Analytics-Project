-- SQL schema for Bloomberg Terminal Project
-- Create database (adjust name as needed)
CREATE DATABASE BloombergProject;
GO

USE BloombergProject;
GO

-- Market_Data table: daily prices
CREATE TABLE dbo.Market_Data (
    Date DATE NOT NULL,
    Ticker VARCHAR(16) NOT NULL,
    Open DECIMAL(18,4),
    Close DECIMAL(18,4),
    High DECIMAL(18,4),
    Low DECIMAL(18,4),
    Volume BIGINT,
    Sector VARCHAR(64),
    Country VARCHAR(64),
    CONSTRAINT PK_Market_Data PRIMARY KEY (Date, Ticker)
);
GO

-- Financials table: quarterly financial statements
CREATE TABLE dbo.Financials (
    Ticker VARCHAR(16) NOT NULL,
    Quarter DATE NOT NULL,
    Revenue DECIMAL(20,2),
    Net_Income DECIMAL(20,2),
    EPS DECIMAL(18,6),
    PE_Ratio DECIMAL(12,4),
    PB_Ratio DECIMAL(12,4),
    CONSTRAINT PK_Financials PRIMARY KEY (Ticker, Quarter)
);
GO

-- Portfolio_Holdings table: snapshots of holdings
CREATE TABLE dbo.Portfolio_Holdings (
    SnapshotDate DATE NOT NULL,
    PortfolioID INT NOT NULL DEFAULT(1),
    Ticker VARCHAR(16) NOT NULL,
    Quantity BIGINT,
    Avg_Cost DECIMAL(18,4),
    Market_Value DECIMAL(20,2),
    CONSTRAINT PK_Portfolio PRIMARY KEY (SnapshotDate, PortfolioID, Ticker)
);
GO

-- Forex_Data table
CREATE TABLE dbo.Forex_Data (
    Date DATE NOT NULL,
    CurrencyPair VARCHAR(16) NOT NULL,
    Open DECIMAL(18,6),
    Close DECIMAL(18,6),
    CONSTRAINT PK_Forex PRIMARY KEY (Date, CurrencyPair)
);
GO

-- Economic indicators table
CREATE TABLE dbo.Economic_Indicators (
    Date DATE NOT NULL,
    Country VARCHAR(64) NOT NULL,
    GDP DECIMAL(20,2),
    Inflation DECIMAL(8,4),
    Interest_Rate DECIMAL(8,4),
    CONSTRAINT PK_Econ PRIMARY KEY (Date, Country)
);
GO

-- Example: staging tables for bulk loads (optional)
CREATE TABLE dbo.Stg_Market_Data AS SELECT * FROM dbo.Market_Data WHERE 1=0;
CREATE TABLE dbo.Stg_Financials AS SELECT * FROM dbo.Financials WHERE 1=0;
GO

-- Bulk load example (SQL Server BULK INSERT) - adjust file path and format as required
-- BULK INSERT dbo.Stg_Market_Data
-- FROM 'C:\data\Market_Data.csv'
-- WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', KEEPNULLS);

-- After loading to staging: basic MERGE to production table (example)
/*
MERGE dbo.Market_Data AS target
USING dbo.Stg_Market_Data AS src
ON (target.Date = src.Date AND target.Ticker = src.Ticker)
WHEN MATCHED THEN
    UPDATE SET Open = src.Open, Close = src.Close, High = src.High, Low = src.Low, Volume = src.Volume, Sector = src.Sector, Country = src.Country
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Date, Ticker, Open, Close, High, Low, Volume, Sector, Country)
    VALUES (src.Date, src.Ticker, src.Open, src.Close, src.High, src.Low, src.Volume, src.Sector, src.Country);
*/
GO

-- Sample stored procedure: get top N movers for a date
CREATE PROCEDURE dbo.GetTopMovers
    @Date DATE,
    @TopN INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP(@TopN) Ticker, Open, Close, ((Close-Open)/NULLIF(Open,0))*100.0 AS ReturnPct, Volume, Sector
    FROM dbo.Market_Data
    WHERE Date = @Date
    ORDER BY ABS((Close-Open)/NULLIF(Open,0)) DESC;
END;
GO

-- Indexing suggestions
CREATE INDEX IX_Market_Date ON dbo.Market_Data(Date);
CREATE INDEX IX_Market_Ticker ON dbo.Market_Data(Ticker);
CREATE INDEX IX_Fin_Ticker ON dbo.Financials(Ticker);
GO
