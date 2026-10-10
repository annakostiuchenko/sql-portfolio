-- Dutch housing market, 1995–2025
-- Source: CBS StatLine table 83625NED (average sale price of existing homes)
-- Engine: DuckDB, run in DBeaver
-- Update the file paths to where you unzipped the CBS download.

-- 1. Join observations to region names; keep municipalities only
DROP TABLE IF EXISTS housing;
CREATE TABLE housing AS
SELECT
    r.Title                          AS municipality,
    o.RegioS                         AS region_code,
    CAST(LEFT(o.Perioden, 4) AS INT) AS year,
    TRY_CAST(o.Value AS DOUBLE)      AS avg_price
FROM read_csv_auto('/Users/anna/Downloads/83625NED-202602170000/Observations.csv') o
JOIN read_csv_auto('/Users/anna/Downloads/83625NED-202602170000/RegioSCodes.csv') r
  ON o.RegioS = r.Identifier
WHERE o.RegioS LIKE 'GM%';

-- Check: 728 municipalities incl. merged ones, 1995–2025, missing prices
SELECT COUNT(*)                     AS rows,
       COUNT(DISTINCT municipality) AS municipalities,
       MIN(year)                    AS first_year,
       MAX(year)                    AS last_year,
       COUNT(*) FILTER (WHERE avg_price IS NULL) AS missing_prices
FROM housing;

-- 2. Keep only municipalities that still exist (have a 2025 price) -> 342
DROP TABLE IF EXISTS housing_current;
CREATE TABLE housing_current AS
SELECT h.*
FROM housing h
WHERE h.region_code IN (
    SELECT region_code FROM housing
    WHERE year = 2025 AND avg_price IS NOT NULL
);

-- 3. Growth per municipality, using 3-year averages so one odd year
--    cannot distort the ranking (2013–15 vs 2023–25)
DROP TABLE IF EXISTS growth;
CREATE TABLE growth AS
WITH p AS (
    SELECT municipality,
           region_code,
           ROUND(AVG(avg_price) FILTER (WHERE year BETWEEN 2013 AND 2015), 0) AS price_2015,
           MAX(avg_price) FILTER (WHERE year = 2020)                         AS price_2020,
           ROUND(AVG(avg_price) FILTER (WHERE year BETWEEN 2023 AND 2025), 0) AS price_2025
    FROM housing_current
    GROUP BY municipality, region_code
)
SELECT *,
       price_2025 - price_2015                             AS change_eur,
       ROUND((price_2025 / price_2015 - 1) * 100, 1)       AS growth_pct,
       RANK() OVER (ORDER BY price_2025 / price_2015 DESC) AS growth_rank
FROM p;

-- Sanity check on the top riser: year by year
SELECT year, avg_price
FROM housing_current
WHERE municipality = 'Diemen' AND year >= 2013
ORDER BY year;

-- 4. National and province series for comparison
DROP TABLE IF EXISTS housing_regions;
CREATE TABLE housing_regions AS
SELECT
    r.Title                          AS region,
    CASE WHEN o.RegioS LIKE 'NL%' THEN 'Netherlands'
         WHEN o.RegioS LIKE 'PV%' THEN 'Province' END AS level,
    CAST(LEFT(o.Perioden, 4) AS INT) AS year,
    TRY_CAST(o.Value AS DOUBLE)      AS avg_price
FROM read_csv_auto('/Users/anna/Downloads/83625NED-202602170000/Observations.csv') o
JOIN read_csv_auto('/Users/anna/Downloads/83625NED-202602170000/RegioSCodes.csv') r
  ON o.RegioS = r.Identifier
WHERE o.RegioS LIKE 'NL%' OR o.RegioS LIKE 'PV%';

-- 5. One long table with all levels, for the municipality-vs-country chart
DROP TABLE IF EXISTS housing_all;
CREATE TABLE housing_all AS
SELECT municipality AS region, 'Municipality' AS level, year, avg_price
FROM housing_current
UNION ALL
SELECT region, level, year, avg_price
FROM housing_regions;

-- 6. Export for Tableau
COPY housing_current TO '/Users/anna/Downloads/nl_housing_municipalities.csv' (HEADER);
COPY growth          TO '/Users/anna/Downloads/nl_housing_growth.csv' (HEADER);
COPY housing_regions TO '/Users/anna/Downloads/nl_housing_regions.csv' (HEADER);
COPY housing_all     TO '/Users/anna/Downloads/nl_housing_all.csv' (HEADER);
