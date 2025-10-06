-- SQL Views for Bloomberg Project analytics (adjust schema/table names as needed)
USE BloombergProject;
GO

-- 1) View: Portfolio daily P&L (assumes Market_Data has daily close prices)
CREATE VIEW vw_Portfolio_DailyPL AS
SELECT
    ph.SnapshotDate AS [Date],
    ph.PortfolioID,
    ph.Ticker,
    ph.Quantity,
    ph.Avg_Cost,
    md.Close AS Market_Price,
    ph.Quantity * md.Close AS Market_Value,
    ph.Quantity * ph.Avg_Cost AS Cost_Value,
    ph.Quantity * md.Close - ph.Quantity * ph.Avg_Cost AS Unrealized_PL,
    CASE WHEN ph.Quantity * ph.Avg_Cost = 0 THEN NULL ELSE (ph.Quantity * md.Close - ph.Quantity * ph.Avg_Cost) / (ph.Quantity * ph.Avg_Cost) END AS ROI_Pct
FROM dbo.Portfolio_Holdings ph
LEFT JOIN dbo.Market_Data md
    ON ph.Ticker = md.Ticker AND ph.SnapshotDate = md.Date;
GO

-- 2) View: Sector Exposure (latest snapshot per portfolio)
CREATE VIEW vw_Sector_Exposure AS
SELECT
    ph.PortfolioID,
    md.Sector,
    SUM(ph.Quantity * md.Close) AS Market_Value,
    SUM(ph.Quantity * ph.Avg_Cost) AS Cost_Value,
    SUM(ph.Quantity * md.Close) - SUM(ph.Quantity * ph.Avg_Cost) AS Unrealized_PL,
    CASE WHEN SUM(ph.Quantity * ph.Avg_Cost)=0 THEN NULL ELSE (SUM(ph.Quantity * md.Close) - SUM(ph.Quantity * ph.Avg_Cost)) / SUM(ph.Quantity * ph.Avg_Cost) END AS ROI_Pct
FROM dbo.Portfolio_Holdings ph
JOIN dbo.Market_Data md ON ph.Ticker = md.Ticker AND ph.SnapshotDate = md.Date
GROUP BY ph.PortfolioID, md.Sector;
GO

-- 3) View: Top Movers for a given date (absolute return)
CREATE VIEW vw_TopMovers AS
SELECT
    md.Date,
    md.Ticker,
    md.Sector,
    md.Country,
    md.Open,
    md.Close,
    ((md.Close - md.Open)/NULLIF(md.Open,0))*100.0 AS ReturnPct,
    md.Volume
FROM dbo.Market_Data md;
GO

-- 4) View: Company Fundamentals (latest quarter per ticker)
CREATE VIEW vw_Company_Fundamentals AS
SELECT f.Ticker, f.Quarter, f.Revenue, f.Net_Income, f.EPS, f.PE_Ratio, f.PB_Ratio
FROM dbo.Financials f
INNER JOIN (
    SELECT Ticker, MAX(Quarter) AS LatestQuarter FROM dbo.Financials GROUP BY Ticker
) latest ON f.Ticker = latest.Ticker AND f.Quarter = latest.LatestQuarter;
GO

-- 5) View: FX Daily Change (percent)
CREATE VIEW vw_FX_Change AS
SELECT
    fd.Date,
    fd.CurrencyPair,
    fd.Open,
    fd.Close,
    ((fd.Close - fd.Open)/NULLIF(fd.Open,0))*100.0 AS ReturnPct
FROM dbo.Forex_Data fd;
GO
