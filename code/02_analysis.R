# 02_analysis.R
# Signed percentage error: does each app over- or under-record, and which
# factors and interactions matter? (proposal v2, aims 1 and 2)
#
# Input : data/processed/gps_runs.csv  (made by code/01_clean_data.R)
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

# ---- 4. Is the app effect the same on every phone? (review comment 7) -------

# Paired difference within each lap: Strava minus Keep
wide <- reshape(dat[, c("lap_id", "block", "app", "error_pct")],
                idvar = c("lap_id", "block"), timevar = "app", direction = "wide")
wide$diff <- wide$error_pct.Strava - wide$error_pct.Keep

p_diff <- ggplot(wide, aes(x = block, y = diff)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  # light box plot underneath; outliers hidden because every point is drawn
  geom_boxplot(width = 0.4, outlier.shape = NA, fill = "grey90", colour = "grey60") +
  geom_point(position = position_jitter(width = 0.1, height = 0, seed = 1),
             size = 2, alpha = 0.7) +
  stat_summary(fun = mean, geom = "crossbar", width = 0.4, colour = "red") +
  labs(x = "Block (member and phone)", y = "Strava - Keep (percentage points)",
       title = "Paired app difference in each lap, by block",
       subtitle = "Box = quartiles, grey line = median, red bar = mean.\nAbove 0: Strava records more than Keep") +
  theme_bw()
ggsave("figures/02_app_difference_by_block.png", p_diff, width = 6, height = 4, dpi = 200)

# Sensitivity model: add the app x block interaction (3 df)
fit_int <- lmer(error_pct ~ block * app + app * lane * placement * pace + (1 | lap_id),
                data = dat)

# Likelihood-ratio test of the 3 extra terms (refit with ML to compare)
lrt <- anova(fit_add, fit_int, refit = TRUE)
print(lrt)

anova_int <- anova(fit_int)
print(anova_int)
write.csv(round(as.data.frame(anova_int), 4), "results/anova_final_model.csv")

# App difference (Strava - Keep) within each block, with 95% CIs
app_by_block <- confint(contrast(emmeans(fit_int, ~ app | block), "revpairwise"))
print(app_by_block)
app_by_block_df <- as.data.frame(app_by_block)
app_by_block_df[, 3:7] <- round(app_by_block_df[, 3:7], 2)
write.csv(app_by_block_df, "results/app_difference_by_block.csv", row.names = FALSE)

# The interaction is clear, so fit_int is used as the final model from here on
fit <- fit_int

# Aim 2 also asks about interactions among the treatment factors: the
# smallest p-value among all 11 two-, three- and four-way interactions of
# app, lane, placement and pace (block:app is reported separately above)
int_terms <- grep(":", rownames(anova_int), value = TRUE)
int_terms <- setdiff(int_terms, "block:app")
int_p <- anova_int[int_terms, "Pr(>F)"]
cat(sprintf("Treatment-factor interactions: %d terms, smallest p = %.2f (%s)\n",
            length(int_terms), min(int_p), int_terms[which.min(int_p)]))

# ---- 5. Model checking ------------------------------------------------------

dat$fitted <- fitted(fit)
dat$resid  <- resid(fit)

png("figures/03_diagnostics.png", width = 9, height = 3.2, units = "in", res = 200)
par(mfrow = c(1, 3))
plot(dat$fitted, dat$resid, xlab = "Fitted value", ylab = "Residual",
     main = "Residuals vs fitted")
abline(h = 0, lty = 2)
qqnorm(dat$resid, main = "Normal Q-Q of residuals")
qqline(dat$resid)
set.seed(1)   # fixed jitter so the figure is reproducible
plot(jitter(dat$lap_order, 0.5), dat$resid, xlab = "Lap order within block",
     ylab = "Residual", main = "Residuals vs lap order")
abline(h = 0, lty = 2)
invisible(dev.off())

# Numerical companions to the plots
print(shapiro.test(dat$resid))                    # normality of residuals
print(cor.test(dat$resid, dat$lap_order))         # trend over the session?
print(bartlett.test(resid ~ block, data = dat))   # equal spread across blocks?

# ---- 6. Estimated effects (aims 1 and 2) ------------------------------------

# Estimated mean error, with 95% CI, for each level of the factors in `spec`.
# Returns a plain data frame with a "level" column naming the level.
em_table <- function(spec) {
  em <- as.data.frame(confint(emmeans(fit, spec)))
  vars <- all.vars(spec)
  em$level <- if (length(vars) == 0) "overall" else
    do.call(paste, c(lapply(vars, function(v) paste(v, em[[v]])), sep = ", "))
  em[, c("level", "emmean", "SE", "df", "lower.CL", "upper.CL")]
}

# Aim 1: average signed error overall and for each app.
# These average over the four blocks ("a typical phone in our study");
# section 4 shows that the app difference changes sign between blocks.
# Aim 2: mean error at each level of lane, placement and pace.
means <- rbind(em_table(~ 1), em_table(~ app), em_table(~ lane),
               em_table(~ placement), em_table(~ pace))
means[, -1] <- round(means[, -1], 2)
print(means)
write.csv(means, "results/estimated_means.csv", row.names = FALSE)

# Main-effect plot: estimated mean error at each level, with 95% CIs
main <- means[means$level != "overall", ]
main$factor <- sub(" .*", "", main$level)                 # e.g. "placement"
main$value  <- factor(sub("^\\S+ ", "", main$level),      # e.g. "pocket"
                      levels = unique(sub("^\\S+ ", "", main$level)))
p_main <- ggplot(main, aes(x = value, y = emmean)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_pointrange(aes(ymin = lower.CL, ymax = upper.CL)) +
  facet_wrap(~ factor, scales = "free_x", nrow = 1) +
  labs(x = NULL, y = "Estimated mean error e (%)",
       title = "Main effects with 95% confidence intervals",
       subtitle = "Averaged over our 4 blocks (fixed-block final model)") +
  theme_bw()
ggsave("figures/04_main_effects.png", p_main, width = 8, height = 3.5, dpi = 200)

# Interaction plots for the two-factor interactions of primary interest:
# x-axis factor, line (trace) factor
pairs_of_interest <- list(c("lane", "pace"), c("placement", "pace"),
                          c("lane", "app"), c("pace", "app"))
int_data <- do.call(rbind, lapply(pairs_of_interest, function(p) {
  em <- as.data.frame(emmeans(fit, as.formula(paste("~", p[1], "*", p[2]))))
  data.frame(panel = paste(p[1], "x", p[2]),
             x = as.character(em[[p[1]]]), trace = as.character(em[[p[2]]]),
             emmean = em$emmean)
}))
# keep the level order used in the data (walk before jog, etc.)
int_data$x     <- factor(int_data$x, levels = unique(int_data$x))
int_data$trace <- factor(int_data$trace, levels = unique(int_data$trace))
p_int <- ggplot(int_data, aes(x = x, y = emmean, colour = trace, group = trace)) +
  geom_point(size = 2) + geom_line() +
  facet_wrap(~ panel, scales = "free_x") +
  labs(x = NULL, y = "Estimated mean error e (%)", colour = "Line",
       title = "Two-factor interactions (parallel lines = no interaction)") +
  theme_bw()
ggsave("figures/05_interactions.png", p_int, width = 8, height = 6, dpi = 200)

# ---- 7. Sensitivity to the true lap length ----------------------------------

# Our walked line may differ slightly from the official measurement line.
# Shift d_true by -1 m and +1 m, refit the final model, and compare.
for (shift in c(-1, 0, 1)) {
  d_true <- dat$true_distance_m + shift
  dat$e_shift <- 100 * (dat$recorded_distance_m - d_true) / d_true
  m <- lmer(e_shift ~ block * app + app * lane * placement * pace + (1 | lap_id),
            data = dat)
  a <- anova(m)
  cat(sprintf("d_true %+d m: overall mean e = %.2f%%, app x block p = %.4f, app p = %.4f\n",
              shift, summary(emmeans(m, ~ 1))$emmean,
              a["block:app", "Pr(>F)"], a["app", "Pr(>F)"]))
}

# ---- 8. Sensitivity: blocks as a random sample of phones --------------------

# The final model treats block as FIXED, so its CIs describe our 4 phones.
# To ask about "a typical phone", treat the phones as a random sample:
#   (1 | block)      phone-to-phone shift in the error
#   (1 | block:app)  phone-to-phone change in the app difference
# The overall mean and the app effect are then tested against phone-to-phone
# variation, with only 4 - 1 = 3 df, so the intervals are much wider.
fit_rb <- lmer(error_pct ~ app * lane * placement * pace +
                 (1 | block) + (1 | block:app) + (1 | lap_id), data = dat)
print(VarCorr(fit_rb))
anova_rb <- anova(fit_rb)
print(anova_rb)

rb_overall <- as.data.frame(confint(emmeans(fit_rb, ~ 1)))
rb_app     <- as.data.frame(confint(contrast(emmeans(fit_rb, ~ app), "revpairwise")))
rb_table <- data.frame(
  quantity = c("overall mean e (%)", "Strava - Keep (points)"),
  estimate = c(rb_overall$emmean,   rb_app$estimate),
  df       = c(rb_overall$df,       rb_app$df),
  lower    = c(rb_overall$lower.CL, rb_app$lower.CL),
  upper    = c(rb_overall$upper.CL, rb_app$upper.CL)
)
rb_table[, -1] <- round(rb_table[, -1], 2)
print(rb_table)
cat(sprintf("Random-block model: app p = %.2f\n", anova_rb["app", "Pr(>F)"]))
write.csv(rb_table, "results/random_block_sensitivity.csv", row.names = FALSE)
