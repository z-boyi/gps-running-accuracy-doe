# 00_clean_data.R
# Turn the raw lap log (one row per lap, both apps side by side) into the
# analysis file data/processed/gps_runs.csv (one row per app reading).
#
# The raw file data/gps_track_data_log.csv is never edited by hand;
# every cleaning step lives here so it can be re-run and checked.
#
# Run from the repository root:  Rscript code/00_clean_data.R
# Run this script first: it also installs the R packages that the analysis
# scripts (02_analysis.R, 03_absolute_error.R) need.

# ---- 0. Packages ------------------------------------------------------------

# Install a package only if it is missing, so re-running the script is fast
packages <- c("lme4", "lmerTest", "emmeans", "pbkrtest", "ggplot2")
missing  <- packages[!packages %in% rownames(installed.packages())]
if (length(missing) > 0) {
  install.packages(missing, repos = "https://cloud.r-project.org")
}

# Load them to check that every package installed correctly.
# This script itself only uses base R; each analysis script loads what it needs.
suppressPackageStartupMessages(
  for (pkg in packages) library(pkg, character.only = TRUE)
)

# ---- 1. Read and check the raw lap log --------------------------------------

raw <- read.csv("data/gps_track_data_log.csv", check.names = FALSE,
                stringsAsFactors = FALSE)

# Basic checks on the raw log: 4 blocks x 8 laps, each combination once per block
stopifnot(nrow(raw) == 32)
stopifnot(all(table(raw[["Block (member)"]]) == 8))
stopifnot(all(table(raw[["Block (member)"]], raw$Lane, raw$Placement, raw$Pace) == 1))

# ---- 2. Reshape: one row per app reading -----------------------------------

# Columns shared by both app readings of a lap
lap <- data.frame(
  block     = raw[["Block (member)"]],
  lap_order = raw[["Lap order"]],
  lane      = raw$Lane,
  placement = raw$Placement,
  pace      = raw$Pace,
  date      = raw$Date,
  weather   = raw$Weather,
  notes     = raw$Notes
)

# Wide -> long: stack the Strava rows on top of the Keep rows
long <- rbind(
  data.frame(lap, app = "Strava",
             recorded_distance_m = round(1000 * raw[["Strava distance (km)"]])),
  data.frame(lap, app = "Keep",
             recorded_distance_m = round(1000 * raw[["Keep distance (km)"]]))
)

# ---- 3. True distance and percentage error ---------------------------------

# True lap length on this track's measurement line (lane 1 and lane 8)
long$true_distance_m <- ifelse(long$lane == 1, 400.00, 453.03)

# Signed percentage error: > 0 means the app over-records
long$error_pct <- 100 * (long$recorded_distance_m - long$true_distance_m) /
  long$true_distance_m

# One id per lap, e.g. "Boyi_3"; the Strava and Keep readings of a lap share it.
# lap_order alone (1-8) is not enough: Phoebe's lap 1 and Boyi's lap 1 are
# different laps, so the id combines block and lap order (32 distinct laps).
long$lap_id <- paste(long$block, long$lap_order, sep = "_")

# ---- 4. Save ----------------------------------------------------------------

# Order rows by block, lap order, then app
long$block <- factor(long$block, levels = c("Phoebe", "Boyi", "Jenny", "Darren"))
long <- long[order(long$block, long$lap_order, long$app), ]

out <- long[, c("block", "lap_order", "lap_id", "lane", "placement", "pace",
                "app", "true_distance_m", "recorded_distance_m", "error_pct",
                "date", "weather", "notes")]
out$error_pct <- round(out$error_pct, 3)

stopifnot(nrow(out) == 64, !anyNA(out$recorded_distance_m))

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
write.csv(out, "data/processed/gps_runs.csv", row.names = FALSE, na = "")
cat("Wrote data/processed/gps_runs.csv:", nrow(out), "rows\n")
