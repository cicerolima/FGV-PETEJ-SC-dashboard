# |  Local helper: convert report_shiny.gdx into a browser-friendly CSV
# |  Run this script on the computer where GAMS / GDX results are available.

# ========================================================
# Packages used only in the local preprocessing step
# ========================================================

packs <- c("gamstransfer", "dplyr")
missing <- packs[!(packs %in% rownames(installed.packages()))]

if (length(missing) > 0) {
  install.packages(missing, repos = "https://cloud.r-project.org")
}

library(gamstransfer)
library(dplyr)


# ========================================================
# Paths
# ========================================================

# By default, place report_shiny.gdx in the repository root.
gdx_file <- "report_shiny.gdx"
out_file <- file.path("..","app", "data", "report.csv")

if (!file.exists(gdx_file)) {
  stop(
    paste0(
      "GDX file not found: ",
      normalizePath(gdx_file, mustWork = FALSE)
    )
  )
}

dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)


# ========================================================
# Read report_1 from GDX
# ========================================================

gdx <- Container$new(gdx_file)
report <- gdx["report_1"]$records


# ========================================================
# Convert to long/tidy format used by the dashboard
# ========================================================

report_tidy <- report %>%
  rename(
    indicador = uni_1,
    cenario   = scen_2,
    item      = uni_3,
    regiao    = uni_4,
    familia   = uni_5,
    ano       = t_6,
    medida    = uni_7,
    valor     = value
  ) %>%
  mutate(
    ano = as.numeric(as.character(ano)),
    valor = as.numeric(valor)
  ) %>%
  arrange(
    indicador,
    cenario,
    regiao,
    item,
    familia,
    medida,
    ano
  )

required_cols <- c(
  "indicador", "cenario", "item", "regiao",
  "familia", "ano", "medida", "valor"
)

if (!all(required_cols %in% names(report_tidy))) {
  stop("Unexpected structure in report_1 records.")
}


# ========================================================
# Write the only data file needed by the web dashboard
# ========================================================

write.csv(
  report_tidy[, required_cols],
  out_file,
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

message("Created: ", normalizePath(out_file, mustWork = TRUE))
message("Rows: ", nrow(report_tidy))
message("Size: ", format(file.info(out_file)$size, big.mark = ","), " bytes")
