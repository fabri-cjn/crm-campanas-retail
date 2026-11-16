-- =====================================================================
-- 02 — Tasa de conversión por campaña  ->  rpt_conversion_campanas
-- =====================================================================

CREATE OR REPLACE TABLE `procrm-514903.dunnhumby.rpt_conversion_campanas` AS

WITH
expuestos AS (
  SELECT
    campaign_id,
    COUNT(DISTINCT household_id) AS expuestos
  FROM `procrm-514903.dunnhumby.campaigns`
  GROUP BY campaign_id
),

convertidos AS (
  SELECT
    r.campaign_id,
    COUNT(DISTINCT r.household_id) AS convertidos
  FROM `procrm-514903.dunnhumby.coupon_redemptions` r
  JOIN `procrm-514903.dunnhumby.campaign_descriptions` d
    ON r.campaign_id = d.campaign_id
  WHERE r.redemption_date BETWEEN d.start_date AND d.end_date
  GROUP BY r.campaign_id
)

SELECT
  d.campaign_id,
  d.campaign_type,
  d.start_date,
  d.end_date,
  DATE_DIFF(d.end_date, d.start_date, DAY) AS dias,
  e.expuestos,
  COALESCE(c.convertidos, 0)               AS convertidos,
  ROUND(COALESCE(c.convertidos, 0) * 100 / e.expuestos, 2) AS tasa_conversion_pct
FROM `procrm-514903.dunnhumby.campaign_descriptions` d
JOIN      expuestos   e ON d.campaign_id = e.campaign_id
-- LEFT JOIN deliberado: una campaña sin redenciones debe aparecer
-- con 0, no desaparecer de la tabla.
LEFT JOIN convertidos c ON d.campaign_id = c.campaign_id
ORDER BY tasa_conversion_pct DESC;