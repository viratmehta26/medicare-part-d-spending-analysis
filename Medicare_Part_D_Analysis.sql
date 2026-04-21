-- ============================================================
-- Medicare Part D Drug Spending Analysis (2019-2023)
-- Dataset: CMS Medicare Part D Spending by Drug
-- Author: Virat Mehta
-- ============================================================

CREATE DATABASE medicare_drug_spending;
USE medicare_drug_spending;

CREATE TABLE part_d_spending (
    Brnd_Name VARCHAR(255),
    Gnrc_Name VARCHAR(255),
    Tot_Mftr INT,
    Mftr_Name VARCHAR(255),
    Tot_Spndng_2019 DECIMAL(15,2),
    Tot_Dsg_Unts_2019 DECIMAL(15,2),
    Tot_Clms_2019 INT,
    Tot_Benes_2019 INT,
    Avg_Spnd_Per_Dsg_Unt_Wghtd_2019 DECIMAL(15,10),
    Avg_Spnd_Per_Clm_2019 DECIMAL(15,6),
    Avg_Spnd_Per_Bene_2019 DECIMAL(15,6),
    Outlier_Flag_2019 INT,
    Tot_Spndng_2020 DECIMAL(15,2),
    Tot_Dsg_Unts_2020 DECIMAL(15,2),
    Tot_Clms_2020 INT,
    Tot_Benes_2020 INT,
    Avg_Spnd_Per_Dsg_Unt_Wghtd_2020 DECIMAL(15,10),
    Avg_Spnd_Per_Clm_2020 DECIMAL(15,6),
    Avg_Spnd_Per_Bene_2020 DECIMAL(15,6),
    Outlier_Flag_2020 INT,
    Tot_Spndng_2021 DECIMAL(15,2),
    Tot_Dsg_Unts_2021 DECIMAL(15,2),
    Tot_Clms_2021 INT,
    Tot_Benes_2021 INT,
    Avg_Spnd_Per_Dsg_Unt_Wghtd_2021 DECIMAL(15,10),
    Avg_Spnd_Per_Clm_2021 DECIMAL(15,6),
    Avg_Spnd_Per_Bene_2021 DECIMAL(15,6),
    Outlier_Flag_2021 INT,
    Tot_Spndng_2022 DECIMAL(15,2),
    Tot_Dsg_Unts_2022 DECIMAL(15,2),
    Tot_Clms_2022 INT,
    Tot_Benes_2022 INT,
    Avg_Spnd_Per_Dsg_Unt_Wghtd_2022 DECIMAL(15,10),
    Avg_Spnd_Per_Clm_2022 DECIMAL(15,6),
    Avg_Spnd_Per_Bene_2022 DECIMAL(15,6),
    Outlier_Flag_2022 INT,
    Tot_Spndng_2023 DECIMAL(15,2),
    Tot_Dsg_Unts_2023 DECIMAL(15,2),
    Tot_Clms_2023 INT,
    Tot_Benes_2023 INT,
    Avg_Spnd_Per_Dsg_Unt_Wghtd_2023 DECIMAL(15,10),
    Avg_Spnd_Per_Clm_2023 DECIMAL(15,6),
    Avg_Spnd_Per_Bene_2023 DECIMAL(15,6),
    Outlier_Flag_2023 INT,
    Chg_Avg_Spnd_Per_Dsg_Unt_22_23 DECIMAL(15,10),
    CAGR_Avg_Spnd_Per_Dsg_Unt_19_23 DECIMAL(15,10)
);

LOAD DATA LOCAL INFILE '/path/to/your/DSD_PTD_RY25_P04_V10_DY23_BGM.csv'
INTO TABLE part_d_spending
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SELECT COUNT(*) AS total_rows FROM part_d_spending;

SELECT COUNT(*) AS overall_rows 
FROM part_d_spending 
WHERE Mftr_Name = 'Overall';

-- ============================================================
-- Query 1: Top 20 Drugs by Total Medicare Spending (2023)
-- Business Question: Where is the money going?
-- ============================================================
WITH ranked_drugs AS (
    SELECT 
        Brnd_Name,
        Gnrc_Name,
        Tot_Spndng_2023,
        Tot_Clms_2023,
        Tot_Benes_2023,
        Avg_Spnd_Per_Clm_2023,
        RANK() OVER (ORDER BY Tot_Spndng_2023 DESC) AS spend_rank
    FROM part_d_spending
    WHERE Mftr_Name = 'Overall'
      AND Tot_Spndng_2023 IS NOT NULL
)
SELECT 
    spend_rank,
    Brnd_Name,
    Gnrc_Name,
    FORMAT(Tot_Spndng_2023, 2) AS total_spending_2023,
    FORMAT(Tot_Clms_2023, 0) AS total_claims,
    FORMAT(Tot_Benes_2023, 0) AS total_beneficiaries,
    ROUND(Avg_Spnd_Per_Clm_2023, 2) AS avg_cost_per_claim
FROM ranked_drugs
WHERE spend_rank <= 20
ORDER BY spend_rank;

-- ============================================================
-- Query 2: Drugs with Highest Cost-Per-Unit Inflation (2022-2023)
-- Business Question: Which drugs are getting more expensive fastest?
-- Note: Filtered to drugs with >$1M in spending to exclude 
-- low-volume items where small absolute changes create 
-- misleadingly high percentages
-- ============================================================
SELECT 
    Brnd_Name,
    Gnrc_Name,
    ROUND(Avg_Spnd_Per_Dsg_Unt_Wghtd_2022, 4) AS cost_per_unit_2022,
    ROUND(Avg_Spnd_Per_Dsg_Unt_Wghtd_2023, 4) AS cost_per_unit_2023,
    ROUND(Chg_Avg_Spnd_Per_Dsg_Unt_22_23 * 100, 2) AS pct_change_yoy,
    FORMAT(Tot_Spndng_2023, 2) AS total_spending_2023,
    RANK() OVER (ORDER BY Chg_Avg_Spnd_Per_Dsg_Unt_22_23 DESC) AS inflation_rank
FROM part_d_spending
WHERE Mftr_Name = 'Overall'
  AND Tot_Spndng_2023 > 1000000
  AND Chg_Avg_Spnd_Per_Dsg_Unt_22_23 IS NOT NULL
ORDER BY Chg_Avg_Spnd_Per_Dsg_Unt_22_23 DESC
LIMIT 25;

-- ============================================================
-- Query 3: Price vs Volume - Cost Increase Decomposition
-- Business Question: Are costs rising because of price 
-- increases or higher utilization?
-- ============================================================
WITH cost_drivers AS (
    SELECT 
        Brnd_Name,
        Gnrc_Name,
        Tot_Spndng_2022,
        Tot_Spndng_2023,
        Tot_Clms_2022,
        Tot_Clms_2023,
        ROUND(((Tot_Spndng_2023 - Tot_Spndng_2022) / Tot_Spndng_2022) * 100, 2) AS spending_change_pct,
        ROUND(((Tot_Clms_2023 - Tot_Clms_2022) / Tot_Clms_2022) * 100, 2) AS volume_change_pct,
        ROUND(Chg_Avg_Spnd_Per_Dsg_Unt_22_23 * 100, 2) AS price_change_pct
    FROM part_d_spending
    WHERE Mftr_Name = 'Overall'
      AND Tot_Spndng_2022 > 0
      AND Tot_Clms_2022 > 0
      AND Tot_Spndng_2023 > 1000000
)
SELECT 
    Brnd_Name,
    Gnrc_Name,
    FORMAT(Tot_Spndng_2023, 2) AS spending_2023,
    spending_change_pct,
    volume_change_pct,
    price_change_pct,
    CASE 
        WHEN price_change_pct > 5 AND volume_change_pct < 5 THEN 'Price-Driven'
        WHEN volume_change_pct > 5 AND price_change_pct < 5 THEN 'Volume-Driven'
        WHEN price_change_pct > 5 AND volume_change_pct > 5 THEN 'Both'
        ELSE 'Stable'
    END AS cost_driver_type
FROM cost_drivers
ORDER BY Tot_Spndng_2023 DESC
LIMIT 100;

-- ============================================================
-- Query 4: Brand vs Generic Spending by Therapeutic Category
-- Business Question: Where are the biggest opportunities to 
-- shift from brand to generic?
-- ============================================================
WITH brand_generic AS (
    SELECT 
        Gnrc_Name,
        COUNT(DISTINCT Brnd_Name) AS num_brands,
        SUM(Tot_Spndng_2023) AS total_category_spend,
        SUM(CASE 
            WHEN Brnd_Name = Gnrc_Name THEN Tot_Spndng_2023 
            ELSE 0 
        END) AS generic_spend,
        SUM(CASE 
            WHEN Brnd_Name != Gnrc_Name THEN Tot_Spndng_2023 
            ELSE 0 
        END) AS brand_spend
    FROM part_d_spending
    WHERE Mftr_Name = 'Overall'
      AND Tot_Spndng_2023 IS NOT NULL
    GROUP BY Gnrc_Name
    HAVING total_category_spend > 5000000
)
SELECT 
    Gnrc_Name,
    num_brands,
    FORMAT(total_category_spend, 2) AS total_spend,
    FORMAT(brand_spend, 2) AS brand_spend,
    FORMAT(generic_spend, 2) AS generic_spend,
    ROUND((brand_spend / total_category_spend) * 100, 1) AS brand_share_pct,
    ROUND((generic_spend / total_category_spend) * 100, 1) AS generic_share_pct
FROM brand_generic
WHERE brand_spend > 0 AND generic_spend > 0
ORDER BY total_category_spend DESC
LIMIT 25;

-- ============================================================
-- Query 5: Manufacturer Concentration Analysis
-- Business Question: Which manufacturers dominate 
-- high-spend drug categories?
-- ============================================================
WITH mftr_spend AS (
    SELECT 
        Mftr_Name,
        COUNT(DISTINCT Gnrc_Name) AS num_drugs,
        SUM(Tot_Spndng_2023) AS total_mftr_spend,
        SUM(Tot_Clms_2023) AS total_mftr_claims,
        ROUND(AVG(Chg_Avg_Spnd_Per_Dsg_Unt_22_23) * 100, 2) AS avg_price_change_pct
    FROM part_d_spending
    WHERE Mftr_Name != 'Overall'
      AND Tot_Spndng_2023 IS NOT NULL
    GROUP BY Mftr_Name
)
SELECT 
    Mftr_Name,
    num_drugs,
    FORMAT(total_mftr_spend, 2) AS total_spending,
    FORMAT(total_mftr_claims, 0) AS total_claims,
    avg_price_change_pct,
    RANK() OVER (ORDER BY total_mftr_spend DESC) AS mftr_rank
FROM mftr_spend
ORDER BY total_mftr_spend DESC
LIMIT 20;

-- ============================================================
-- Query 6: 4-Year CAGR Outliers - Sustained Cost Growth
-- Business Question: Which drugs have been consistently 
-- getting more expensive, not just a one-year spike?
-- ============================================================
SELECT 
    Brnd_Name,
    Gnrc_Name,
    ROUND(CAGR_Avg_Spnd_Per_Dsg_Unt_19_23 * 100, 2) AS cagr_pct_19_23,
    ROUND(Chg_Avg_Spnd_Per_Dsg_Unt_22_23 * 100, 2) AS yoy_change_pct_22_23,
    FORMAT(Tot_Spndng_2019, 2) AS spending_2019,
    FORMAT(Tot_Spndng_2023, 2) AS spending_2023,
    ROUND(((Tot_Spndng_2023 - Tot_Spndng_2019) / Tot_Spndng_2019) * 100, 2) AS total_spending_change_pct
FROM part_d_spending
WHERE Mftr_Name = 'Overall'
  AND CAGR_Avg_Spnd_Per_Dsg_Unt_19_23 IS NOT NULL
  AND Tot_Spndng_2023 > 1000000
  AND Tot_Spndng_2019 > 0
ORDER BY CAGR_Avg_Spnd_Per_Dsg_Unt_19_23 DESC
LIMIT 25;