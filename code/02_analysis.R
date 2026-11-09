# 02_analysis.R
# Planned analysis (skeleton - to be completed once data are collected).
#
# Response: percentage distance error  e = (d_recorded - d_true) / d_true
#   d_true = 400 m (lane 1), ~453 m (lane 8)
#
# Model: factorial linear mixed-effects model
#   fixed:  block + app * lane * placement * pace
#   random: lap nested within block (the two app readings in a lap are paired)

library(lme4)
library(lmerTest)   # F tests with Satterthwaite df
library(ggplot2)

dat <- read.csv("data/processed/gps_runs.csv", stringsAsFactors = TRUE)

dat$true_distance_m <- ifelse(dat$lane == 1, 400, 453)
dat$error_pct <- 100 * (dat$recorded_distance_m - dat$true_distance_m) / dat$true_distance_m
dat$lap_id <- interaction(dat$block, dat$lap_order)
dat[c("block", "app", "lane", "placement", "pace")] <-
  lapply(dat[c("block", "app", "lane", "placement", "pace")], factor)

# Effect coding so factorial effects are interpretable
options(contrasts = c("contr.sum", "contr.poly"))

fit <- lmer(error_pct ~ block + app * lane * placement * pace + (1 | lap_id),
            data = dat)

anova(fit)                       # factorial effect tests
confint(fit, method = "Wald")    # 95% CIs for fixed effects

# Descriptive summaries: means, SDs, mean absolute error by treatment
aggregate(cbind(error_pct, abs_error = abs(error_pct)) ~ app + lane + placement + pace,
          data = dat, FUN = function(x) c(mean = mean(x), sd = sd(x)))

# TODO: main-effect & interaction plots, paired app comparison plot
# TODO: diagnostics - residual vs fitted, normal Q-Q, residual vs lap order
