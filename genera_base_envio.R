# =====================================================================
# Genera la base de envío simulada de la campaña 8
#
# Los household_id son reales (vienen de campaigns). Los datos de
# contacto son inventados: los logs de envío de una campaña real son
# datos personales y no existen en ninguna fuente pública.
#
# El script PLANTA errores a propósito, para que el validador de Excel
# tenga qué detectar. Al final imprime cuántos plantó de cada tipo:
# esos son los números contra los que se verifica el validador.
# =====================================================================

library(completejourney)
library(dplyr)
library(readr)

set.seed(42)

# --- Hogares reales de la campaña 8 -----------------------------------
hogares <- campaigns %>%
  filter(campaign_id == 8) %>%
  distinct(household_id)

nombres   <- c("Ana", "Luis", "María", "Carlos", "Rosa", "Jorge", "Elena",
               "Miguel", "Carmen", "Pedro", "Lucía", "Andrés", "Sofía",
               "Diego", "Paula", "Javier", "Daniela", "Rubén")
apellidos <- c("Ramírez", "Torres", "Quispe", "Flores", "Vargas", "Mendoza",
               "Castillo", "Rojas", "Salazar", "Chávez", "Herrera", "Paredes")

base <- hogares %>%
  mutate(
    nombre   = paste(sample(nombres,   n(), replace = TRUE),
                     sample(apellidos, n(), replace = TRUE)),
    correo   = paste0(tolower(gsub(" ", ".", nombre)), household_id,
                      "@", sample(c("gmail.com", "hotmail.com", "outlook.com"),
                                  n(), replace = TRUE)),
    acepta_comunicaciones = TRUE,
    segmento = sample(c("Alto valor", "Medio", "Ocasional"),
                      n(), replace = TRUE, prob = c(0.2, 0.5, 0.3))
  )

n <- nrow(base)
disponibles <- seq_len(n)

tomar <- function(k) {
  elegidos <<- sample(disponibles, k)
  disponibles <<- setdiff(disponibles, elegidos)
  elegidos
}

# --- Error 1: hogares sin consentimiento (15) -------------------------
i <- tomar(15)
base$acepta_comunicaciones[i] <- FALSE

# --- Error 2: correos mal formados (8) --------------------------------
# cuatro sin arroba, cuatro sin dominio
i <- tomar(8)
base$correo[i[1:4]] <- sub("@", "", base$correo[i[1:4]])
base$correo[i[5:8]] <- sub("@.*$", "@", base$correo[i[5:8]])

# --- Error 3: nombre vacío, rompe la personalización (10) -------------
i <- tomar(10)
base$nombre[i] <- ""

# --- Error 4: hogares ajenos a la campaña (5) -------------------------
ajenos <- campaigns %>%
  filter(campaign_id != 8) %>%
  distinct(household_id) %>%
  anti_join(hogares, by = "household_id") %>%
  slice_head(n = 5) %>%
  mutate(
    nombre   = paste(sample(nombres, 5, TRUE), sample(apellidos, 5, TRUE)),
    correo   = paste0("hogar", household_id, "@gmail.com"),
    acepta_comunicaciones = TRUE,
    segmento = "Medio"
  )

# --- Error 5: filas duplicadas (12) -----------------------------------
duplicados <- base %>% slice_sample(n = 12)

# --- Base final, en orden aleatorio -----------------------------------
base_envio <- bind_rows(base, ajenos, duplicados) %>%
  slice_sample(prop = 1)

write_csv(base_envio, "base_envio_campana_8.csv", na = "")

# --- Resumen de control -----------------------------------------------
# Estos son los números que tu validador de Excel debe encontrar.
cat("\nBase de envío generada:", nrow(base_envio), "filas\n")
cat("Errores plantados:\n")
cat("  sin consentimiento :", sum(!base_envio$acepta_comunicaciones), "\n")
cat("  correo inválido    :", sum(!grepl("^[^@]+@[^@]+\\.[^@]+$", base_envio$correo)), "\n")
cat("  nombre vacío       :", sum(base_envio$nombre == ""), "\n")
cat("  hogares ajenos     : 5\n")
cat("  filas duplicadas   : 12\n")
