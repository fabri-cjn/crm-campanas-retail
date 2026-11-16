-- =====================================================================
-- 05 — Serie semanal  ->  rpt_serie_semanal_campana_8
-- =====================================================================

CREATE OR REPLACE TABLE `procrm-514903.dunnhumby.rpt_serie_semanal_campana_8` AS

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

semanas AS (
  SELECT DISTINCT DATE_TRUNC(DATE(transaction_timestamp), WEEK) AS semana
  FROM `procrm-514903.dunnhumby.transactions`
  WHERE DATE(transaction_timestamp) BETWEEN DATE '2017-03-21' AND DATE '2017-06-25'
),

-- Cada hogar en cada semana, haya comprado o no
base AS (
  SELECT g.household_id, g.grupo, s.semana
  FROM grupos g
  CROSS JOIN semanas s
),

gasto AS (
  SELECT
    household_id,
    DATE_TRUNC(DATE(transaction_timestamp), WEEK) AS semana,
    SUM(sales_value)          AS gasto,
    COUNT(DISTINCT basket_id) AS canastas
  FROM `procrm-514903.dunnhumby.transactions`
  WHERE DATE(transaction_timestamp) BETWEEN DATE '2017-03-21' AND DATE '2017-06-25'
  GROUP BY household_id, semana
)

SELECT
  b.semana,
  b.grupo,
  b.semana >= DATE '2017-05-08' AS en_campana,
  COUNT(*) AS hogares,
  ROUND(SUM(COALESCE(g.gasto, 0)) / COUNT(*), 2) AS gasto_por_hogar,
  ROUND(SAFE_DIVIDE(SUM(COALESCE(g.gasto, 0)),
                    SUM(COALESCE(g.canastas, 0))), 2) AS ticket
FROM base b
LEFT JOIN gasto g
  ON b.household_id = g.household_id
 AND b.semana       = g.semana
GROUP BY b.semana, b.grupo, en_campana
ORDER BY b.semana, b.grupo;