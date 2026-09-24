# Local optional helper to export and preview the Shinylive site.

if (!requireNamespace("shinylive", quietly = TRUE)) {
  install.packages("shinylive", repos = "https://cloud.r-project.org")
}

if (!file.exists(file.path("app", "data", "report.csv"))) {
  stop("app/data/report.csv not found. Run tools/prepare_report_csv.R first.")
}

unlink("site", recursive = TRUE, force = TRUE)

shinylive::export(
  appdir = "app",
  destdir = "site",
  wasm_packages = TRUE,
  template_params = list(
    title = "FGV-PETEJ-SC"
  )
)

message("Shinylive site created in ./site")
message("Preview with: httpuv::runStaticServer(\"site/\")")
