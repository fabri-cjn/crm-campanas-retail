-- =====================================================================
-- 03 — Uplift de la campaña 8, agregado  ->  rpt_uplift_campana_8
-- =====================================================================

CREATE OR REPLACE TABLE `procrm-514903.dunnhumby.rpt_uplift_campana_8` AS

WITH
-- Hogares alcanzados por cualquier otra campaña activa en la ventana
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
  b.grupo,
  b.ventana,
  COUNT(*) AS hogares,
  ROUND(SUM(COALESCE(g.gasto, 0))    / COUNT(*), 2) AS gasto_por_hogar,
  ROUND(SUM(COALESCE(g.canastas, 0)) / COUNT(*), 2) AS canastas_por_hogar,
  -- Ticket a nivel de grupo (gasto total del grupo / canastas totales)
  ROUND(SAFE_DIVIDE(SUM(COALESCE(g.gasto, 0)),
                    SUM(COALESCE(g.canastas, 0))), 2) AS ticket
FROM base b
LEFT JOIN gasto g
  ON b.household_id = g.household_id
 AND b.ventana      = g.ventana
GROUP BY b.grupo, b.ventana
ORDER BY b.grupo, b.ventana;

-- Control: 'hogares' debe dar 485 en las dos filas de expuesto
-- y 1,225 en las dos de control.