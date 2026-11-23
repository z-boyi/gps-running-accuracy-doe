# 03_absolute_error.R
# Accuracy: how large is the typical error, ignoring its sign?
# (proposal v2, aim 3 and review comment 5)
#
# A mean signed error near 0 can hide large + and - errors, so here we use
# the absolute percentage error |e| and MAPE = mean of |e| in a group.
#
# Input : data/processed/gps_runs.csv  (made by code/00_clean_data.R)
# Output: tables in results/, plot in figures/
# Run from the repository root:  Rscript code/03_absolute_error.R

suppressPackageStartupMessages({
  library(lme4)
  library(lmerTest)
  library(emmeans)
  library(ggplot2)
})

dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

dat <- read.csv("data/processed/gps_runs.csv")
dat$block     <- factor(dat$block, levels = c("Phoebe", "Boyi", "Jenny", "Darren"))
dat$app       <- factor(dat$app, levels = c("Keep", "Strava"))
dat$lane      <- factor(dat$lane)
dat$placement <- factor(dat$placement, levels = c("hand", "pocket"))
dat$pace      <- factor(dat$pace, levels = c("walk", "jog"))
dat$lap_id    <- factor(dat$lap_id)
options(contrasts = c("contr.sum", "contr.poly"))

dat$abs_e <- abs(dat$error_pct)

# ---- 1. MAPE by app with a bootstrap CI -------------------------------------

# Resample whole laps (both app readings together) within each block, so every
# bootstrap sample keeps the design: 4 blocks x 8 laps, paired readings.
mape_by_app <- function(d) tapply(d$abs_e, d$app, mean)

laps_in_block <- split(as.character(dat$lap_id), dat$block)
laps_in_block <- lapply(laps_in_block, unique)
rows_of_lap   <- split(seq_len(nrow(dat)), as.character(dat$lap_id))

set.seed(404)
B <- 5000
boot <- replicate(B, {
  laps <- unlist(lapply(laps_in_block, sample, replace = TRUE))
  mape_by_app(dat[unlist(rows_of_lap[laps]), ])
})
boot_diff <- boot["Strava", ] - boot["Keep", ]

mape_table <- data.frame(
  app      = c("Keep", "Strava", "Strava - Keep"),
  mape     = c(mape_by_app(dat), diff(mape_by_app(dat))),
  boot_lo  = c(apply(boot, 1, quantile, 0.025), quantile(boot_diff, 0.025)),
  boot_hi  = c(apply(boot, 1, quantile, 0.975), quantile(boot_diff, 0.975))
)
mape_table[, -1] <- round(mape_table[, -1], 2)
print(mape_table)
write.csv(mape_table, "results/mape_by_app_bootstrap.csv", row.names = FALSE)

# MAPE by block and app (descriptive)
mape_block <- aggregate(abs_e ~ block + app, data = dat, FUN = mean)
mape_block$abs_e <- round(mape_block$abs_e, 2)
names(mape_block)[3] <- "mape"
print(mape_block)
write.csv(mape_block, "results/mape_by_block_app.csv", row.names = FALSE)

