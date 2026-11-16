CREATE OR REPLACE TABLE `procrm-514903.dunnhumby.rpt_uplift_resumen` AS
WITH p AS (
  SELECT
    MAX(IF(grupo='expuesto' AND ventana='durante', gasto_por_hogar, NULL)) AS e_dur,
    MAX(IF(grupo='expuesto' AND ventana='antes',   gasto_por_hogar, NULL)) AS e_ant,
    MAX(IF(grupo='control'  AND ventana='durante', gasto_por_hogar, NULL)) AS c_dur,
    MAX(IF(grupo='control'  AND ventana='antes',   gasto_por_hogar, NULL)) AS c_ant
  FROM `procrm-514903.dunnhumby.rpt_uplift_campana_8`
)
SELECT
  ROUND(e_dur - e_ant, 2)                       AS cambio_expuesto,
  ROUND(c_dur - c_ant, 2)                       AS cambio_control,
  ROUND((e_dur - e_ant) - (c_dur - c_ant), 2)   AS uplift_gasto,
  ROUND((c_dur - c_ant) * 100 / (e_dur - e_ant), 1) AS pct_no_atribuible
FROM p;