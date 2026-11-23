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

# ---- 2. Model for log(|e| + 0.5) ---------------------------------------------

# |e| is skewed and often 0, so model log(|e| + 0.5) with the same final mixed
# model as the signed error (including app x block, see 02_analysis.R). Back-transformed means are "typical" (median-like)
# absolute errors, so they are smaller than MAPE.
dat$log_abs <- log(dat$abs_e + 0.5)
fit_abs <- lmer(log_abs ~ block * app + app * lane * placement * pace + (1 | lap_id),
                data = dat)
anova_abs <- anova(fit_abs)
print(anova_abs)
write.csv(round(as.data.frame(anova_abs), 4), "results/anova_log_abs_error.csv")

back <- function(x) pmax(exp(x) - 0.5, 0)   # undo log(|e| + 0.5); |e| >= 0
typical <- function(spec) {
  em <- as.data.frame(confint(emmeans(fit_abs, spec)))
  data.frame(em[, all.vars(spec), drop = FALSE],
             typical_abs_e = back(em$emmean),
             lower = back(em$lower.CL), upper = back(em$upper.CL))
}
typ_app  <- typical(~ app)
typ_cell <- typical(~ app * lane * placement * pace)
print(typ_app, digits = 3)
write.csv(transform(typ_cell, typical_abs_e = round(typical_abs_e, 2),
                    lower = round(lower, 2), upper = round(upper, 2)),
          "results/typical_abs_error_by_treatment.csv", row.names = FALSE)

# Check that the conclusion does not hinge on the constant 0.5
for (k in c(0.25, 0.5, 1)) {
  m <- lmer(log(abs_e + k) ~ block * app + app * lane * placement * pace + (1 | lap_id),
            data = dat)
  cat(sprintf("constant %.2f: app p = %.3f\n", k, anova(m)["app", "Pr(>F)"]))
}

# ---- 3. Plot: typical |e| for all 16 treatment combinations ------------------

typ_cell$combo <- with(typ_cell, paste0("lane ", lane, ", ", placement, ", ", pace))
p_cell <- ggplot(typ_cell, aes(x = typical_abs_e, y = combo, colour = app)) +
  geom_pointrange(aes(xmin = lower, xmax = upper),
                  position = position_dodge(width = 0.5)) +
  labs(x = "Typical absolute error |e| (%), back-transformed, 95% CI",
       y = NULL, colour = "App",
       title = "Accuracy of each tested combination",
       subtitle = "Intervals overlap widely: no single best combination") +
  theme_bw()
ggsave("figures/06_typical_abs_error_by_treatment.png", p_cell,
       width = 7, height = 4.5, dpi = 200)
