-- =====================================================================
-- 04 — Uplift por hogar  ->  rpt_uplift_hogares_campana_8
-- =====================================================================

CREATE OR REPLACE TABLE `procrm-514903.dunnhumby.rpt_uplift_hogares_campana_8` AS

WITH
otras AS (
  SELECT DISTINCT c.household_id
  FROM `procrm-514903.dunnhumby.campaigns` c
  JOIN `procrm-514903.dunnhumby.campaign_descriptions` d
    ON c.campaign_id = d.campaign_id
  WHERE d.campaign_id != 8
    AND d.start_date <= DATE '2017-06-25'
    AND d.end_date   >= DATE '2017-03-21'
),

exp_8 AS (
  SELECT DISTINCT household_id
  FROM `procrm-514903.dunnhumby.campaigns`
  WHERE campaign_id = 8
),

grupos AS (
  SELECT
    u.household_id,
    IF(u.household_id IN (SELECT household_id FROM exp_8), 'expuesto', 'control') AS grupo
  FROM (SELECT DISTINCT household_id
        FROM `procrm-514903.dunnhumby.transactions`) u
  WHERE u.household_id NOT IN (SELECT household_id FROM otras)
),

base AS (
  SELECT g.household_id, g.grupo, ventana
  FROM grupos g
  CROSS JOIN UNNEST(['antes', 'durante']) AS ventana
),

gasto AS (
  SELECT
    household_id,
    IF(DATE(transaction_timestamp) <= DATE '2017-05-07', 'antes', 'durante') AS ventana,
    SUM(sales_value)          AS gasto,
    COUNT(DISTINCT basket_id) AS canastas
  FROM `procrm-514903.dunnhumby.transactions`
  WHERE DATE(transaction_timestamp) BETWEEN DATE '2017-03-21' AND DATE '2017-06-25'
  GROUP BY household_id, ventana
)

SELECT
  b.household_id,
  b.grupo,
  SUM(IF(b.ventana = 'antes',   COALESCE(g.gasto, 0), 0)) AS gasto_antes,
  SUM(IF(b.ventana = 'durante', COALESCE(g.gasto, 0), 0)) AS gasto_durante,
  SUM(IF(b.ventana = 'durante', COALESCE(g.gasto, 0), 0))
    - SUM(IF(b.ventana = 'antes', COALESCE(g.gasto, 0), 0)) AS diferencia
FROM base b
LEFT JOIN gasto g
  ON b.household_id = g.household_id
 AND b.ventana      = g.ventana
GROUP BY b.household_id, b.grupo;

