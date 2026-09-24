# |  (C) 2026 FGV AGRO Research group
# |  This file is part of PETEJ-SC distribution.
# |  Author: Cicero Lima
# |
# |  Browser version for Shinylive / GitHub Pages.
# |  The GDX file is NOT read in the browser. Run the local helper
# |  tools/prepare_report_csv.R before publishing the application.


# ========================================================
# Packages available in the browser (WebAssembly)
# ========================================================

library(shiny)
library(dplyr)
library(ggplot2)

# scale_color_viridis_d() is provided by ggplot2, so the separate
# {viridis} package is not required in the browser version.


# ========================================================
# Read pre-processed PETEJ report
# ========================================================

report_file <- file.path("data", "report.csv")

if (!file.exists(report_file)) {
  stop(
    paste0(
      "PETEJ data file not found: ", report_file,
      ". Run tools/prepare_report_csv.R locally before publishing."
    )
  )
}

report_tidy <- read.csv(
  report_file,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  fileEncoding = "UTF-8"
) %>%
  mutate(
    ano = as.numeric(ano),
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

missing_cols <- setdiff(required_cols, names(report_tidy))

if (length(missing_cols) > 0) {
  stop(
    paste0(
      "Invalid report.csv. Missing columns: ",
      paste(missing_cols, collapse = ", ")
    )
  )
}


# ========================================================
# Benchmark year - 2019
# ========================================================

report_2019 <- report_tidy %>%
  filter(ano == 2019)


# ========================================================
# Simulation periods - excluding 2019
# ========================================================

report_tidy <- report_tidy %>%
  filter(ano != 2019)


# ========================================================
# USER INTERFACE
# ========================================================

ui <- fluidPage(
  
  titlePanel(
    "Modelo FGV-PETEJ"
  ),
  
  sidebarLayout(
    
    # ====================================================
    # SIDEBAR
    # ====================================================
    
    sidebarPanel(
      
      # --------------------------------------------------
      # Indicator
      # --------------------------------------------------
      
      selectInput(
        inputId = "indicador",
        label   = "Indicador",
        choices = NULL
      ),
      
      
      # --------------------------------------------------
      # Scenario
      # --------------------------------------------------
      
      checkboxGroupInput(
        inputId = "cenarios",
        label   = "Cenário",
        choices = NULL
      ),
      
      
      # --------------------------------------------------
      # Region
      # --------------------------------------------------
      
      checkboxGroupInput(
        inputId = "regioes",
        label   = "Região",
        choices = NULL
      ),
      
      fluidRow(
        
        column(
          6,
          actionButton(
            "selecionar_regioes",
            "Selecionar todas"
          )
        ),
        
        column(
          6,
          actionButton(
            "desmarcar_regioes",
            "Desmarcar"
          )
        )
        
      ),
      
      tags$hr(),
      
      
      # --------------------------------------------------
      # Item / activity / component
      # --------------------------------------------------
      
      checkboxGroupInput(
        inputId = "itens",
        label   = "Item / atividade / componente",
        choices = NULL
      ),
      
      fluidRow(
        
        column(
          6,
          actionButton(
            "selecionar_itens",
            "Selecionar todos"
          )
        ),
        
        column(
          6,
          actionButton(
            "desmarcar_itens",
            "Desmarcar"
          )
        )
        
      ),
      
      tags$hr(),
      
      
      # --------------------------------------------------
      # Household
      # --------------------------------------------------
      
      checkboxGroupInput(
        inputId = "familias",
        label   = "Família / grupo",
        choices = NULL
      ),
      
      fluidRow(
        
        column(
          6,
          actionButton(
            "selecionar_familias",
            "Selecionar todas"
          )
        ),
        
        column(
          6,
          actionButton(
            "desmarcar_familias",
            "Desmarcar"
          )
        )
        
      ),
      
      tags$hr(),
      
      
      # --------------------------------------------------
      # Measure
      # --------------------------------------------------
      
      selectInput(
        inputId = "medida",
        label   = "Medida",
        choices = NULL
      ),
      
      
      # --------------------------------------------------
      # Display / BAU comparison
      # --------------------------------------------------
      
      selectInput(
        inputId = "comparacao",
        label   = "Forma de exibição",
        choices = c(
          "Valor original" = "original"
        )
      )
      
    ),
    
    
    # ====================================================
    # MAIN PANEL
    # ====================================================
    
    mainPanel(
      
      fluidRow(
        
        column(
          12,
          downloadButton(
            "download_plot",
            "Download PNG"
          )
        )
        
      ),
      
      tags$br(),
      
      plotOutput(
        "grafico",
        height = "620px"
      ),
      
      tags$hr(),
      
      tableOutput(
        "tabela"
      )
      
    )
    
  )
  
)


# ========================================================
# SERVER
# ========================================================

server <- function(input, output, session) {
  
  
  # ======================================================
  # INDICATOR
  # ======================================================
  
  observe({
    
    indicadores <- sort(
      unique(report_tidy$indicador)
    )
    
    updateSelectInput(
      session,
      "indicador",
      choices  = indicadores,
      selected = indicadores[1]
    )
    
  })
  
  
  # ======================================================
  # SCENARIO
  # ======================================================
  
  observeEvent(
    input$indicador,
    {
      
      req(input$indicador)
      
      df <- report_tidy %>%
        filter(
          indicador == input$indicador
        )
      
      cenarios <- unique(
        df$cenario
      )
      
      updateCheckboxGroupInput(
        session,
        "cenarios",
        choices  = cenarios,
        selected = cenarios
      )
      
    }
  )
  
  
  # ======================================================
  # UPDATE REGION / ITEM / HOUSEHOLD / MEASURE
  # ======================================================
  
  observe({
    
    req(
      input$indicador,
      input$cenarios
    )
    
    df <- report_tidy %>%
      filter(
        indicador == input$indicador,
        cenario %in% input$cenarios
      )
    
    
    # ----------------------------------------------------
    # Regions
    # ----------------------------------------------------
    
    regioes <- unique(
      df$regiao
    )
    
    updateCheckboxGroupInput(
      session,
      "regioes",
      choices  = regioes,
      selected = regioes
    )
    
    
    # ----------------------------------------------------
    # Items
    # ----------------------------------------------------
    
    itens <- unique(
      df$item
    )
    
    updateCheckboxGroupInput(
      session,
      "itens",
      choices  = itens,
      selected = itens
    )
    
    
    # ----------------------------------------------------
    # Households
    # ----------------------------------------------------
    
    familias <- unique(
      df$familia
    )
    
    updateCheckboxGroupInput(
      session,
      "familias",
      choices  = familias,
      selected = familias
    )
    
    
    # ----------------------------------------------------
    # Measures
    # ----------------------------------------------------
    
    medidas <- unique(
      df$medida
    )
    
    updateSelectInput(
      session,
      "medida",
      choices  = medidas,
      selected = medidas[1]
    )
    
  })
  
  
  # ======================================================
  # UPDATE DISPLAY OPTIONS
  #
  # ch_%:
  #
  # 100 * [
  #   (1 + TE/100) /
  #   (1 + BAU/100)
  #   - 1
  # ]
  #
  # Other measures:
  #
  # Difference:
  # TE - BAU
  #
  # Percentage variation:
  # 100 * (TE / BAU - 1)
  # ======================================================
  
  observeEvent(
    input$medida,
    {
      
      req(input$medida)
      
      if (input$medida == "ch_%") {
        
        updateSelectInput(
          session,
          "comparacao",
          choices = c(
            "Valor original"          = "original",
            "Variação vs BAU (%)"     = "var_bau"
          ),
          selected = "original"
        )
        
      } else {
        
        updateSelectInput(
          session,
          "comparacao",
          choices = c(
            "Valor original"                  = "original",
            "Diferença absoluta vs BAU"       = "diff_abs",
            "Variação percentual vs BAU (%)"  = "var_pct"
          ),
          selected = "original"
        )
        
      }
      
    },
    ignoreInit = FALSE
  )
  
  
  # ======================================================
  # REGION BUTTONS
  # ======================================================
  
  observeEvent(
    input$selecionar_regioes,
    {
      
      req(
        input$indicador,
        input$cenarios
      )
      
      regioes <- report_tidy %>%
        filter(
          indicador == input$indicador,
          cenario %in% input$cenarios
        ) %>%
        pull(regiao) %>%
        unique()
      
      updateCheckboxGroupInput(
        session,
        "regioes",
        selected = regioes
      )
      
    }
  )
  
  
  observeEvent(
    input$desmarcar_regioes,
    {
      
      updateCheckboxGroupInput(
        session,
        "regioes",
        selected = character(0)
      )
      
    }
  )
  
  
  # ======================================================
  # ITEM BUTTONS
  # ======================================================
  
  observeEvent(
    input$selecionar_itens,
    {
      
      req(
        input$indicador,
        input$cenarios
      )
      
      itens <- report_tidy %>%
        filter(
          indicador == input$indicador,
          cenario %in% input$cenarios
        ) %>%
        pull(item) %>%
        unique()
      
      updateCheckboxGroupInput(
        session,
        "itens",
        selected = itens
      )
      
    }
  )
  
  
  observeEvent(
    input$desmarcar_itens,
    {
      
      updateCheckboxGroupInput(
        session,
        "itens",
        selected = character(0)
      )
      
    }
  )
  
  
  # ======================================================
  # HOUSEHOLD BUTTONS
  # ======================================================
  
  observeEvent(
    input$selecionar_familias,
    {
      
      req(
        input$indicador,
        input$cenarios
      )
      
      familias <- report_tidy %>%
        filter(
          indicador == input$indicador,
          cenario %in% input$cenarios
        ) %>%
        pull(familia) %>%
        unique()
      
      updateCheckboxGroupInput(
        session,
        "familias",
        selected = familias
      )
      
    }
  )
  
  
  observeEvent(
    input$desmarcar_familias,
    {
      
      updateCheckboxGroupInput(
        session,
        "familias",
        selected = character(0)
      )
      
    }
  )
  
  
  # ======================================================
  # BASE DATA
  #
  # Important:
  # Do not filter scenario here.
  #
  # BAU must remain available internally even when the user
  # selects only TE, because it is the reference scenario.
  # ======================================================
  
  dados_base <- reactive({
    
    req(
      input$indicador,
      input$regioes,
      input$itens,
      input$familias,
      input$medida
    )
    
    report_tidy %>%
      filter(
        indicador == input$indicador,
        regiao %in% input$regioes,
        item %in% input$itens,
        familia %in% input$familias,
        medida == input$medida
      )
    
  })
  
  
  # ======================================================
  # FILTERED / TRANSFORMED DATA
  # ======================================================
  
  dados_filtrados <- reactive({
    
    req(
      input$cenarios,
      input$comparacao
    )
    
    dados <- dados_base()
    
    
    # ----------------------------------------------------
    # ORIGINAL VALUES
    # ----------------------------------------------------
    
    if (input$comparacao == "original") {
      
      return(
        dados %>%
          filter(
            cenario %in% input$cenarios
          )
      )
      
    }
    
    
    # ----------------------------------------------------
    # SCENARIOS TO BE COMPARED AGAINST BAU
    # ----------------------------------------------------
    
    cenarios_comparacao <- setdiff(
      input$cenarios,
      "BAU"
    )
    
    validate(
      need(
        length(cenarios_comparacao) > 0,
        "Para comparar com o BAU, selecione pelo menos um cenário diferente de BAU."
      )
    )
    
    
    # ----------------------------------------------------
    # BAU REFERENCE
    # ----------------------------------------------------
    
    dados_bau <- dados %>%
      filter(
        cenario == "BAU"
      ) %>%
      select(
        indicador,
        item,
        regiao,
        familia,
        ano,
        medida,
        valor_bau = valor
      )
    
    
    validate(
      need(
        nrow(dados_bau) > 0,
        "Não existem observações BAU para a combinação selecionada."
      )
    )
    
    
    # ----------------------------------------------------
    # POLICY SCENARIOS
    # ----------------------------------------------------
    
    dados_cenario <- dados %>%
      filter(
        cenario %in% cenarios_comparacao
      ) %>%
      rename(
        valor_cenario = valor
      )
    
    
    # ----------------------------------------------------
    # MERGE SCENARIO + BAU
    # ----------------------------------------------------
    
    dados_comp <- dados_cenario %>%
      left_join(
        dados_bau,
        by = c(
          "indicador",
          "item",
          "regiao",
          "familia",
          "ano",
          "medida"
        )
      )
    
    
    # ----------------------------------------------------
    # CHECK BAU
    # ----------------------------------------------------
    
    validate(
      need(
        any(!is.na(dados_comp$valor_bau)),
        "Não foi possível encontrar o valor BAU correspondente."
      )
    )
    
    
    # ----------------------------------------------------
    # CASE 1:
    # measure = ch_%
    #
    # The reported BAU and TE values are already percentage
    # changes relative to the common 2019 benchmark.
    #
    # Therefore:
    #
    # TE / BAU comparison =
    #
    # 100 * [
    #   (1 + g_TE) /
    #   (1 + g_BAU)
    #   - 1
    # ]
    #
    # where g is expressed as a decimal.
    # ----------------------------------------------------
    
    if (
      input$medida == "ch_%" &&
      input$comparacao == "var_bau"
    ) {
      
      dados_comp <- dados_comp %>%
        mutate(
          
          valor = if_else(
            
            !is.na(valor_bau) &
              abs(1 + valor_bau / 100) > 1e-10,
            
            100 * (
              (1 + valor_cenario / 100) /
                (1 + valor_bau / 100)
              - 1
            ),
            
            NA_real_
          ),
          
          cenario = paste0(
            cenario,
            " vs BAU"
          )
        )
      
    }
    
    
    # ----------------------------------------------------
    # CASE 2:
    # Absolute difference
    #
    # Scenario - BAU
    # ----------------------------------------------------
    
    if (
      input$medida != "ch_%" &&
      input$comparacao == "diff_abs"
    ) {
      
      dados_comp <- dados_comp %>%
        mutate(
          
          valor =
            valor_cenario -
            valor_bau,
          
          cenario = paste0(
            cenario,
            " vs BAU"
          )
        )
      
    }
    
    
    # ----------------------------------------------------
    # CASE 3:
    # Percentage variation relative to BAU
    #
    # 100 * (Scenario / BAU - 1)
    # ----------------------------------------------------
    
    if (
      input$medida != "ch_%" &&
      input$comparacao == "var_pct"
    ) {
      
      dados_comp <- dados_comp %>%
        mutate(
          
          valor = if_else(
            
            !is.na(valor_bau) &
              abs(valor_bau) > 1e-10,
            
            100 * (
              valor_cenario /
                valor_bau
              - 1
            ),
            
            NA_real_
          ),
          
          cenario = paste0(
            cenario,
            " vs BAU"
          )
        )
      
    }
    
    
    # ----------------------------------------------------
    # Return same structure as original database
    # ----------------------------------------------------
    
    dados_comp %>%
      select(
        indicador,
        cenario,
        item,
        regiao,
        familia,
        ano,
        medida,
        valor
      )
    
  })
  
  
  # ======================================================
  # DISPLAY LABEL
  # ======================================================
  
  rotulo_exibicao <- reactive({
    
    req(
      input$medida,
      input$comparacao
    )
    
    if (input$comparacao == "original") {
      
      return(
        input$medida
      )
      
    }
    
    if (
      input$medida == "ch_%" &&
      input$comparacao == "var_bau"
    ) {
      
      return(
        "Variação vs BAU (%)"
      )
      
    }
    
    if (input$comparacao == "diff_abs") {
      
      return(
        paste0(
          "Diferença absoluta - ",
          input$medida
        )
      )
      
    }
    
    if (input$comparacao == "var_pct") {
      
      return(
        "Variação vs BAU (%)"
      )
      
    }
    
    input$medida
    
  })
  
  
  # ======================================================
  # SUBTITLE
  # ======================================================
  
  subtitulo_grafico <- reactive({
    
    if (input$comparacao == "original") {
      
      paste(
        "Cenários:",
        paste(
          input$cenarios,
          collapse = " + "
        )
      )
      
    } else {
      
      cenarios_comparacao <- setdiff(
        input$cenarios,
        "BAU"
      )
      
      paste(
        paste(
          cenarios_comparacao,
          collapse = " + "
        ),
        "em relação ao BAU"
      )
      
    }
    
  })
  
  
  # ======================================================
  # TABLE
  # ======================================================
  
  output$tabela <- renderTable({
    
    dados_filtrados() %>%
      arrange(
        regiao,
        item,
        familia,
        cenario,
        ano
      )
    
  })
  
  
  # ======================================================
  # PLOT OBJECT
  #
  # Color    = economic series
  # Linetype = scenario
  # Shape    = scenario
  #
  # In original mode:
  # BAU and TE for the same series have the same color.
  #
  # In BAU comparison mode:
  # the plotted line is the transformed scenario vs BAU.
  # ======================================================
  
  grafico_obj <- reactive({
    
    dados <- dados_filtrados()
    
    validate(
      need(
        nrow(dados) > 0,
        "Não existem dados para a combinação selecionada."
      )
    )
    
    
    # ----------------------------------------------------
    # Remove missing values generated by invalid BAU ratios
    # ----------------------------------------------------
    
    dados <- dados %>%
      filter(
        !is.na(valor)
      )
    
    
    validate(
      need(
        nrow(dados) > 0,
        "Não existem valores válidos para esta comparação com o BAU."
      )
    )
    
    
    # ----------------------------------------------------
    # Series identifiers
    # ----------------------------------------------------
    
    dados <- dados %>%
      mutate(
        
        serie = interaction(
          regiao,
          item,
          familia,
          sep  = " | ",
          drop = TRUE
        ),
        
        grupo = interaction(
          cenario,
          regiao,
          item,
          familia,
          sep  = " | ",
          drop = TRUE
        )
        
      )
    
    
    # ----------------------------------------------------
    # Plot
    # ----------------------------------------------------
    
    ggplot(
      dados,
      aes(
        x        = ano,
        y        = valor,
        group    = grupo,
        color    = serie,
        linetype = cenario
      )
    ) +
      
      geom_hline(
        yintercept = 0,
        linewidth  = 0.4,
        linetype   = "dotted"
      ) +
      
      geom_line(
        linewidth = 1.2
      ) +
      
      geom_point(
        aes(
          shape = cenario
        ),
        size = 2.8
      ) +
      
      scale_color_viridis_d(
        option = "D",
        begin  = 0.1,
        end    = 0.9
      ) +
      
      scale_x_continuous(
        breaks = sort(
          unique(dados$ano)
        )
      ) +
      
      theme_minimal() +
      
      labs(
        
        title = paste(
          input$indicador,
          "-",
          rotulo_exibicao()
        ),
        
        subtitle = subtitulo_grafico(),
        
        x = "Ano",
        y = rotulo_exibicao(),
        
        color    = "Série",
        linetype = "Cenário",
        shape    = "Cenário"
        
      ) +
      
      theme(
        
        axis.text.x = element_text(
          size = 12
        ),
        
        axis.text.y = element_text(
          size = 12
        ),
        
        axis.title.x = element_text(
          size = 14
        ),
        
        axis.title.y = element_text(
          size = 14
        ),
        
        plot.title = element_text(
          size = 17,
          face = "bold"
        ),
        
        plot.subtitle = element_text(
          size = 13
        ),
        
        legend.title = element_text(
          size = 12
        ),
        
        legend.text = element_text(
          size = 11
        )
        
      )
    
  })
  
  
  # ======================================================
  # DISPLAY PLOT
  # ======================================================
  
  output$grafico <- renderPlot({
    
    grafico_obj()
    
  })
  
  
  # ======================================================
  # DOWNLOAD PLOT - PNG
  # ======================================================
  
  output$download_plot <- downloadHandler(
    
    filename = function() {
      
      nome_indicador <- gsub(
        "[^A-Za-z0-9_-]",
        "_",
        input$indicador
      )
      
      nome_medida <- gsub(
        "[^A-Za-z0-9_-]",
        "_",
        input$medida
      )
      
      nome_comparacao <- gsub(
        "[^A-Za-z0-9_-]",
        "_",
        input$comparacao
      )
      
      nome_cenarios <- paste(
        input$cenarios,
        collapse = "_"
      )
      
      nome_cenarios <- gsub(
        "[^A-Za-z0-9_-]",
        "_",
        nome_cenarios
      )
      
      paste0(
        "PETEJ_",
        nome_indicador,
        "_",
        nome_medida,
        "_",
        nome_comparacao,
        "_",
        nome_cenarios,
        ".png"
      )
      
    },
    
    
    content = function(file) {
      
      p <- grafico_obj()
      
      ggsave(
        filename = file,
        plot     = p,
        device   = "png",
        width    = 12,
        height   = 7,
        units    = "in",
        dpi      = 300,
        bg       = "white"
      )
      
    }
    
  )
  
}


# ========================================================
# RUN APP
# ========================================================

shinyApp(
  ui,
  server
)
