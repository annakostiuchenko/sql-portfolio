
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


SELECT COUNT(*)                     AS rows,
       COUNT(DISTINCT municipality) AS municipalities,
       MIN(year)                    AS first_year,
       MAX(year)                    AS last_year,
       COUNT(*) FILTER (WHERE avg_price IS NULL) AS missing_prices
FROM housing;

DROP TABLE IF EXISTS housing_current;
CREATE TABLE housing_current AS
SELECT h.*
FROM housing h
WHERE h.region_code IN (
    SELECT region_code FROM housing
    WHERE year = 2025 AND avg_price IS NOT NULL
);


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

SELECT year, avg_price
FROM housing_current
WHERE municipality = 'Diemen' AND year >= 2013
ORDER BY year;

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


DROP TABLE IF EXISTS housing_all;
CREATE TABLE housing_all AS
SELECT municipality AS region, 'Municipality' AS level, year, avg_price
FROM housing_current
UNION ALL
SELECT region, level, year, avg_price
FROM housing_regions;

COPY housing_current TO '/Users/anna/Downloads/nl_housing_municipalities.csv' (HEADER);
COPY growth          TO '/Users/anna/Downloads/nl_housing_growth.csv' (HEADER);
COPY housing_regions TO '/Users/anna/Downloads/nl_housing_regions.csv' (HEADER);
COPY housing_all     TO '/Users/anna/Downloads/nl_housing_all.csv' (HEADER);
