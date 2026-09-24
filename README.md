# FGV-PETEJ-SC Dashboard

Browser-only version of the FGV-PETEJ-SC Shiny dashboard using **Shinylive**.

The public dashboard does **not** contain or execute GAMS/MPSGE. It only reads the
pre-processed results in `app/data/report.csv` and runs Shiny inside the browser.

## Architecture

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

## 1. Update model results

Copy the current `report_shiny.gdx` to the repository root and run locally:

```r
source("tools/prepare_report_csv.R")
```

This creates/updates:

```text
app/data/report.csv
```

`report_shiny.gdx` is ignored by Git and should remain local.

## 2. Test the ordinary Shiny app locally

```r
shiny::runApp("app")
```

## 3. Test the Shinylive version locally

```r
source("tools/build_site.R")

install.packages("httpuv") # only once
httpuv::runStaticServer("site/")
```

Do not open `site/index.html` directly with `file://`; use a local HTTP server.

## 4. Publish with GitHub Pages

1. Create a GitHub repository and copy this project into it.
2. Commit `app/data/report.csv` together with the code.
3. Push to the `main` branch.
4. In GitHub: **Settings > Pages > Build and deployment > Source = GitHub Actions**.
5. The workflow `.github/workflows/deploy-pages.yml` exports the Shinylive app and publishes it.

After the first successful deployment, the dashboard will be available at a URL similar to:

```text
https://USERNAME.github.io/REPOSITORY/
```

## Updating the dashboard

For each new PETEJ simulation:

```text
1. Run GAMS
2. Generate report_shiny.gdx
3. Run tools/prepare_report_csv.R
4. Check app/data/report.csv
5. git add / commit / push
6. GitHub Actions republishes the site automatically
```

## Public/private data note

Everything placed in `app/` is bundled into the static website and can be downloaded by a visitor.
Therefore, only publish model outputs that are appropriate for sharing. Keep GAMS source code, raw
confidential data, and `report_shiny.gdx` outside `app/`.
