# FGV-PETEJ-SC Dashboard

Desenvolvido por Cicero Lima

Autores: Cicero Zanetti de Lima, Angelo Costa Gurgel

E-mail: cicero.lima@fgv.br  /  czlima@gmail.com

Dashboard para visualização dos resultados do modelo FGV-PETEJ-SC. 
O dashboard utiliza a estrutura do **Shinylive**.

Esse dashboard público não contém o código GAMS/MPSGE e executáveis/solvers. Apenas lê os resultados processados. Localmente é executado a conversão do arquivo GDX --> CSV e, posteriormente, a execução do **Shinylive**.

O arquivo csv com os dados completos do dashboard estão em: `app/data/report.csv` 

## Arquitetura do workflow

```text
FGV-PETEJ-SC / GAMS
        |
        | report_shiny.gdx
        v
local preprocessing
(tools/prepare_report_csv.R)
        |
        | app/data/report.csv
        v
Shiny + Shinylive
        |
        v
GitHub Pages
```
