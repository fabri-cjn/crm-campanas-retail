library(pacman)
p_load(completejourney,dplyr,purrr,readr)


arreglar_ids <- function(df) {
  df %>% mutate(across(
    ends_with("_id") | ends_with("_upc"),
    ~ sprintf("%.0f", as.numeric(.x))
  ))
}

tablas <- list(
  transactions          = get_transactions(),
  campaigns             = campaigns,
  campaign_descriptions = campaign_descriptions,
  coupon_redemptions    = coupon_redemptions
)

tablas <- lapply(tablas, arreglar_ids)

# Control: las cuatro líneas tienen que dar 0
for (n in names(tablas)) {
  cols <- tablas[[n]][grepl("_id$|_upc$", names(tablas[[n]]))]
  message(n, " — celdas con notación científica: ",
          sum(sapply(cols, function(c) sum(grepl("e", c, fixed = TRUE)))))
}

for (n in names(tablas)) {
  write_csv(tablas[[n]], paste0(n, ".csv"), na = "")
}



#t-test
d <- readr::read_csv("resultados.csv")
t.test(diferencia ~ grupo, data = d)
