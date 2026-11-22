# 02_analysis.R
# Signed percentage error: does each app over- or under-record, and which
# factors and interactions matter? (proposal v2, aims 1 and 2)
#
# Input : data/processed/gps_runs.csv  (made by code/00_clean_data.R)
# Output: tables in results/, plots in figures/
# Run from the repository root:  Rscript code/02_analysis.R

suppressPackageStartupMessages({
  library(lme4)
  library(lmerTest)   # F tests with Satterthwaite df
  library(emmeans)    # estimated marginal means with 95% CIs
  library(ggplot2)
})

dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# ---- 1. Data ---------------------------------------------------------------

dat <- read.csv("data/processed/gps_runs.csv")

# Treat every design variable as a factor (lane 1/8 is a category, not a number)
dat$block     <- factor(dat$block, levels = c("Phoebe", "Boyi", "Jenny", "Darren"))
dat$app       <- factor(dat$app, levels = c("Keep", "Strava"))
dat$lane      <- factor(dat$lane)
dat$placement <- factor(dat$placement, levels = c("hand", "pocket"))
dat$pace      <- factor(dat$pace, levels = c("walk", "jog"))
dat$lap_id    <- factor(dat$lap_id)

# Sum-to-zero (effect) coding, so each factorial effect is a deviation
# from the overall mean and the ANOVA tests match the usual 2^k effects
options(contrasts = c("contr.sum", "contr.poly"))

# ---- 2. Descriptive summaries ----------------------------------------------

# n, mean and SD of the signed error, and MAPE = mean of |e|, for each group
summarise_e <- function(formula) {
  out <- aggregate(formula, data = dat, FUN = function(e)
    round(c(n = length(e), mean = mean(e), sd = sd(e), mape = mean(abs(e))), 2))
  out <- do.call(data.frame, out)   # turn the matrix column into ordinary columns
  names(out) <- sub("error_pct.", "", names(out), fixed = TRUE)
  out
}

by_app   <- summarise_e(error_pct ~ app)
by_block <- summarise_e(error_pct ~ block + app)
by_cell  <- summarise_e(error_pct ~ app + lane + placement + pace)
print(by_app)
print(by_block)

write.csv(by_app,   "results/summary_by_app.csv",       row.names = FALSE)
write.csv(by_block, "results/summary_by_block_app.csv", row.names = FALSE)
write.csv(by_cell,  "results/summary_by_treatment.csv", row.names = FALSE)

# Raw data plot: every reading, by block and app
p_raw <- ggplot(dat, aes(x = block, y = error_pct, colour = app)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(position = position_jitterdodge(jitter.width = 0.15,
                                             jitter.height = 0, seed = 1),
             size = 2, alpha = 0.8) +
  labs(x = "Block (member and phone)", y = "Signed error e (%)", colour = "App",
       title = "All 64 readings: error by block and app") +
  theme_bw()
ggsave("figures/01_raw_error_by_block.png", p_raw, width = 6, height = 4, dpi = 200)

# ---- 3. Planned model: additive block --------------------------------------

# Fixed: block + full 2^4 factorial of app, lane, placement, pace
# Random: (1 | lap_id) = one random intercept for each of the 32 laps.
#   In "(1 | lap_id)", "|" means "for each group of"; the 1 is an intercept.
#   So every lap gets its own shift u_lap ~ N(0, sigma_lap^2), and the model
#   estimates sigma_lap rather than 32 separate shifts.
#
# Why it is needed: both apps recorded the SAME lap at the same time, so the
# two readings share that lap's conditions (the line actually walked, the
# satellites at that moment, ...) beyond what block and treatments explain.
# This is a split-plot structure:
#   - whole plot = lap;  whole-plot factors = lane, placement, pace
#     (each lap gets a different combination; they are compared between laps,
#     so their error is lap-to-lap variation: 32 laps, 21 residual df)
#   - sub-plot = app reading within a lap; sub-plot factor = app
#     (compared within laps, so the lap shift cancels, as in a paired t test)
# Dropping (1 | lap_id) and using lm() would treat the 64 readings as
# independent (pseudo-replication): in the final model (section 4) the
# placement p-value would fall from 0.08 to 0.04, a false "significant"
# result, while the app test would lose the benefit of pairing. The term is kept because the design requires
# it, whether or not it is significant in this data set.
fit_add <- lmer(error_pct ~ block + app * lane * placement * pace + (1 | lap_id),
                data = dat)

anova_add <- anova(fit_add)   # Type III F tests, Satterthwaite df
print(anova_add)
print(VarCorr(fit_add))       # lap-to-lap SD and residual SD

write.csv(round(as.data.frame(anova_add), 4), "results/anova_additive_model.csv")
