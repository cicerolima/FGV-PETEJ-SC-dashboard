# | Local helper: convert report_shiny.gdx into a browser-friendly CSV
# | Run this script on the computer where GAMS / GDX results are available.

# ========================================================
# Packages used only in the local preprocessing step
# ========================================================

packs <- c(
  "gamstransfer",
  "dplyr"
)

missing <- packs[
  !(packs %in% rownames(installed.packages()))
]

if (length(missing) > 0) {
  
  install.packages(
    missing,
    repos = "https://cloud.r-project.org"
  )
  
}

library(gamstransfer)
library(dplyr)


# ========================================================
# Paths
# ========================================================

# This file is expected to be located in:
#
#   tools/prepare_report_csv.R
#
# The GDX file should be located in the repository root:
#
#   report_shiny.gdx
#
# The CSV will be created in:
#
#   app/data/report.csv


# --------------------------------------------------------
# Detect directory where this script is located
# --------------------------------------------------------

get_script_dir <- function() {
  
  frames <- sys.frames()
  
  ofiles <- vapply(
    frames,
    function(x) {
      
      if (!is.null(x$ofile)) {
        
        as.character(x$ofile)
        
      } else {
        
        NA_character_
        
      }
      
    },
    character(1)
  )
  
  ofiles <- ofiles[
    !is.na(ofiles)
  ]
  
  if (length(ofiles) > 0) {
    
    dirname(
      normalizePath(
        tail(ofiles, 1),
        winslash = "/",
        mustWork = FALSE
      )
    )
    
  } else {
    
    getwd()
    
  }
  
}


script_dir <- get_script_dir()


# --------------------------------------------------------
# Repository root
# --------------------------------------------------------

repo_root <- normalizePath(
  file.path(
    script_dir,
    ".."
  ),
  winslash = "/",
  mustWork = FALSE
)


# --------------------------------------------------------
# Input GDX
# --------------------------------------------------------

gdx_file <- file.path(
  script_dir,
  "report_shiny.gdx"
)


# --------------------------------------------------------
# Output CSV
# --------------------------------------------------------

out_file <- file.path(
  repo_root,
  "app",
  "data",
  "report.csv"
)


# ========================================================
# Check input file
# ========================================================

if (!file.exists(gdx_file)) {
  
  stop(
    paste0(
      "GDX file not found: ",
      normalizePath(
        gdx_file,
        winslash = "/",
        mustWork = FALSE
      )
    )
  )
  
}


# ========================================================
# Create output directory
# ========================================================

dir.create(
  dirname(out_file),
  recursive = TRUE,
  showWarnings = FALSE
)


# ========================================================
# Read report_1 from GDX
# ========================================================

gdx <- Container$new(
  gdx_file
)

report <- gdx[
  "report_1"
]$records


# ========================================================
# Check original GDX structure
# ========================================================

required_gdx_cols <- c(
  "uni_1",
  "scen_2",
  "uni_3",
  "uni_4",
  "uni_5",
  "t_6",
  "uni_7",
  "value"
)


if (!all(required_gdx_cols %in% names(report))) {
  
  stop(
    paste0(
      "Unexpected structure in report_1 records.\n",
      "Expected columns: ",
      paste(
        required_gdx_cols,
        collapse = ", "
      ),
      "\n",
      "Available columns: ",
      paste(
        names(report),
        collapse = ", "
      )
    )
  )
  
}


# ========================================================
# Indicator labels
# ========================================================

# "indicador" remains the original GAMS identifier.
#
# "indicador_label" is the label displayed in the dashboard.

indicator_labels <- c(
  
  "CONS" =
    "Consumo",
  
  "OUTPUT_VALUE" =
    "Valor da produção",
  
  "CPI" =
    "Inflação",
  
  "GDP_DEFLATOR" =
    "Deflator do PIB",
  
  "VA" =
    "Valor adicionado",
  
  "EMPREGO" =
    "Emprego",
  
  "EMPREGO_RISK" =
    "Empregos mapeados",
  
  "ELEC_GEN" =
    "Geração de energia elétrica",
  
  "ELEC_BALANCE" =
    "Balanço energia elétrica",
  
  "ELEC_GHG" =
    "Emissões GEE - Energia elétrica"
  
)


# ========================================================
# Convert to long / tidy format
# ========================================================

report_tidy <- report %>%
  
  rename(
    
    indicador = uni_1,
    
    cenario = scen_2,
    
    item = uni_3,
    
    regiao = uni_4,
    
    familia = uni_5,
    
    ano = t_6,
    
    medida = uni_7,
    
    valor = value
    
  ) %>%
  
  mutate(
    
    # ----------------------------------------------------
    # Convert GDX categorical dimensions to character
    # ----------------------------------------------------
    
    indicador = as.character(indicador),
    cenario   = as.character(cenario),
    item      = as.character(item),
    regiao    = as.character(regiao),
    familia   = as.character(familia),
    medida    = as.character(medida),
    
    # ----------------------------------------------------
    # Numerical variables
    # ----------------------------------------------------
    
    ano = as.numeric(
      as.character(ano)
    ),
    
    valor = as.numeric(
      valor
    ),
    
    # ----------------------------------------------------
    # Friendly indicator labels
    # ----------------------------------------------------
    
    indicador_label = recode(
      indicador,
      
      "CONS"         = "Consumo",
      "OUTPUT_VALUE" = "Valor da produção",
      "CPI"          = "Inflação",
      "GDP_DEFLATOR" = "Deflator do PIB",
      "VA"           = "Valor adicionado",
      "EMPREGO"      = "Emprego",
      "EMPREGO_RISK" = "Empregos mapeados",
      "ELEC_GEN"     = "Geração de energia elétrica",
      "ELEC_BALANCE" = "Balanço energia elétrica",
      "ELEC_GHG"     = "Emissões GEE - Energia elétrica",
      
      .default = indicador
    )
    
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


# ========================================================
# Check final structure
# ========================================================

required_cols <- c(
  
  "indicador",
  
  "indicador_label",
  
  "cenario",
  
  "item",
  
  "regiao",
  
  "familia",
  
  "ano",
  
  "medida",
  
  "valor"
  
)


if (!all(required_cols %in% names(report_tidy))) {
  
  stop(
    paste0(
      "Unexpected structure after preparing report_1.\n",
      "Expected columns: ",
      paste(
        required_cols,
        collapse = ", "
      )
    )
  )
  
}


# ========================================================
# Write browser-friendly CSV
# ========================================================

write.csv(
  
  report_tidy[
    ,
    required_cols
  ],
  
  out_file,
  
  row.names = FALSE,
  
  fileEncoding = "UTF-8",
  
  na = ""
  
)


# ========================================================
# Processing summary
# ========================================================

message(
  "--------------------------------------------"
)

message(
  "FGV-PETEJ-SC report prepared successfully"
)

message(
  "--------------------------------------------"
)


message(
  "Input GDX: ",
  normalizePath(
    gdx_file,
    winslash = "/",
    mustWork = TRUE
  )
)


message(
  "Created CSV: ",
  normalizePath(
    out_file,
    winslash = "/",
    mustWork = TRUE
  )
)


message(
  "Rows: ",
  format(
    nrow(report_tidy),
    big.mark = ","
  )
)


message(
  "Size: ",
  format(
    file.info(out_file)$size,
    big.mark = ","
  ),
  " bytes"
)


message(
  "Indicators found: ",
  paste(
    sort(
      unique(
        report_tidy$indicador
      )
    ),
    collapse = ", "
  )
)


message(
  "--------------------------------------------"
)
