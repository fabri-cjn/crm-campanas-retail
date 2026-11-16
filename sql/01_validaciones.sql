
-- 01 — Validaciones previas al análisis


-- ---------------------------------------------------------------------
-- 1.1  Grano de la tabla de exposición
-- ---------------------------------------------------------------------
SELECT
  campaign_id,
  COUNT(*)                     AS filas,
  COUNT(DISTINCT household_id) AS hogares
FROM `procrm-514903.dunnhumby.campaigns`
GROUP BY campaign_id
ORDER BY hogares DESC;


-- ---------------------------------------------------------------------
-- 1.2  Contaminación del grupo de comparación
-- ---------------------------------------------------------------------
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
universo AS (
  SELECT DISTINCT household_id
  FROM `procrm-514903.dunnhumby.transactions`
)
SELECT
  IF(e.household_id IS NULL, 'no expuesto a 8', 'expuesto a 8') AS grupo,
  COUNT(*)                                                      AS hogares,
  COUNTIF(o.household_id IS NOT NULL)                           AS con_otra_campana,
  ROUND(COUNTIF(o.household_id IS NOT NULL) * 100 / COUNT(*), 1) AS pct
FROM universo u
LEFT JOIN exp_8 e ON u.household_id = e.household_id
LEFT JOIN otras o ON u.household_id = o.household_id
GROUP BY grupo;


-- ---------------------------------------------------------------------
-- 1.3  Ventana de atribución
-- ---------------------------------------------------------------------
SELECT
  COUNT(*)                                                             AS total,
  COUNTIF(r.redemption_date NOT BETWEEN d.start_date AND d.end_date)   AS fuera_de_ventana
FROM `procrm-514903.dunnhumby.coupon_redemptions` r
JOIN `procrm-514903.dunnhumby.campaign_descriptions` d
  ON r.campaign_id = d.campaign_id;