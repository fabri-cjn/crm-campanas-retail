# Medición del efecto incremental de campañas de marketing directo en retail

**Análisis de uplift con grupo de comparación sobre datos transaccionales reales**

Proyecto de portafolio · Noviembre 2026
Herramientas: SQL (Google BigQuery), Looker Studio, Microsoft Excel, R

**Dashboard interactivo:** `https://datastudio.google.com/reporting/4a26fa19-c433-4f92-8d8d-1f757b48c914`

---

## Resumen

El presente trabajo evalúa si una campaña de marketing directo con cupones genera compras incrementales, o si únicamente captura compras que habrían ocurrido de todos modos. Se analizaron 1,469,307 transacciones correspondientes a 2,469 hogares de una cadena de supermercados estadounidense durante el año 2017.

Mediante un diseño de diferencias en diferencias con grupo de comparación, se determinó que el gasto de los hogares expuestos a la campaña analizada se incrementó en USD 11.09 por hogar, mientras que el de los hogares no expuestos aumentó USD 10.84 en el mismo periodo. El efecto atribuible a la campaña asciende a USD 0.25 por hogar, magnitud que no resulta estadísticamente distinguible de cero (prueba t de Welch, p = 0.9794).

Se concluye que el 98% del incremento observado en el grupo expuesto corresponde a variación estacional y no al efecto de la campaña.

---

## 1. Objetivos

### 1.1 Objetivo general

Determinar el efecto incremental de una campaña de marketing directo sobre el gasto de los hogares expuestos, aislando el componente atribuible a la campaña del que corresponde a factores externos.

### 1.2 Objetivos específicos

1. Construir un grupo de comparación válido a partir de hogares no expuestos a la campaña.
2. Cuantificar la variación del gasto, la frecuencia de visita y el ticket promedio en ambos grupos, antes y durante la campaña.
3. Contrastar estadísticamente la diferencia observada entre grupos.
4. Caracterizar el desempeño de los tres tipos de campaña presentes en el conjunto de datos.
5. Diseñar los controles de calidad aplicables a una base de envío previa al lanzamiento de una campaña.

---

## 2. Datos

Se utilizó el conjunto de datos *The Complete Journey*, de dunnhumby, accedido a través del paquete `completejourney` del repositorio CRAN (licencia CC0). El conjunto registra el comportamiento de compra de 2,469 hogares con tarjeta de fidelidad de una cadena de supermercados de los Estados Unidos durante un periodo de un año, con fechas ancladas en 2017.

| Tabla | Registros | Contenido |
| --- | --- | --- |
| `transactions` | 1,469,307 | línea de producto por boleta: hogar, canasta, fecha, monto |
| `campaigns` | 6,589 | asignación hogar–campaña (exposición) |
| `campaign_descriptions` | 27 | tipo y vigencia de cada campaña |
| `coupon_redemptions` | 2,102 | redención de cupón, con fecha (conversión) |

La particularidad que hace a este conjunto apropiado para el objetivo planteado es la existencia de una tabla de exposición. Esta permite identificar no solo al hogar que recibió la comunicación y compró, sino también al que la recibió y no compró, condición indispensable para calcular tasas de conversión y efectos incrementales.

Las cuatro tablas fueron cargadas a Google BigQuery. Todas las cifras monetarias se expresan en dólares estadounidenses.

### 2.1 Incidencia detectada en la carga

Durante la carga se identificaron dos registros de `transactions` (de 1,469,307) cuyos identificadores figuraban en notación científica dentro del propio paquete de origen —`"9e+05"` y `"4.0128e+10"`, resultado de aplicar `as.character()` sobre valores de doble precisión—, lo que impedía su conversión al tipo INT64 de destino. Se corrigieron en R mediante `sprintf("%.0f", as.numeric(.x))` aplicado a la totalidad de las columnas identificadoras antes de la exportación.

---

## 3. Metodología

### 3.1 Definiciones operativas

Las siguientes definiciones se establecieron previamente al cálculo y se mantuvieron constantes a lo largo del análisis:

| Concepto | Definición adoptada | Fundamento |
| --- | --- | --- |
| Ventana de atribución | la redención debe ocurrir entre `start_date` y `end_date` de la campaña | la vigencia la determina el dato; se verificó que 0 de 2,102 redenciones ocurren fuera de ella |
| Ticket | gasto total del grupo entre número total de canastas del grupo | medida agregada, comparable entre ventanas temporales |
| Frecuencia | canastas distintas (`basket_id`) por hogar | la canasta constituye la visita; el registro original está a nivel de producto |
| Unidad de análisis | el hogar | la tarjeta de fidelidad se emite por hogar y la campaña se dirige a esa unidad |
| Denominador | la totalidad de hogares del grupo | un hogar sin compras se computa como cero y no se excluye del promedio |

Cabe precisar que la variable `sales_value` corresponde al monto percibido por el minorista, neto de descuentos por cupón y por tarjeta de fidelidad; no equivale al precio pagado por el cliente.

### 3.2 Selección de la campaña

Se seleccionó la **campaña 8** entre las tres de mayor alcance del conjunto (campañas 8, 13 y 18, todas de tipo A, con aproximadamente 1,100 hogares cada una). Las 24 campañas restantes presentan entre 12 y 361 hogares expuestos; con tamaños de esa magnitud, cualquier diferencia observada resulta indistinguible del ruido muestral.

| Parámetro | Valor |
| --- | --- |
| Campaña | 8 (tipo A) |
| Ventana de campaña | 2017-05-08 a 2017-06-25 (48 días) |
| Ventana previa | 2017-03-21 a 2017-05-07 (48 días) |

La campaña 18 fue descartada como caso principal por extenderse del 30 de octubre al 24 de diciembre, periodo que coincide íntegramente con la temporada navideña, durante la cual el gasto en supermercados se incrementa por factores ajenos a cualquier acción de marketing.

Las campañas de tipo A son personalizadas: cada hogar recibió dieciséis cupones seleccionados en función de su comportamiento de compra previo. Esta característica introduce sesgo de selección y condiciona la interpretación de los resultados.

### 3.3 Diseño del grupo de comparación

Previamente a la medición se verificó si ambos grupos recibían estímulos adicionales durante la ventana de análisis (21 de marzo a 25 de junio):

| Grupo | Hogares | Con otra campaña activa | Proporción |
| --- | --- | --- | --- |
| Expuesto a la campaña 8 | 1,076 | 591 | 54.9% |
| No expuesto a la campaña 8 | 1,393 | 168 | 12.1% |

El desbalance observado es de 4.5 a 1. Los hogares incluidos en la campaña 8 reciben considerablemente más comunicaciones que el resto, consecuencia directa del mecanismo de segmentación de las campañas tipo A, que selecciona reiteradamente a los hogares de mayor valor. En consecuencia, una comparación contra ese grupo habría capturado el efecto conjunto de múltiples campañas y no el de la campaña bajo análisis.

Se restringió por tanto la muestra a hogares expuestos exclusivamente a la campaña 8 y a hogares sin ninguna campaña activa durante la ventana:

| Grupo | Hogares |
| --- | --- |
| Expuesto (únicamente campaña 8) | 485 |
| Control (sin campañas) | 1,225 |

---

## 4. Resultados

### 4.1 Efecto sobre el gasto, la frecuencia y el ticket

| Indicador | Expuesto (n = 485) | Control (n = 1,225) | Efecto incremental |
| --- | --- | --- | --- |
| Gasto por hogar | 313.04 → 324.13 (+11.09) | 109.30 → 120.14 (+10.84) | **+0.25** |
| Canastas por hogar | 10.99 → 11.57 (+0.58) | 4.12 → 4.54 (+0.42) | +0.16 |
| Ticket | 28.48 → 28.02 (−0.46) | 26.52 → 26.46 (−0.06) | −0.40 |

El gasto de los hogares expuestos se incrementó en 11.09 dólares durante la campaña. El de los hogares no expuestos lo hizo en 10.84 dólares en idéntico periodo. En consecuencia, el 98% del incremento observado se habría producido igualmente en ausencia de la campaña, y corresponde a la variación estacional propia del paso de primavera a verano.

La serie semanal confirma el resultado por vía gráfica: ambas curvas evolucionan en paralelo a lo largo de las trece semanas analizadas, sin que se registre discontinuidad alguna en la semana del 7 de mayo, correspondiente al inicio de la campaña.

### 4.2 Contraste estadístico

Se aplicó la prueba t de Welch sobre la diferencia de gasto por hogar entre ambos grupos. La elección de la variante de Welch responde a la desigualdad de varianzas, esperable en grupos con bases de gasto sustancialmente distintas:

```
Welch Two Sample t-test
t = -0.025886, df = 621.71, p-value = 0.9794
Intervalo de confianza al 95%: [-19.50269, 18.99522]
Medias: control = 10.836 | expuesto = 11.089
```

El intervalo de confianza resulta más informativo que el valor p. Los datos son compatibles tanto con una reducción de 19 dólares por hogar como con un incremento de magnitud equivalente. La conclusión apropiada no consiste en afirmar la ausencia de efecto, sino en reconocer que:

> El efecto incremental no es distinguible de cero, y el diseño únicamente permite detectar efectos superiores a ±19 dólares por hogar, equivalentes a cerca del 6% sobre una base de 313 dólares.

Las medias obtenidas en la prueba (diferencia de 0.25) coinciden con las de la tabla agregada, lo que valida ambos cálculos de manera independiente.

### 4.3 Desempeño por tipo de campaña

| Tipo | Campañas | Hogares alcanzados | Conversión simple (%) | Conversión ponderada (%) |
| --- | --- | --- | --- | --- |
| Tipo A | 4 | 3,647 | 15.44 | 16.56 |
| Tipo B | 17 | 2,368 | 6.60 | 6.50 |
| Tipo C | 6 | 574 | 7.09 | 5.92 |
| **Total** | **27** | **6,589** | **8.01** | **12.02** |

Las campañas de tipo A, personalizadas según comportamiento previo, presentan una tasa de conversión aproximadamente 2.5 veces superior a la de los demás tipos.

La discrepancia entre ambas medidas de conversión merece atención. La conversión simple corresponde al promedio no ponderado de las tasas individuales, de modo que una campaña de 12 hogares pesa lo mismo que una de 1,133. La conversión ponderada corresponde al cociente entre convertidos totales y expuestos totales. Ambas son correctas, pero responden a preguntas distintas: la campaña típica convierte al 8.01%, mientras que el hogar típico alcanzado convierte al 12.02%. El tipo C ilustra el fenómeno con claridad, al descender de 7.09% a 5.92% una vez ponderado por alcance.

---

## 5. Controles de calidad de la base de envío

Los registros de envío —direcciones de correo, rebotes, bajas y estados de entrega— constituyen datos personales y no se encuentran disponibles en ninguna fuente pública. Esta sección emplea por tanto una base de envío simulada, construida sobre los identificadores reales de hogar de la campaña 8, en la cual se introdujeron errores de manera deliberada con el fin de validar los controles implementados.

Sobre un total de 1,093 registros, el validador desarrollado en Excel detectó la totalidad de los errores introducidos:

| Control | Detectados | Implicancia operativa |
| --- | --- | --- |
| Registros duplicados | 12 | un mismo destinatario recibe la comunicación dos veces |
| Correo con formato inválido | 8 | genera rebotes que deterioran la reputación del dominio remitente |
| Nombre vacío | 10 | la personalización se muestra incompleta en la pieza enviada |
| Sin consentimiento | 15 | el envío a quien ha solicitado su baja constituye un incumplimiento normativo |
| Hogar ajeno a la campaña | 5 | la base no corresponde a la audiencia definida |

Se incorporó asimismo una lista de verificación por envío, con una fila por campaña y una columna por control: base validada, pieza revisada, enlaces probados, prueba interna enviada, horario confirmado, envío ejecutado y reporte actualizado.

---

## 6. Discusión y limitaciones

**Sesgo de selección.** Los 485 hogares expuestos registraban un gasto de 313 dólares por hogar con anterioridad a la campaña, frente a 109 dólares del grupo de control: una relación cercana a 3 a 1. Los grupos no resultan comparables en nivel, y el supuesto de tendencias paralelas que exige un diseño de diferencias en diferencias no es verificable disponiendo únicamente de dos periodos.

**Regresión a la media.** En términos relativos, el grupo de control creció más que el expuesto (9.9% frente a 3.5%). Un hogar cuyo gasto asciende a 313 dólares dispone de menor margen de crecimiento que uno de 109 dólares, razón por la cual la lectura en valores absolutos resulta la apropiada en este caso.

**Alcance de la generalización.** Los 485 hogares analizados constituyen un subconjunto de los 1,076 originalmente alcanzados: precisamente aquellos que no recibieron otras campañas, presumiblemente de menor nivel de interacción con la marca. Los resultados aplican a ese subconjunto.

**Cobertura.** El análisis abarca una única campaña. Su replicación sobre la campaña 13 permitiría evaluar la consistencia del hallazgo; la campaña 18, por su coincidencia con la temporada navideña, resultaría ilustrativa para dimensionar cuánto exagera la estacionalidad una medición carente de grupo de comparación.

---

## 7. Conclusiones

1. La campaña analizada no produjo un efecto incremental detectable sobre el gasto de los hogares expuestos. El efecto estimado de 0.25 dólares por hogar no es estadísticamente distinguible de cero.

2. En ausencia de un grupo de comparación, el análisis habría reportado un incremento de 11.09 dólares por hogar, equivalente al 3.5%, como resultado de la campaña. La magnitud del error de atribución asciende a un factor de 44.

3. La verificación previa del grupo de comparación resultó determinante: el 54.9% de los hogares expuestos recibía simultáneamente otras campañas, frente al 12.1% del grupo no expuesto. De no haberse corregido, la medición habría capturado el efecto conjunto de múltiples acciones de marketing.

4. Las campañas personalizadas (tipo A) presentan tasas de conversión sustancialmente superiores, aunque dicha ventaja no puede interpretarse causalmente: la personalización se construye sobre hogares previamente identificados como de mayor valor.

---

## 8. Estructura del repositorio

```
/sql     01_validaciones.sql                  validaciones previas: grano, contaminación y ventana
         02_rpt_conversion_campanas.sql       tasa de conversión por campaña
         03_rpt_uplift_campana_8.sql          uplift agregado por grupo y ventana
         04_uplift_por_hogar.sql              insumo del contraste estadístico
         05_rpt_serie_semanal_campana_8.sql   evolución semanal por grupo
         06_rpt_uplift_resumen.sql            indicadores finales del dashboard
/r       genera_base_envio.R                  base de envío simulada con errores controlados
         t_test_uplift.R                      prueba t de Welch
/excel   validador_base_envio.xlsx            validador, lista de verificación y tablas dinámicas
         base_envio_campana_8.csv             base de envío simulada
README.md
```

Las tablas de reporte (`rpt_*`) se materializan en BigQuery en lugar de mantener las uniones en tiempo de consulta: las consultas de uplift recorren 1.5 millones de registros, por lo que su precálculo permite que el dashboard cargue de manera inmediata sin consumo de cuota en cada visita.

---

## 9. Fuente de los datos

dunnhumby. *The Complete Journey*. Disponible en https://www.8451.com/area51/
Acceso mediante el paquete `completejourney` (CRAN), licencia CC0.
